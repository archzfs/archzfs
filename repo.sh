#!/bin/bash -e


#
# repo.sh adds the archzfs packages to the archzfs repository or archzfs-testing repository
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


DRY_RUN=0   # Show commands only. Don't do anything.
REPO="" # The destination repo for the packages
KERNEL_VERSION=""
KERNEL_VERSION_NO_HYPHEN=""
PKGVER_MATCH=""
MODE=""
MODE_STD=0
MODE_GIT=0
MODE_LTS=0


usage() {
    echo "${NAME} - Adds the compiled packages to the archzfs repo."
    echo
    echo "Usage: ${NAME} [options] [mode] [repo] [package [...]]"
    echo
    echo "Options:"
    echo
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo
    echo "Modes:"
    echo
    echo "    std       Use the standard packages. Used by default."
    echo "    git       Use the git packages."
    echo "    lts       Use the lts packages."
    echo
    echo "Repository target:"
    echo
    echo "    azfs      Use the archzfs repo. Used by default."
    echo "    test      Use the archzfs-testing repo."
    echo
    echo "Example Usage:"
    echo
    echo "    ${NAME}                       :: Add standard packages to the archzfs repo."
    echo "    ${NAME} lts -n -d             :: Show output commands and debug info."
    echo "    ${NAME} git package.tar.xz    :: Add package.tar.xz to the archzfs repo."
    echo "    ${NAME} gts *.tar.xz          :: Add *.tar.xz to the archzfs repo."
    trap - EXIT # Prevents exit log output
}


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "std" ]]; then
        MODE_STD=1
        MODE="std"
    elif [[ ${ARGS[$a]} == "git" ]]; then
        MODE_STD=0
        MODE_GIT=1
        MODE="git"
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        MODE_STD=0
        MODE_LTS=1
        MODE="lts"
    elif [[ ${ARGS[$a]} == "azfs" ]]; then
        REPO="archzfs"
    elif [[ ${ARGS[$a]} == "test" ]]; then
        REPO="archzfs-testing"
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    fi
done


if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi


if [[ ${REPO} == "" ]]; then
    error "No destination repo specified!"
    exit 1
fi


if [[ ${MODE} == "" ]]; then
    echo
    error "A mode must be selected!"
    usage;
    exit 0;
fi


msg "$(date) :: ${NAME} started..."


# The abs path to the repo
REPO_TARGET=${REPO_BASEPATH}/${REPO}


# Set the kernel version
if [[ ${MODE_STD} -eq 1 ]]; then
    KERNEL_VERSION=$(kernel_version_full ${STD_KERNEL_VERSION})
    KERNEL_VERSION_NO_HYPHEN=$(kernel_version_full_no_hyphen ${STD_KERNEL_VERSION})
    PKGVER_MATCH="${ZOL_VERSION}_${KERNEL_VERSION_NO_HYPHEN}-${STD_PKGREL}"
elif [[ ${MODE_LTS} -eq 1 ]]; then
    KERNEL_VERSION=$(kernel_version_full ${LTS_KERNEL_VERSION})
    KERNEL_VERSION_NO_HYPHEN=$(kernel_version_full_no_hyphen ${LTS_KERNEL_VERSION})
    PKGVER_MATCH="${ZOL_VERSION}_${KERNEL_VERSION_NO_HYPHEN}-${LTS_PKGREL}"
elif [[ ${MODE_GIT} -eq 1 ]]; then
    KERNEL_VERSION=$(kernel_version_full ${GIT_KERNEL_VERSION})
    KERNEL_VERSION_NO_HYPHEN=$(kernel_version_full_no_hyphen ${GIT_KERNEL_VERSION})
    PKGVER_MATCH="${ZOL_VERSION}.*${KERNEL_VERSION_NO_HYPHEN}-${GIT_PKGREL}"
fi


debug "DRY_RUN: "${DRY_RUN}
debug "REPO: "${REPO}
debug "REPO_TARGET: ${REPO_TARGET}"
debug "KERNEL_VERSION: ${KERNEL_VERSION}"
debug "KERNEL_VERSION_NO_HYPHEN: ${KERNEL_VERSION_NO_HYPHEN}"
debug "PKGVER_MATCH: ${PKGVER_MATCH}"


# A list of packages to install. Pulled from the command line.
pkgs=()


# Extract any packages from the arguments passed to the script
for arg in "$@"; do
    if [[ ${arg} =~ pkg.tar.xz$ ]]; then
        pkgs+=("${pkgs[@]}" ${arg})
    fi
done


if [[ ${REPO} != "" ]]; then
    msg "Creating a list of packages to add..."

    # Get the local packages if no packages were passed to the script
    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        # Get packages from the backup directory if the repo is demz-repo-archiso
        run_cmd_show_and_capture_output_no_dry_run "find packages/${MODE}/ -iname '*${KERNEL_VERSION_NO_HYPHEN}*.pkg.tar.xz'"
        for pkg in ${RUN_CMD_OUTPUT}; do
            pkgs+=(${pkg})
        done
    fi

    # A list of packages to add. The strings are in the form of
    # "name;pkg.tar.xz;repo_path". There must be no spaces.
    pkg_list=()

    # A list of package sources to move
    pkg_src_list=()

    for pkg in ${pkgs[@]}; do
        arch=$(package_arch_from_path ${pkg})
        name=$(package_name_from_path ${pkg})
        vers=$(package_version_from_path ${pkg})

        debug "Version match check: arch: ${arch} name: ${name} vers: ${vers} PKGVER_MATCH: ${PKGVER_MATCH}"

        if ! [[ ${vers} =~ ^${PKGVER_MATCH} ]]; then
            debug "Version mismatch!"
            continue
        fi

        if [[ ${arch} == "any" ]]; then
            repos=`realpath ${REPO_TARGET}/x86_64`
            for repo in ${repos}; do
                debug "Package: pkgname: ${name} pkgver: ${vers} pkgpath: ${pkg} pkgdest: ${REPO_TARGET}/${arch}"
                # Each index is [name, version, pkgpath, pkgdest]
                pkg_list+=("${name};${vers};${pkg};${repo}")
            done
            continue
        fi

        debug "Using: pkgname: ${name} pkgver: ${vers} pkgpath: ${pkg} pkgdest: ${REPO_TARGET}/${arch}"
        pkg_list+=("${name};${vers};${pkg};${REPO_TARGET}/${arch}")

        litem="packages/${MODE}/${name}/${name}-${vers}.src.tar.gz;${REPO_TARGET}/${arch}"
        debug "Source: srcname: ${name}-${vers}.src.tar.gz srcdest: ${REPO_TARGET}/${arch}"

        pkg_src_list+=(${litem})
    done

    if [[ ${#pkg_list[@]} == 0 ]]; then
        error "No packages to process!"
        exit 1
    fi

    exist_pkg_mv_list=()
    new_pkg_cp_list=()
    pkg_add_list=()
    src_mv_list=()

    for ipkg in ${pkg_list[@]}; do
        IFS=';' read -a pkgopt <<< "${ipkg}"

        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pkgp="${pkgopt[2]}"
        repo="${pkgopt[3]}"

        msg2 "Processing package ${name}-${vers} to ${repo}"
        [[ ! -d ${repo} ]] && run_cmd "mkdir -p ${repo}"

        # Move the old packages to backup
        for x in $(find ${repo} -type f -iname "${name}*.pkg.tar.xz"); do
            ename=$(package_name_from_path ${x})}
            evers=$(package_version_from_path ${x})}
            if [[ ${ename} == ${name} && ${evers} != ${vers} ]]; then
                # The '*' globs the signatures and package sources
                epkg="${repo}/${ename}-${evers}*"
                debug "epkg: ${epkg}"
                exist_pkg_mv_list+=(${epkg})
            fi
        done

        # The * is to catch the signature
        new_pkg_cp_list+=("${pkgp}*;${repo}")
        bname=$(basename ${pkgp})
        pkg_add_list+=("${repo}/${bname};${repo}")
    done

    # Build mv list with unique source packages since i686 and x86_64 both have identical source packages. If we attempt to
    # move with identical file names, cp will fail with the "cp: will not overwrite just-created" error.
    exist_pkg_mv_list_uniq=()
    for ((i = 0; i < ${#exist_pkg_mv_list[@]}; i++)); do
        if [[ ${exist_pkg_mv_list[$i]} != *src.tar.gz ]]; then
            exist_pkg_mv_list_uniq+=(${exist_pkg_mv_list[$i]})
            continue
        fi
    done

    msg "Performing file operations..."

    # Remove the existing packages in the repo path
    if [[ ${exist_pkg_mv_list[@]} -ne 0 ]]; then
        run_cmd "rm -f ${exist_pkg_mv_list[*]}"
    fi

    for arch in "x86_64"; do
        msg "Copying the new ${arch} packages to the repo..."

        cp_list=""  # The packages to copy in one string
        ra_list=""  # The packages to add to the repo in one string
        repo=""     # The destination repo

        # Create the command file lists from the arrays
        for pkg in "${new_pkg_cp_list[@]}"; do
            if [[ "${pkg}" == *${arch}* ]]; then
                cp_list="$cp_list "$(echo "${pkg}" | cut -d \; -f 1)
                repo=$(echo "${pkg}" | cut -d \; -f 2)
                ra=$(echo "${pkg}" | cut -d \; -f 1 | xargs basename)
                ra_list="${ra_list} ${repo}/${ra%?}"
            fi
        done

        if [[ ${cp_list} == "" ]]; then
            warning "No packages to copy!"
            continue
        fi

        run_cmd "cp -fv ${cp_list} ${repo}/"
        run_cmd "repo-add -k ${GPG_SIGN_KEY} -s -v ${repo}/${REPO}.db.tar.xz ${ra_list}"
        if [[ ${RUN_CMD_RETURN} -ne 0 ]]; then
            error "An error occurred adding the package to the repo!"
            exit 1
        fi
    done

    # Copy package sources
    msg "Copy package sources"
    for arch in "x86_64"; do
        src_cp_list=()
        for src in "${pkg_src_list[@]}"; do
            if [[ "${src}" == *${arch}* ]]; then
                debug "SRC='${src}'"
                src_cp_list="${src_cp_list} "$(echo "${src}" | cut -d \; -f 1)
                repo=$(echo "${src}" | cut -d \; -f 2)
            fi
        done
        run_cmd "cp -fv ${src_cp_list} ${repo}/"
    done
fi
