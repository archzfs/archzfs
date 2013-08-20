#!/bin/bash

source "lib.sh"
source "conf.sh"

check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    # Sends a message on mismatch
    SCRAPED_STRING=$(curl -s "$1" | grep -Po "$2")
    if [[ $SCRAPED_STRING != "$3" ]]; then
        error "Checking \"$1\" expected \"$3\" got \"$SCRAPED_STRING\""
        return 1
    fi
}

#
# Check archiso kernel version (this will change when the archiso is updated)
#
msg "Checking archiso download page for linux kernel version changes..."

check_webpage "https://www.archlinux.org/download/" \
    "(?<=Included Kernel:</strong> )[\d\.]+" $LINUX_ARCHISO

if [[ $? != 0 ]]; then
    msg2 "Sending notification..."
    send_email "Push the required packages to the archiso repo!" \
        "The archiso has been changed!"
else
    msg2 "The archiso kernel version is current."
fi

#
# Check linux kernel version
#
msg "Checking the online package database for linux kernel version changes..."

check_webpage "https://www.archlinux.org/packages/core/i686/linux/" \
    "(?<=<h2>linux )[\d\.-]+(?=</h2>)" $LINUX_VERSION_FULL

if [[ $? != 0 ]]; then
    msg2 "Sending notification..."
    send_email "Update the archzfs repository!" \
        "The linux package has been changed!"
else
    msg2 "The linux kernel package is current."
fi

#
# Check ZFSonLinux.org
#
msg "Checking zfsonlinux.org for new versions..."

check_webpage "http://zfsonlinux.org/" \
    "(?<=zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" $ZOL_VERSION

if [[ $? != 0 ]]; then
    msg2 "Sending notification..."
    send_email "Update the archzfs repository!" \
        "The ZOL packages have been changed!"
else
    msg2 "The ZOL sources are current."
fi
