#!/bin/bash

DIR="$( cd "$( dirname "$0"  )" && pwd  )"

source $DIR/lib.sh
source $DIR/conf.sh

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
    echo "    -n:    Dry run."
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
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"
    debug "Expecting: $3"
    PAGE=""
    if [[ $DEBUG == 1 ]]; then
        PAGE=$(curl -vsL "${1}")
    else
        PAGE=$(curl -sL "${1}")
    fi
    debug "Page: ${PAGE}"
    SCRAPED_STRING=$(echo "${PAGE}" | \grep -Po -m 1 "${2}")
    debug "Got \"$SCRAPED_STRING\" from webpage."
    if [[ $SCRAPED_STRING != "$3" ]]; then
        error "Checking \"$1\" expected \"$3\" got \"$SCRAPED_STRING\""
        debug "Returning 1 from check_webpage()"
        return 1
    fi
}

HAS_ERROR=0

msg "scraper.sh started..."

#
# Check archiso kernel version (this will change when the archiso is updated)
#
msg "Checking archiso download page for linux kernel version changes..."

check_webpage "https://www.archlinux.org/download/" "(?<=Included Kernel:</strong> )[\d\.]+" "$AZB_KERNEL_ARCHISO_VERSION"

if [[ $? != 0 ]]; then
    error "The archiso has been changed!"
    HAS_ERROR=1
else
    msg2 "The archiso kernel version is current."
fi

#
# Check i686 linux kernel version
#
msg "Checking the online package database for i686 linux kernel version changes..."

check_webpage "https://www.archlinux.org/packages/core/i686/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_GIT_KERNEL_X32_VERSION"

if [[ $? != 0 ]]; then
    error "linux i686 is out-of-date!"
    HAS_ERROR=1
else
    msg2 "The i686 linux kernel package is current."
fi

#
# Check x86_64 linux kernel version
#
msg "Checking the online package database for x86_64 linux kernel version changes..."

check_webpage "https://www.archlinux.org/packages/core/x86_64/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_GIT_KERNEL_X64_VERSION"

if [[ $? != 0 ]]; then
    error "linux x86_64 is out-of-date!"
    HAS_ERROR=1
else
    msg2 "The x86_64 linux kernel package is current."
fi

#
# Check i686 linux-lts kernel version
#
msg "Checking the online package database for i686 linux-lts kernel version changes..."

check_webpage "https://www.archlinux.org/packages/core/i686/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "$AZB_LTS_KERNEL_X32_VERSION"

if [[ $? != 0 ]]; then
    error "linux-lts i686 is out-of-date!"
    HAS_ERROR=1
else
    msg2 "The i686 linux-lts kernel package is current."
fi

#
# Check x86_64 linux-lts kernel version
#
msg "Checking the online package database for x86_64 linux-lts kernel version changes..."

check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "$AZB_LTS_KERNEL_X64_VERSION"

if [[ $? != 0 ]]; then
    error "linux-lts x86_64 is out-of-date!"
    HAS_ERROR=1
else
    msg2 "The x86_64 linux-lts kernel package is current."
fi

#
# Check ZFSonLinux.org
#
msg "Checking zfsonlinux.org for new versions..."

check_webpage "http://zfsonlinux.org/" "(?<=downloads/zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" "$AZB_ZOL_VERSION"

if [[ $? != 0 ]]; then
    error "ZOL version has changed!"
    HAS_ERROR=1
else
    msg2 "The ZOL sources are current."
fi

if [[ $HAS_ERROR -eq 1 ]]; then
    exit 1;
fi
