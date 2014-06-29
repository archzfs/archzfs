#!/bin/bash

#
# repo.sh adds the archzfs packages to a specified repository.
#

source ./lib.sh
source ./conf.sh

set -e

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

DRY_RUN=0       # Show commands only. Don't do anything.
AZB_REPO=""     # The destination repo for the packages
AZB_MODE_GIT=0
AZB_MODE_LTS=0

usage() {
	echo "repo.sh - Adds the compiled packages to the archzfs repo."
    echo
	echo "Usage: repo.sh [options] [mode] [repo] [package [...]]"
    echo
    echo "Options:"
    echo
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo
    echo "Modes:"
    echo
    echo "    git       Use the git packages."
    echo "    lts       Use the lts packages."
    echo
    echo "Example Usage:"
    echo
    echo "    repo.sh   git core                  :: Add git packages in the current directory to the core repo."
    echo "    repo.sh   lts core -n -d            :: Show output commands and debug info."
    echo "    repo.sh   git core package.tar.xz   :: Add package.tar.xz to the core repo."
    echo "    repo.sh   gts core *.tar.xz         :: Add *.tar.xz to the core repo."
}

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "git" ]]; then
        AZB_MODE_GIT=1
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        AZB_MODE_LTS=1
    elif [[ ${ARGS[$a]} == "core" ]]; then
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

if [[ $AZB_MODE_GIT == 0 && $AZB_MODE_LTS == 0 ]]; then
    echo -e "\n"
    error "A mode must be selected!"
    echo -e "\n"
    usage;
    exit 0;
fi

[[ $AZB_MODE_GIT == 1 ]] && AZB_KERNEL_VERSION=$AZB_GIT_KERNEL_VERSION || AZB_KERNEL_VERSION=$AZB_LTS_KERNEL_VERSION

msg "repo.sh started..."

if [[ $AZB_REPO == "" ]]; then
    error "No destination repo specified!"
    exit 1
fi

# The abs path to the repo
AZB_REPO_TARGET=$AZB_REPO_BASEPATH/$AZB_REPO

debug "DRY_RUN: "$DRY_RUN
debug "AZB_REPO: "$AZB_REPO
debug "AZB_REPO_TARGET: $AZB_REPO_TARGET"
debug "AZB_KERNEL_VERSION: $AZB_KERNEL_VERSION"

# A list of packages to install. Pulled from the command line.
pkgs=()

# Extract any packages from the arguments passed to the script
for arg in "$@"; do
    if [[ $arg =~ pkg.tar.xz$ ]]; then
        pkgs+=("${pkgs[@]}" $arg)
    fi
done

[[ $AZB_MODE_GIT == 1 ]] && path_glob="*-git" || path_glob="*-lts"

# Get the local packages if no packages were passed to the script
if [[ "${#pkgs[@]}" -eq 0 ]]; then
    # Get packages from the backup directory if the repo is demz-repo-archiso
    if [[ $AZB_REPO == "demz-repo-archiso" ]]; then
        fcmd_out=$(find ${AZB_PACKAGE_BACKUP_DIR} -iname "*${AZB_KERNEL_ARCHISO_VERSION}*.pkg.tar.xz")
    else
        fcmd_out=$(find ${path_glob} -iname "*${AZB_KERNEL_VERSION}*.pkg.tar.xz")
    fi
    for pkg in $fcmd_out; do
        pkgs+=($pkg)
    done
fi

if [[ $AZB_REPO != "" ]]; then
    msg "Creating a list of packages to add..."

    # A list of packages to add. The strings are in the form of
    # "name;pkg.tar.xz;repo_path". There must be no spaces.
    pkg_list=()

    # A list of package sources to move
    pkg_src_list=()

    [[ $AZB_MODE_GIT == 1 ]] && full_kernel_git_version || full_kernel_lts_version
    [[ $AZB_REPO == "demz-repo-archiso" ]] && full_kernel_archiso_version

    for pkg in ${pkgs[@]}; do

        arch=$(package_arch_from_path $pkg)
        name=$(package_name_from_path $pkg)
        vers=$(package_version_from_path $pkg)

        version_match=0

        # Use a specific version incase of archiso
        if [[ $AZB_REPO == "demz-repo-archiso" ]]; then
            debug "Expect version: ${AZB_ZOL_VERSION}.*${AZB_KERNEL_ARCHISO_VERSION_CLEAN}-${AZB_ARCHISO_PKGREL}"
            [[ $vers =~ ${AZB_ZOL_VERSION}.*${AZB_KERNEL_ARCHISO_VERSION_CLEAN}-${AZB_ARCHISO_PKGREL} ]] && version_match=1
        elif [[ $AZB_REPO == "demz-repo-core" && $AZB_MODE_GIT == 1 ]]; then
            [[ $vers =~ ${AZB_ZOL_VERSION}.*${AZB_GIT_KERNEL_X64_VERSION_CLEAN}-${AZB_GIT_PKGREL} ]] && version_match=1
        elif [[ $AZB_REPO == "demz-repo-core" && $AZB_MODE_LTS == 1 ]]; then
            [[ $vers =~ ${AZB_ZOL_VERSION}.*${AZB_LTS_KERNEL_X64_VERSION_CLEAN}-${AZB_LTS_PKGREL} ]] && version_match=1
        fi

        if [[ $version_match -eq 0 ]]; then
            debug "Version mismatch!"
            continue
        fi

        if [[ $arch == "any" ]]; then
            repos=`realpath $AZB_REPO_TARGET/{x86_64,i686}`
            for repo in $repos; do
                debug "Package: pkgname: $name\n\t\t  pkgver: $vers\n\t\t  pkgpath: $pkg\n\t\t  pkgdest: $AZB_REPO_TARGET/$arch"
                # Each index is [name, version, pkgpath, pkgdest]
                pkg_list+=("$name;$vers;$pkg;$repo")
            done
            continue
        fi

        debug "Using: pkgname: $name\n\t\t  pkgver: $vers\n\t\t  pkgpath: $pkg\n\t\t  pkgdest: $AZB_REPO_TARGET/$arch"
        pkg_list+=("$name;$vers;$pkg;$AZB_REPO_TARGET/$arch")

        litem="$name/$name-$vers.src.tar.gz;$AZB_REPO_TARGET/$arch"
        debug "Source: srcname: $name-$vers.src.tar.gz\n\t\t   srcdest: $AZB_REPO_TARGET/$arch"
        pkg_src_list+=($litem)
    done

    if [[ ${#pkg_list[@]} == 0 ]]; then
        error "No packages to process!"
        exit 1
    fi

    exist_pkg_mv_list=()
    new_pkg_mv_list=()
    pkg_add_list=()
    src_mv_list=()

    for ipkg in ${pkg_list[@]}; do
        IFS=';' read -a pkgopt <<< "$ipkg"

        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pkgp="${pkgopt[2]}"
        repo="${pkgopt[3]}"

        msg2 "Processing $name-$vers to $repo"
        [[ ! -d $repo ]] && run_cmd "mkdir -p $repo"

        # Move the old packages to backup
        for x in $(find $repo -type f -iname "${name}*.pkg.tar.xz"); do
            ename=$(package_name_from_path $x)
            evers=$(package_version_from_path $x)
            if [[ $ename == $name && $evers != $vers ]]; then
                # The '*' globs the signatures and package sources
                epkg="$repo/$ename-${evers}*"
                debug "Found existing package $epkg"
                exist_pkg_mv_list+=($epkg)
                src="${epkg:0:(-1)}.src.tar.gz"
                if [[ -f $src ]]; then
                    exist_pkg_mv_list+=($src)
                fi
            fi
        done

        new_pkg_mv_list+=("$pkgp*;$repo")
        bname=$(basename $pkgp)
        pkg_add_list+=("$repo/$bname;$repo")
    done

    msg "Performing file operations..."

    if [[ ${#exist_pkg_mv_list[@]} -gt 0 ]]; then
        msg2 "Move old packages and sources to backup directory"
        run_cmd "mv ${exist_pkg_mv_list[*]} $AZB_PACKAGE_BACKUP_DIR/"
    fi

    for arch in "i686" "x86_64"; do

        msg "Copying the new $arch packages and sources to the repo..."

        mv_list=""  # The packages to copy in one string
        ra_list=""  # The packages to add to the repo in one string
        repo=""     # The destination repo

        # Create the command file lists from the arrays
        for pkg in "${new_pkg_mv_list[@]}"; do
            if [[ "$pkg" == *$arch* ]]; then
                mv_list="$mv_list "$(echo "$pkg" | cut -d \; -f 1)
                repo=$(echo "$pkg" | cut -d \; -f 2)
                ra=$(echo "$pkg" | cut -d \; -f 1 | xargs basename)
                ra_list="$ra_list $repo/${ra%?}"
            fi
        done

        if [[ $mv_list == "" ]]; then
            warning "No packages to move!"
            continue
        fi
        run_cmd "mv $mv_list $repo/"

        run_cmd "repo-add -k $AZB_GPG_SIGN_KEY -s -v -f $repo/${AZB_REPO}.db.tar.xz $ra_list"
        if [[ $? -ne 0 ]]; then
            error "An error occurred adding the package to the repo!"
            exit 1
        fi

    done

    # Copy package sources
    msg "Copy package sources"
    for arch in "i686" "x86_64"; do
        src_mv_list=()
        for src in "${pkg_src_list[@]}"; do
            if [[ "$src" == *$arch* ]]; then
                src_mv_list="$src_mv_list "$(echo "$src" | cut -d \; -f 1)
                repo=$(echo "$src" | cut -d \; -f 2)
            fi
        done
        run_cmd "cp $src_mv_list $repo/"
        if [[ $arch == "x86_64" ]]; then
            # Delete the package sources
            run_cmd "rm $src_mv_list"
        fi
    done
fi
