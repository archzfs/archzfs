#!/bin/bash
#
# This script is used to make sure the archzfs repositories are up to date and
# in sync with my local repositories.
#
# This is necessary because I often forgot to push the changes to the archzfs
# host after updating my local repositories.
#
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

compute_local_repo_hash() {
    # $1: The repository to compute
    # Sets LOCAL_REPO_HASH
    msg "Computing local $1 repository hashes..."
    LFILES=$(cd $REPO_BASEPATH; sha256sum $1/{x86_64,i686}/*)
    if [[ $DEBUG == "1" ]]; then
        msg2 "Repository hash list:"
        echo "$LFILES"
    fi
    LOCAL_REPO_HASH=$(echo "$LFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Computed hash: $LOCAL_REPO_HASH"
}

compute_remote_repo_hash() {
    # $1: The repository to compute
    # Sets REMOTE_REPO_HASH
    msg "Computing remote $1 repository hashes..."
    RFILES=$(ssh $REMOTE_LOGIN "cd webapps/default; sha256sum $1/{x86_64,i686}/*")
    if [[ $DEBUG == "1" ]]; then
        msg2 "Repository hash list:"
        echo "$RFILES"
    fi
    REMOTE_REPO_HASH=$(echo "$RFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Computed hash: $REMOTE_REPO_HASH"
}

compare_repo() {
    # $1: The repo name to compare
    compute_local_repo_hash $1
    echo $LOCAL_REPO_HASH
    compute_remote_repo_hash $1
    echo $REMOTE_REPO_HASH
}

#
# Check demz-repo-archiso
#
compare_repo "demz-repo-archiso" "x86_64"

#
# Check demz-repo-core
#
