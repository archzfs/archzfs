#!/bin/bash

source ./lib.sh
source ./conf.sh

set -e

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

usage() {
	echo "scraper.sh - A cheap webpage scraper."
    echo
	echo "Usage: scraper.sh [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Don't send email."
    echo "    -d:    Show debug info."
    echo
	echo "Examples:"
    echo
    echo "    scraper.sh -d     :: Show debug output."
    echo "    scraper.sh -n     :: Don't run commands, but show output."
}

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done

check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    # Sends a message on mismatch. Only the first match is checked.
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"
    debug "Expecting: $3"
    SCRAPED_STRING=$(curl -s "$1" | grep -Po -m 1 "$2")
    debug "Got \"$SCRAPED_STRING\" from webpage."
    if [[ $SCRAPED_STRING != "$3" ]]; then
        error "Checking \"$1\" expected \"$3\" got \"$SCRAPED_STRING\""
        debug "Returning 1 from check_webpage()"
        return 1
    fi
}

msg "scraper.sh started..."

#
# Check archiso kernel version (this will change when the archiso is updated)
#
msg "Checking archiso download page for linux kernel version changes..."

check_webpage "https://www.archlinux.org/download/" \
    "(?<=Included Kernel:</strong> )[\d\.]+" "$AZB_LINUX_ARCHISO"

if [[ $? != 0 ]]; then
    msg2 "Sending notification..."
    run_cmd send_email \
        "Push the required packages to the archiso repo!" \
        "The archiso has been changed!"
else
    msg2 "The archiso kernel version is current."
fi

#
# Check i686 linux kernel version
#
# msg "Checking the online package database for i686 linux kernel version changes..."

# check_webpage "https://www.archlinux.org/packages/core/i686/linux/" \
    # "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_LINUX_X32_VERSION_FULL"

# if [[ $? != 0 ]]; then
    # msg2 "Sending notification..."
    # send_email "Update the archzfs repository!" \
        # "The i686 linux package has been changed!"
# else
    # msg2 "The i686 linux kernel package is current."
# fi

# #
# # Check x86_64 linux kernel version
# #
# msg "Checking the online package database for x86_64 linux kernel version changes..."

# check_webpage "https://www.archlinux.org/packages/core/x86_64/linux/" \
    # "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_LINUX_X64_VERSION_FULL"

# if [[ $? != 0 ]]; then
    # msg2 "Sending notification..."
    # send_email "Update the archzfs repository!" \
        # "The x86_64 linux package has been changed!"
# else
    # msg2 "The x86_64 linux kernel package is current."
# fi
# #
# # Check ZFSonLinux.org
# #
# msg "Checking zfsonlinux.org for new versions..."

# check_webpage "http://zfsonlinux.org/" \
    # "(?<=zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" "$AZB_ZOL_VERSION"


# if [[ $? != 0 ]]; then
    # msg2 "Sending notification..."
    # run_cmd send_email "Update the archzfs repository!" \
        # "The ZOL packages have been changed!"
# else
    # msg2 "The ZOL sources are current."
# fi
