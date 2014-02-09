#!/bin/bash

#
# repo.sh adds the archzfs packages to a specified repository.
#

source ./lib.sh
source ./conf.sh

set -e

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

DRY_RUN=0   # Show commands only. Don't do anything.
AZB_REPO=""     # The destination repo for the packages

usage() {
	echo "repo.sh - Adds the compiled packages to the archzfs repo."
    echo
	echo "Usage: repo.sh [options] [repo] [package [...]]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    echo
    echo "Example Usage:"
    echo
    echo "       repm core                  :: Add packages in the current directory to the core repo."
    echo "       repm core -n -d            :: Show output commands and debug info."
    echo "       repm core package.tar.xz   :: Add package.tar.xz to the core repo."
    echo "       repm core *.tar.xz         :: Add *.tar.xz to the core repo."
}

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "core" ]]; then
        AZB_REPO="demz-repo-core"
    elif [[ ${ARGS[$a]} == "community" ]]; then
        AZB_REPO="demz-repo-community"
    elif [[ ${ARGS[$a]} == "testing" ]]; then
        AZB_REPO="demz-repo-testing"
    elif [[ ${ARGS[$a]} == "archiso" ]]; then
        AZB_REPO="demz-repo-archiso"
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done

if [ $# -lt 1 ]; then
    usage;
    exit 0;
fi

msg "repo.sh started..."

if [[ $AZB_REPO == "" ]]; then
    error "No destination repo specified!"
    exit 1
fi

# The abs path to the repo
AZB_REPO_TARGET=$AZB_REPO_BASEPATH/$AZB_REPO

# The abs path to the package source directory in the repo
AZB_SOURCE_TARGET="$AZB_REPO_TARGET/sources/"

debug "DRY_RUN: "$DRY_RUN
debug "AZB_REPO: "$AZB_REPO
debug "AZB_REPO_TARGET: $AZB_REPO_TARGET"
debug "AZB_SOURCE_TARGET: $AZB_SOURCE_TARGET"

# A list of packages to install. Pulled from the command line.
pkgs=()

# Extract any packages from the arguments passed to the script
for arg in "$@"; do
    if [[ $arg =~ pkg.tar.xz$ ]]; then
        pkgs+=("${pkgs[@]}" $arg)
    fi
done

# Get the local packages if no packages were passed to the script
if [[ "${#pkgs[@]}" -eq 0 ]]; then
    for pkg in $(find . -iname "*.pkg.tar.xz"); do
        debug "Found package: $pkg"
        pkgs+=($pkg)
    done
fi

for pkg in ${pkgs[@]}; do
    debug "PKG: $pkg"
done

if [[ $AZB_REPO != "" ]]; then

    msg "Creating a list of packages to add..."
    # A list of packages to add. The strings are in the form of
    # "name;pkg.tar.xz;repo_path". There must be no spaces.
    pkg_list=()

    # Add packages to the pkg_list
    for pkg in ${pkgs[@]}; do

        arch=$(package_arch_from_path $pkg)
        name=$(package_name_from_path $pkg)
        vers=$(package_version_from_path $pkg)
        debug "DEBUG: Found package: $name, $arch, $vers"
        if [[ $vers != $AZB_FULL_VERSION ]]; then
            continue
        fi

        if [[ $arch == "any" ]]; then
            repos=`realpath $AZB_REPO_TARGET/{x86_64,i686}`
            for repo in $repos; do
                debug "Using: $name;$vers;$pkg;$repo"
                pkg_list+=("$name;$vers;$pkg;$repo")
            done
            continue
        fi

        debug "Using: $name;$vers;$pkg;$AZB_REPO_TARGET/$arch"
        pkg_list+=("$name;$vers;$pkg;$AZB_REPO_TARGET/$arch")

    done

    if [[ ${#pkg_list[@]} == 0 ]]; then
        error "No packages to process!"
        exit 1
    fi

    pkg_mv_list=()
    pkg_cp_list=()
    pkg_add_list=()
    src_rm_list=()
    src_cp_list=()

    for ipkg in ${pkg_list[@]}; do
        IFS=';' read -a pkgopt <<< "$ipkg"

        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pbin="${pkgopt[2]}"
        repo="${pkgopt[3]}"

        msg2 "Processing $pbin to $repo"
        [[ ! -d $repo ]] && run_cmd "mkdir -p $repo"

        # Move the old packages to backup
        for x in $(find $repo -type f -iname "${name}*.pkg.tar.xz"); do
            ename=$(package_name_from_path $x)
            evers=$(package_version_from_path $x)
            if [[ $ename == $name && $evers != $vers ]]; then
                debug "Found Old Package: $ename, Version: $evers"
                # The '*' globs the signatures
                debug "Added $repo/$ename-${evers}* to move list"
                pkg_mv_list+=("$repo/$ename-${evers}*")
            fi
        done

        pkg_cp_list+=("$pbin*;$repo")

        bname=$(basename $pbin)
        pkg_add_list+=("$repo/$bname;$repo")

        # Copy the sources to the source target
        [[ ! -d $AZB_SOURCE_TARGET ]] && run_cmd "mkdir -p $AZB_SOURCE_TARGET"

        # If there is zfs and zfs-utils in the directory, the glob will get
        # both zfs and zfs-utils when globbing zfs*, therefore we have to check
        # each file to see if it is the one we want.
        for file in $(find -L $AZB_SOURCE_TARGET -iname "${name}*.src.tar.gz" 2>/dev/null); do
            src_name=$(tar -O -xzvf "$file" $name/PKGBUILD 2> /dev/null | grep "pkgname" | cut -d \" -f 2)
            if [[ $src_name == $name ]]; then
                debug "Added $src_name ($file) to src_rm_list"
                src_rm_list+=("$file")
            fi
        done
        src_cp_list+=("./$name/$name-${vers}.src.tar.gz")
    done

    msg "Performing file operations..."

    msg2 "Move old packages to backup directory"
    run_cmd "mv ${pkg_mv_list[*]} $AZB_REPO_BASEPATH/backup/"

    for arch in "i686" "x86_64"; do

        msg "Copying the new $arch packages and adding to repo..."

        cp_list=""
        ra_list=""
        repo=""

        # Create the command file lists from the arrays
        for pkg in "${pkg_cp_list[@]}"; do
            if [[ "$pkg" == *$arch* ]]; then
                debug "Copying: $pkg"
                cp_list="$cp_list "$(echo "$pkg" | cut -d \; -f 1)
                repo=$(echo "$pkg" | cut -d \; -f 2)
                ra=$(echo "$pkg" | cut -d \; -f 1 | xargs basename)
                ra_list="$ra_list $repo/${ra%?}"
            fi
        done

        run_cmd "cp $cp_list $repo/"

        run_cmd "repo-add -k $AZB_GPG_SIGN_KEY -s -v -f $repo/${AZB_REPO}.db.tar.xz $ra_list"
        if [[ $? -ne 0 ]]; then
            error "An error occurred adding the package to the repo!"
            exit 1
        fi

    done

    if [[ ${#src_rm_list[@]} -ne 0 ]]; then
        zlist=$(echo "${src_rm_list[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        run_cmd "rm $zlist"
    fi

    nlist=$(echo "${src_cp_list[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    run_cmd "cp $nlist $AZB_SOURCE_TARGET"

fi
