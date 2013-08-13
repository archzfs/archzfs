#!/bin/bash

REPO_BASEPATH="/data/pacman/repo"
REMOTE_LOGIN="jalvarez@jalvarez.webfactional.com"

source "lib.sh"

check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    # Sends a message on mismatch
    MSTR=$(curl -s "$1" | grep -Po "$2")
    if [[ $MSTR != "$3" ]]; then
        error "Checking \"$1\" expected \"$3\" got \"$MSTR\""
    fi
}
