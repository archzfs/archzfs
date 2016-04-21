#!/bin/bash -e


#
# A script for scraping data from the web. When ran in cron with a correct email address configured, an alert email will be
# sent notifying the user that either the "linux" kernel package version has changed, a new ZFSonLinux version has been
# released, or a new archiso has been released.
#


NAME=$(basename $0)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 1
fi
source_safe "${SCRIPT_DIR}/conf.sh"


# setup signal traps
trap 'clean_up' 0
for signal in TERM HUP QUIT; do
    trap "trap_exit $signal \"$(msg "$signal signal caught. Exiting...")\"" "$signal"
done
trap "trap_exit INT \"$(msg "Aborted by user! Exiting...")\"" INT
trap "trap_exit USR1 \"$(error "An unknown error has occurred. Exiting..." 2>&1 )\"" ERR


usage() {
    echo "${NAME} - A cheap webpage scraper."
    echo
    echo "Usage: ${NAME} [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dry run."
    echo "    -d:    Show debug info."
    echo
    echo "Examples:"
    echo
    echo "    ${NAME} -d     :: Show debug output."
    echo "    ${NAME} -n     :: Don't run commands, but show output."
    trap - EXIT # Prevents exit log output
}


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    fi
done


msg "$(date) :: ${NAME} started..."


CHECK_WEBPAGE_RETVAL=0


check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"
    debug "Expecting: $3"

    run_cmd_no_output "curl -sL ${1}"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        return
    fi

    if [[ $(echo ${RUN_CMD_OUTPUT} | \grep -q "504 Gateway Timeout"; echo $?) -eq 0 ]]; then
        CHECK_WEBPAGE_RETVAL=-1
        return
    elif [[ $(echo ${RUN_CMD_OUTPUT} | \grep -q "503 Service Unavailable"; echo $?) -eq 0 ]]; then
        CHECK_WEBPAGE_RETVAL=-1
        return
    elif [[ ${RUN_CMD_OUTPUT} == "RETVAL: 7" ]]; then
        CHECK_WEBPAGE_RETVAL=-1
        return
    fi

    SCRAPED_STRING=$(echo "${RUN_CMD_OUTPUT}" | \grep -Po -m 1 "${2}")
    debug "Got \"${SCRAPED_STRING}\" from webpage."

    if [[ ${SCRAPED_STRING} != "$3" ]]; then
        error "Checking '$1' expected '$3' got '${SCRAPED_STRING}'"
        debug "Returning 1 from check_webpage()"
        CHECK_WEBPAGE_RETVAL=1
        return
    fi

    CHECK_WEBPAGE_RETVAL=0
    return
}


check_result() {
    # $1 current line
    # $2 changed line
    if [[ ${CHECK_WEBPAGE_RETVAL} -eq 0 ]]; then
        msg2 "The $1 version is current."
    elif [[ ${CHECK_WEBPAGE_RETVAL} -eq 1 ]]; then
        error "The $2 is out-of-date!"
        HAS_ERROR=1
    elif [[ ${CHECK_WEBPAGE_RETVAL} -eq -1 ]]; then
        warning "The $2 package page was unreachable!"
    else
        error "Check returned ${CHECK_WEBPAGE_RETVAL}"
        HAS_ERROR=1
    fi
}


HAS_ERROR=0


# Bail if no internet
# Please thank Comcast for this requirement...
if [[ $(ping -w 1 -c 1 8.8.8.8 &> /dev/null; echo $?) != 0 ]]; then
    exit 0;
fi


check_archiso() {
    #
    # Check archiso kernel version (this will change when the archiso is updated)
    #
    msg "Checking archiso download page for linux kernel version changes..."
    check_webpage "https://www.archlinux.org/download/" "(?<=Included Kernel:</strong> )[\d\.]+" \
        "${ARCHISO_KERNEL_VERSION}"
    check_result "archiso kernel version" "archiso"
}


check_linux_kernel() {
    #
    # Check x86_64 linux kernel version
    #
    msg "Checking the online package database for x86_64 linux kernel version changes..."
    check_webpage "https://www.archlinux.org/packages/core/x86_64/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" \
        "${STD_KERNEL_VERSION}"
    check_result "x86_64 linux kernel package" "linux x86_64"
}


check_linux_lts_kernel() {
    #
    # Check x86_64 linux-lts kernel version
    #
    msg "Checking the online package database for x86_64 linux-lts kernel version changes..."
    check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" \
        "${LTS_KERNEL_VERSION}"
    check_result "x86_64 linux-lts kernel package" "linux-lts x86_64"
}


check_zol_version() {
    #
    # Check ZFSonLinux.org
    #
    msg "Checking zfsonlinux.org for new versions..."
    check_webpage "http://zfsonlinux.org/" "(?<=downloads/zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" "${ZOL_VERSION}"
    check_result "ZOL stable version" "ZOL stable version"
}


check_archiso
check_linux_kernel
check_linux_lts_kernel
check_zol_version


#
# This is the end
# Beautiful friend
# This is the end
# My only friend, the end
#
if [[ ${HAS_ERROR} -eq 1 ]]; then
    exit 1;
fi
