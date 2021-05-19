#!/bin/bash
#
# This script finds files of a specified (wildcarded) name and age within (wildcarded) directories
# under the backup root directory. It then uploads these to the specified container.
# It requires the Python Swift client to be installed and swift credentials (openrc.sh).
#
# References:
# The pathadd function was taken from:
#     https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there



pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}


USAGE_STR="Usage: $(basename $0) [-h(elp)] [-v(erbose)] [-t(est)] [-p(ath) swift_install_dir] [-c(reds) openstack_cred_file] [-m(time) days] [-f(files) file_regex] [-d(irs) dir_regex] [-b(ackup) root_dir] container"

function show_help()
{
    cat <<ENDOFHELP
$USAGE_STR
Where:
    -h                  provides this handy help.
    -v                  verbose mode.
    -t                  test mode (sets verbose) - don't upload to container
    -p <path_to_swift>  path to directory containing Swift application (otherwise looks on PATH).
    -c <cred_file>      specify OpenStack credential file to source (if not sourced in shell).
    -m [+]days          match files modified +before or since (default 1 = in last day)
    -f '<file_regex>'   find files matching this pattern (eg: "apollo-???_*.tgz")
    -d '<dir_regex>'    backup files from dirs matching this pattern (eg: "apollo-???_archive")
    -b <root_dir>       search under this backup root directory (default .)
    container           name of container holding objects
}
ENDOFHELP
}



VERBOSE_MODE=0
QUIET="--quiet"
TEST_MODE=0
MTIME=-1
DIR_REGEX=""
FILE_REGEX='*'
BACKUP_ROOT="$PWD"

while getopts "b:d:f:m:c:p:tvh" opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        v)
            VERBOSE_MODE=1
            QUIET=""
            ;;
        t)
            TEST_MODE=1
            VERBOSE_MODE=1
            ;;
        p)
            PATH_TO_SWIFT=$OPTARG
            pathadd ${PATH_TO_SWIFT}
            ;;
        c)
            SWIFT_CRED_FILE=$OPTARG
            source ${SWIFT_CRED_FILE} || exit
            ;;
        m)
            MTIME=$OPTARG
            [ "${MTIME:0:1}" != "+" ] && MTIME="-${MTIME}"
            ;;
        f)
            FILE_REGEX=$OPTARG
            ;;
        d)
            DIR_REGEX=$OPTARG
            ;;
        b)
            BACKUP_ROOT=$OPTARG
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


# search for matching files
[ $VERBOSE_MODE -eq 1 ] && echo "find ${BACKUP_ROOT}/${DIR_REGEX} -name ${FILE_REGEX} -mtime ${MTIME} -print"
ARCHIVE="$(find ${BACKUP_ROOT}/${DIR_REGEX} -name ${FILE_REGEX} -mtime ${MTIME} -print)"
#WEEKLY_ARCHIVES="$(find $BACKUP_ROOT/apollo-???_archive/ -name 'apollo-???_*.tgz' -mtime -7 -print)"
if [ $? -ne 0 ]; then
    echo "Error: Unable to locate files to backup - check paths and regexes! Exiting." >&2
    exit 1
fi

for a in $ARCHIVE; do
    if [ $VERBOSE_MODE -eq 1 ]; then
        echo "archiving: $(du -sh $a)"
    fi
    filename="$(basename $a)"
    directory="$(dirname $a)"
    # upload a large file segmented into 1G with multiple simultanious threads
    [ $VERBOSE_MODE -eq 1 ] && echo "changing into $directory"
    pushd . > /dev/null
    cd $directory
    [ $VERBOSE_MODE -eq 1 ] && echo "uploading $filename with:"
    [ $VERBOSE_MODE -eq 1 ] && echo "swift ${QUIET} upload --changed --segment-size 1000000000 $CONTAINER $filename" >&2
    if [ $TEST_MODE -eq 0 ]; then
        swift $QUIET upload --changed --segment-size 1000000000 $CONTAINER $filename
        if [ $? -ne 0 ]; then
            echo "Error: swift upload failed! Aborting." >&2
            popd > /dev/null
            exit 1
        fi
    fi
    popd > /dev/null
    # deprecated due to only manifest expiring leaving orphaned segments
    # set file's storage expiry to be in 31.25 days
    #swift post $CONTAINER $filename -H "X-Delete-After:3200000"
done

[ $VERBOSE_MODE -eq 1 ] && swift list --lh $CONTAINER >&2

