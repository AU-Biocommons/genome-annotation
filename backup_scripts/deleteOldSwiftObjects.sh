#!/bin/bash
#
# This script deletes objects from the specified container that have reached the specified age
# it requires the Python Swift client to be installed and swift credentials (openrc.sh)
#
# References:
# The list processing code was adapted from:
#     https://medium.com/metrosystemsro/safe-automatic-cleanup-of-old-objects-on-openstack-swift-containers-30f9bfcd7981
# The pathadd function was taken from:
#     https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there



pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}


USAGE_STR="Usage: $(basename $0) [-h(elp)] [-v(erbose)] [-t(est)] [-p(ath) swift_install_dir] [-c(reds) openstack_cred_file] [-e (expire) days] [-k(eep) minimum] container"

function show_help()
{
    cat <<ENDOFHELP
$USAGE_STR
Where:
    -h                  provides this handy help.
    -v                  verbose mode.
    -t                  test mode (sets verbose) - don't delete any files.
    -p <path_to_swift>  path to directory containing Swift application (otherwise looks on PATH).
    -c <cred_file>      specify OpenStack credential file to source (if not sourced in shell).
    -e <days>           age in days at which objects should be deleted (default 30)
    -k <minimum>        the minimum number of objects to be kept (default 0).
    container           name of container holding objects
}
ENDOFHELP
}



VERBOSE_MODE=0
TEST_MODE=0
NUM_KEEP_MIN=0
DAYS_TO_EXPIRE=30
#HOURS_TO_EXPIRE=30

while getopts "k:e:c:p:tvh" opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        v)
            VERBOSE_MODE=1
            ;;
        t)
            TEST_MODE=1
            VERBOSE_MODE=1
            ;;
        k)
            NUM_KEEP_MIN=$OPTARG
            ;;
        e)
            DAYS_TO_EXPIRE=$OPTARG
            #HOURS_TO_EXPIRE=$OPTARG
            ;;
        c)
            SWIFT_CRED_FILE=$OPTARG
            source ${SWIFT_CRED_FILE} || exit
            ;;
        p)
            PATH_TO_SWIFT=$OPTARG
            pathadd ${PATH_TO_SWIFT}
            ;;
        \?)
            echo "Error: Invalid option: -${OPTARG}" >&2
            echo >&2 "$usage_str"
            exit 1
            ;;
    esac
done

# get rid of option params
shift $((OPTIND-1))

if [ $# -eq 1 ]; then
    CONTAINER="${1}"
else
    echo "Error: No container specified!" >&2
    echo >&2 "$usage_str"
    exit 1
fi


# test that swift is installed / on PATH and credentials have been sourced

[ $VERBOSE_MODE -eq 1 ] && swift --version >&2 || swift --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: 'swift' application not found on PATH. Exiting." >&2
    exit 1
fi

[ $VERBOSE_MODE -eq 1 ] && swift list --lh >&2 || swift list -l > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Swift OpenStack AUTH credentials need to be sourced. Exiting." >&2
    exit 1
fi


objs_to_del=''
num_del=0
num_objs=0


# swift file date and time are in GMT, so use it for comparison with current time
export TZ=GMT
[ $VERBOSE_MODE -eq 1 ] && echo "Current date (GMT): $(date)" >&2

obj_listing="$(swift list --lh ${CONTAINER})"
[ $VERBOSE_MODE -eq 1 ] && printf "%s:\n%s" "${CONTAINER}" "${obj_listing}"
while IFS= read -r obj_line; do
    read -r obj_size obj_date obj_time obj_x obj_name obj_rest <<< "${obj_line}"
    [ $VERBOSE_MODE -eq 1 ] && echo "$obj_size $obj_date $obj_time $obj_x $obj_name $obj_rest"
    printf -v all_objs "%s\n%s %s" "${all_objs}" "${obj_name}" "${obj_date}"
    # only process lines that aren't the container total
    if [ ! -z "${obj_date}" ] && [ ! -z "${obj_time}" ] && [ ! -z "${obj_name}" ]; then
        [ $VERBOSE_MODE -eq 1 ] && echo "Processing object: $obj_date $obj_time $obj_name" >&2
        num_objs=$((num_objs+1))
	date_diff=$((($(date +%s)-$(date +%s --date "${obj_date}"))/(60*60*24)))
	#hour_diff=$((($(date +%s)-$(date +%s --date "${obj_date} ${obj_time}"))/(60*60)))
	if [ ${date_diff} -ge ${DAYS_TO_EXPIRE} ]; then
	#if [ ${hour_diff} -ge ${HOURS_TO_EXPIRE} ]; then
            [ $VERBOSE_MODE -eq 1 ] && echo "$obj_name: ${date_diff} -gt ${DAYS_TO_EXPIRE}" >&2
            [ $VERBOSE_MODE -eq 1 ] && echo "Found object named \"${obj_name}\", modified on \"${obj_date}\" at \"${obj_time}\" (${date_diff} days ago)" >&2
            #[ $VERBOSE_MODE -eq 1 ] && echo "Found object named \"${obj_name}\", modified on \"${obj_date}\" at \"${obj_time}\" (${hour_diff} hours ago)" >&2
	    printf -v objs_to_del "%s\n%s %s" "${objs_to_del}" "${obj_name}" "${obj_date}"
	    #printf -v objs_to_del "%s\n%s %s" "${objs_to_del}" "${obj_name}" "${obj_time}"
	    num_del=$((num_del+1))
	fi
    fi
done < <(printf '%s\n' "${obj_listing}")

# Reverse sort by date (oldest first)
objs_to_del=`sort -k 2 <<< "${objs_to_del}"`

num_objs_rem=$((num_objs-num_del))
if [ $VERBOSE_MODE -eq 1 ]; then
    echo "objects to delete: ${objs_to_del}" >&2
    echo "number of objects to delete: ${num_del}" >&2
    echo "number of objects remaining: ${num_objs_rem}" >&2
fi

if [ $num_del -gt 0 ]; then
    if [ ${num_objs_rem} -ge ${NUM_KEEP_MIN} ]; then
        [ $VERBOSE_MODE -eq 1 ] && echo "Processing ${num_del} expired objects..." >&2
        while IFS= read -r obj2_line; do
            read -r obj2_name obj2_date <<< "${obj2_line}"
            if [ ! -z "${obj2_name}" ] && [ ! -z "${obj2_date}" ]; then
                [ $VERBOSE_MODE -eq 1 ] && echo "Deleting: $obj2_name $obj2_date" >&2
                if [ $TEST_MODE -eq 0 ]; then
                    swift --quiet delete ${CONTAINER} ${obj2_name}
                else
                    echo "swift delete ${CONTAINER} ${obj2_name}" >&2
                fi
            elif [ ! -z "${obj2_name}" ] || [ ! -z "${obj2_date}" ]; then
                echo "Warning: skipping malformed entry '$obj2_line'" >&2
            # else (empty line)
            fi
        done < <(printf '%s\n' "${objs_to_del}")
    else
        [ $VERBOSE_MODE -eq 1 ] && echo "Delete aborted to retain minimum number of objects (${NUM_KEEP_MIN})!" >&2
    fi
else
    [ $VERBOSE_MODE -eq 1 ] && echo "No objects to delete." >&2
fi

