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

CHECK_WEBPAGE_RETVAL=0

check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"
    debug "Expecting: $3"
    PAGE=""
    if [[ $DEBUG == 1 ]]; then
        PAGE=$(curl -vsL "${1}"; echo "RETVAL: $?")
    else
        PAGE=$(curl -sL "${1}"; echo "RETVAL: $?")
    fi
    if [[ $(echo $PAGE | grep -q "504 Gateway Timeout"; echo $?) == 0 ]]; then
        # error "IN HERE YO 1"
        CHECK_WEBPAGE_RETVAL=-1
        return
    elif [[ $(echo $PAGE | grep -q "503 Service Unavailable"; echo $?) == 0 ]]; then
        # error "IN HERE YO 2"
        CHECK_WEBPAGE_RETVAL=-1
        return
    elif [[ $PAGE == "RETVAL: 7" ]]; then
        # error "IN HERE YO 3"
        CHECK_WEBPAGE_RETVAL=-1
        return
    fi
    # debug "Page: ${PAGE}"
    SCRAPED_STRING=$(echo "${PAGE}" | \grep -Po -m 1 "${2}")
    debug "Got \"$SCRAPED_STRING\" from webpage."
    if [[ $SCRAPED_STRING != "$3" ]]; then
        error "PAGE: $PAGE"
        error "Checking \"$1\" expected \"$3\" got \"$SCRAPED_STRING\""
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
    if [[ $CHECK_WEBPAGE_RETVAL == 0 ]]; then
        msg2 "The $1 version is current."
    elif [[ $CHECK_WEBPAGE_RETVAL == 1 ]]; then
        error "The $2 is out-of-date!"
        HAS_ERROR=1
    elif [[ $CHECK_WEBPAGE_RETVAL == -1 ]]; then
        warning "The $2 package page was unreachable!"
    else
        error "Check returned $CHECK_WEBPAGE_RETVAL"
        HAS_ERROR=1
    fi
}

HAS_ERROR=0

# Bail if no internet
if [[ $(ping -w 1 -c 1 8.8.8.8 &> /dev/null; echo $?) != 0 ]]; then
    exit 0;
fi

msg "scraper.sh started..."

#
# Check archiso kernel version (this will change when the archiso is updated)
#
msg "Checking archiso download page for linux kernel version changes..."
check_webpage "https://www.archlinux.org/download/" "(?<=Included Kernel:</strong> )[\d\.]+" "$AZB_KERNEL_ARCHISO_VERSION"
check_result "archiso kernel version" "archiso"

#
# Check i686 linux kernel version
#
msg "Checking the online package database for i686 linux kernel version changes..."
check_webpage "https://www.archlinux.org/packages/core/i686/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_GIT_KERNEL_X32_VERSION"
check_result "i686 linux kernel package" "linux i686"

#
# Check x86_64 linux kernel version
#
msg "Checking the online package database for x86_64 linux kernel version changes..."
check_webpage "https://www.archlinux.org/packages/core/x86_64/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" "$AZB_GIT_KERNEL_X64_VERSION"
check_result "x86_64 linux kernel package" "linux x86_64"

#
# Check i686 linux-lts kernel version
#
msg "Checking the online package database for i686 linux-lts kernel version changes..."
check_webpage "https://www.archlinux.org/packages/core/i686/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "$AZB_LTS_KERNEL_X32_VERSION"
check_result "i686 linux-lts kernel package" "linux-lts i686"

#
# Check x86_64 linux-lts kernel version
#
msg "Checking the online package database for x86_64 linux-lts kernel version changes..."
check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "$AZB_LTS_KERNEL_X64_VERSION"
check_result "x86_64 linux-lts kernel package" "linux-lts x86_64"

#
# Check ZFSonLinux.org
#
msg "Checking zfsonlinux.org for new versions..."
check_webpage "http://zfsonlinux.org/" "(?<=downloads/zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" "$AZB_ZOL_VERSION"
check_result "ZOL stable version" "ZOL stable version"

#
# This is the end
# Beautiful friend
# This is the end
# My only friend, the end
#
if [[ $HAS_ERROR -eq 1 ]]; then
    exit 1;
fi
