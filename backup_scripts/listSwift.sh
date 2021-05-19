#!/bin/bash
#
# This script lists objects in the specified container, or if not specied,
# it will list all the containers
# it requires the Python Swift client to be installed and swift credentials (openrc.sh)
#
# References:
# The pathadd function was taken from:
#     https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there



pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}


USAGE_STR="Usage: $(basename $0) [-h(elp)] [-p(ath) swift_install_dir] [-c(reds) openstack_cred_file] [container]"

function show_help()
{
    cat <<ENDOFHELP
$USAGE_STR
Where:
    -h                  provides this handy help.
    -p <path_to_swift>  path to directory containing Swift application (otherwise looks on PATH).
    -c <cred_file>      specify OpenStack credential file to source (if not sourced in shell).
    [container]         name of container holding objects, otherwise list all containers
}
ENDOFHELP
}


while getopts "c:p:h" opt; do
    case $opt in
        h)
            show_help
            exit 0
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

CONTAINER=""
if [ $# -eq 1 ]; then
    CONTAINER="${1}"
fi

swift --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: 'swift' application not found on PATH!" >&2
    exit 1
fi

# this just tests that credentials are sourced
swift list >&/dev/null
if [ $? -ne 0 ]; then
    echo "Error: Swift OpenStack AUTH credentials need to be sourced!" >&2
    exit 1
fi

# any errors here are likely to be due to specified container not existing
swift list --lh ${CONTAINER}

