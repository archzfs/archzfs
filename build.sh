#!/bin/bash


#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager) is required!
#


NAME=$(basename $0)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMMANDS=()
MODE=""
MODE_NAME=""
MODE_LIST=()
UPDATE_FUNCS=()


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 1
fi
source_safe "${SCRIPT_DIR}/conf.sh"


# setup signal traps
trap "trap_quit" TERM HUP QUIT
trap "trap_abort" INT
trap "trap_usr1" USR1
trap "trap_exit" EXIT


usage() {
    echo "${NAME} - A build script for archzfs"
    echo
    echo "Usage: ${NAME} [options] mode command [command ...]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    echo "    -u:    Perform an update in the clean chroot."
    echo "    -C:    Remove all files that are not package sources."
    echo
    echo "Modes:"
    echo
    for mode in "${MODE_LIST[@]}"; do
        mode_name=$(echo ${mode} | cut -f2 -d:)
        mode_desc=$(echo ${mode} | cut -f3 -d:)
        echo -e "    ${mode_name}    ${mode_desc}"
    done
    echo
    echo "Commands:"
    echo
    echo "    make          Build all packages."
    echo "    test          Build test packages."
    echo "    update        Update all git PKGBUILDs using conf.sh variables."
    echo "    update-test   Update all git PKGBUILDs using the testing conf.sh variables."
    echo "    sign          GPG detach sign all compiled packages (default)."
    echo "    sources       Build the package sources. This is done by default when using the make command."
    echo
    echo "Examples:"
    echo
    echo "    ${NAME} -C                       :: Remove all compiled packages"
    echo "    ${NAME} git make -u              :: Update the chroot and build all of the packages"
    echo "    ${NAME} lts update               :: Update PKGBUILDS only"
    echo "    ${NAME} git update make -u       :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo "    ${NAME} lts update-test test -u  :: Update PKGBUILDs (use testing versions), update the chroot, and make all of the packages"
    trap - EXIT # Prevents exit log output
}


build_sources() {
    for pkg in ${pkg_list}; do
        msg "Building source for ${pkg}";
        run_cmd "cd \"${SCRIPT_DIR}/packages/${MODE_NAME}/${pkg}\" && mkaurball -f"
    done
}


sign_packages() {
    files=$(find ${SCRIPT_DIR} -iname "*.pkg.tar.xz")
    debug "Found files: ${files}"
    msg "Signing the packages with GPG"
    for f in ${files}; do
        if [[ ! -f "${f}.sig" ]]; then
            msg2 "Signing ${f}"
            run_cmd_no_output "gpg --batch --yes --detach-sign --use-agent -u ${gpg_sign_key} \"${f}\""
        fi
    done
}


git_check_repo() {
    for pkg in ${pkg_list}; do
        local reponame="spl"
        local url="${spl_git_url}"
        if [[ ${pkg} =~ ^zfs ]]; then
            url="${zfs_git_url}"
            reponame="zfs"
        fi
        local repopath="${SCRIPT_DIR}/packages/${MODE_NAME}/${pkg}/${reponame}"

        debug "GIT URL: ${url}"
        debug "GIT REPO: ${repopath}"

        if [[ ! -d "${repopath}"  ]]; then
            msg2 "Cloning repo '${repopath}'"
            run_cmd_no_dry_run "git clone --mirror '${url}' '${repopath}'"
            if [[ ${RUN_CMD_RETURN} -ne 0 ]]; then
                error "Failure while cloning ${url} repo"
                exit 1
            fi
        else
            msg2 "Updating repo '${repopath}'"
            run_cmd_no_dry_run "cd ${repopath} && git fetch --all -p"
            if [[ ${RUN_CMD_RETURN} -ne 0 ]]; then
                error "Failure while fetching ${url} repo"
                exit 1
            fi
        fi
    done
}


git_calc_pkgver() {
    for repo in "spl" "zfs"; do
        msg2 "Cloning working copy for ${repo}"
        local sha=${spl_git_commit}
        local kernvers=$(kernel_version_full_no_hyphen ${kernel_version})
        if [[ ${repo} =~ ^zfs ]]; then
            sha=${zfs_git_commit}
        fi

        pkg=$(eval "echo \${${repo}_pkgname}")
        debug "Using package '${pkg}'"

        # Checkout the git repo to a work directory
        local cmd="/usr/bin/bash -s << EOF 2>/dev/null\\n"
        cmd+="[[ -d temp ]] && rm -r temp\\n"
        cmd+="mkdir temp && cd temp\\n"
        cmd+="git clone ../packages/${MODE_NAME}/${pkg}/${repo} && cd ${repo}\\n"
        cmd+="git checkout -b azb ${sha}\\n"
        cmd+="EOF\\n"
        run_cmd_no_output_no_dry_run "${cmd}"

        # Get the version number past the last tag
        msg2 "Calculating PKGVER"
        cmd="cd temp/${repo} && "
        cmd+="echo \$(git describe --long | sed -r 's/^${repo}-//;s/([^-]*-g)/r\1/;s/-/_/g')_${kernvers}"
        run_cmd_no_output_no_dry_run "${cmd}"

        if [[ ${repo} =~ ^spl ]]; then
            spl_pkgver=${RUN_CMD_OUTPUT}
            debug "spl_pkgver: ${spl_pkgver}"
        elif [[ ${repo} =~ ^zfs ]]; then
            zfs_pkgver=${RUN_CMD_OUTPUT}
            debug "zfs_pkgver: ${zfs_pkgver}"
        fi

        # Cleanup
        msg2 "Removing working directory"
        run_cmd_no_output_no_dry_run "rm -vrf temp"
    done
}

generate_package_files() {
    debug "kernel_version_full: ${kernel_version_full}"
    debug "kernel_mod_path: ${kernel_mod_path}"
    debug "archzfs_package_group: ${archzfs_package_group}"
    debug "header: ${header}"
    debug "spl_pkgver: ${spl_pkgver}"
    debug "spl_pkgrel: ${spl_pkgrel}"
    debug "zfs_pkgver: ${zfs_pkgver}"
    debug "zfs_pkgrel: ${zfs_pkgrel}"
    debug "spl_makedepends: ${spl_makedepends}"
    debug "zfs_makedepends: ${zfs_makedepends}"
    debug "zol_version: ${zol_version}"
    debug "spl_utils_pkgname: ${spl_utils_pkgname}"
    debug "spl_pkgname: ${spl_pkgname}"
    debug "zfs_utils_pkgname: ${zfs_utils_pkgname}"
    debug "zfs_pkgname: ${zfs_pkgname}"
    debug "spl_utils_pkgbuild_path: ${spl_utils_pkgbuild_path}"
    debug "spl_pkgbuild_path: ${spl_pkgbuild_path}"
    debug "zfs_utils_pkgbuild_path: ${zfs_utils_pkgbuild_path}"
    debug "zfs_pkgbuild_path: ${zfs_pkgbuild_path}"
    debug "zfs_workdir: ${zfs_workdir}"
    debug "zfs_src_target: ${zfs_src_target}"
    debug "zfs_src_hash: ${zfs_src_hash}"
    debug "spl_workdir: ${spl_workdir}"
    debug "spl_src_target: ${spl_src_target}"
    debug "spl_src_hash: ${spl_src_hash}"
    debug "spl_hostid_hash: ${spl_hostid_hash}"
    debug "zfs_bash_completion_hash: ${zfs_bash_completion_hash}"
    debug "zfs_initcpio_install_hash: ${zfs_initcpio_install_hash}"
    debug "zfs_initcpio_hook_hash: ${zfs_initcpio_hook_hash}"

    # Make sure our target directory exists
    run_cmd_no_output "[[ -d "${spl_utils_pkgbuild_path}" ]] || mkdir -p ${spl_utils_pkgbuild_path}"
    run_cmd_no_output "[[ -d "${spl_pkgbuild_path}" ]] || mkdir -p ${spl_pkgbuild_path}"
    run_cmd_no_output "[[ -d "${zfs_utils_pkgbuild_path}" ]] || mkdir -p ${zfs_utils_pkgbuild_path}"
    run_cmd_no_output "[[ -d "${zfs_pkgbuild_path}" ]] || mkdir -p ${zfs_pkgbuild_path}"

    # Finally, generate the update packages ...
    msg2 "Creating spl-utils PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl-utils/PKGBUILD.sh"
    msg2 "Copying spl-utils.hostid"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/spl-utils/spl-utils.hostid ${spl_utils_pkgbuild_path}/spl-utils.hostid"

    msg2 "Creating spl PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl/PKGBUILD.sh"
    msg2 "Creating spl.install"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl/spl.install.sh"

    msg2 "Creating zfs-utils PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs-utils/PKGBUILD.sh"
    msg2 "Copying zfs-utils.bash-completion"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.bash-completion-r1 ${zfs_utils_pkgbuild_path}/zfs-utils.bash-completion-r1"
    msg2 "Copying zfs-utils.initcpio.hook"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.initcpio.hook ${zfs_utils_pkgbuild_path}/zfs-utils.initcpio.hook"
    msg2 "Copying zfs-utils.initcpio.install"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.initcpio.install ${zfs_utils_pkgbuild_path}/zfs-utils.initcpio.install"

    msg2 "Creating zfs PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs/PKGBUILD.sh"
    msg2 "Creating zfs.install"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs/zfs.install.sh"
}


generate_mode_list() {
    for mode in $(ls ${SCRIPT_DIR}/src/kernels); do
        mode_name=$(source ${SCRIPT_DIR}/src/kernels/${mode}; echo ${mode_name})
        mode_desc=$(source ${SCRIPT_DIR}/src/kernels/${mode}; echo ${mode_desc})
        MODE_LIST+=("${mode%.*}:${mode_name}:${mode_desc}")
    done
}


build_packages() {
    for pkg in ${pkg_list}; do
        msg "Building ${pkg}..."
        run_cmd "cd \"${SCRIPT_DIR}/packages/${MODE_NAME}/${pkg}\" && sudo ccm64 s && mksrcinfo"
        if [[ ${RUN_CMD_RETURN} -ne 0 ]]; then
            error "A problem occurred building the package"
            exit 1
        fi
        msg2 "${pkg} package files:"
        run_cmd "tree ${chroot_path}/build/${pkg}/pkg"
    done
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
}


get_kernel_update_funcs() {
    for kernel in $(ls ${SCRIPT_DIR}/src/kernels); do
        if [[ ${kernel%.*} != ${MODE_NAME} ]]; then
            continue
        fi
        updatefuncs=$(cat "${SCRIPT_DIR}/src/kernels/${kernel}" | grep -oh "update_.*_pkgbuilds")
        for func in ${updatefuncs}; do UPDATE_FUNCS+=("${func}"); done
    done
}


# Do this early so it is possible to see the output
if check_debug; then
    DEBUG=1
fi


generate_mode_list


if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "make" ]]; then
        COMMANDS+=("make")
    elif [[ ${ARGS[$a]} == "test" ]]; then
        COMMANDS+=("test")
    elif [[ ${ARGS[$a]} == "update" ]]; then
        COMMANDS+=("update")
    elif [[ ${ARGS[$a]} == "update-test" ]]; then
        COMMANDS+=("update-test")
    elif [[ ${ARGS[$a]} == "sources" ]]; then
        COMMANDS+=("sources")
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        COMMANDS+=("sign")
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        COMMANDS+=("cleanup")
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        COMMANDS+=("update_chroot")
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    else
        check_mode "${ARGS[$a]}"
        debug "have mode '${MODE}'"
    fi
done


if have_command "cleanup" && [[ $# -gt 1 ]]; then
    echo
    error "-C should be used by itself!"
    usage;
    exit 0;
fi


if ! have_command "cleanup" && [[ ${#COMMANDS[@]} -eq 0 || ${MODE} == "" ]]; then
    echo
    error "A build mode and command must be selected!"
    usage;
    exit 0;
fi


if have_command "cleanup"; then
    msg "Cleaning up work files..."
    run_cmd "find . \( -iname \"*.log\" -o -iname \"*.pkg.tar.xz*\" -o -iname \"*.src.tar.gz\" \) -print -exec rm -rf {} \\;"
    run_cmd "rm -rf  */src"
    run_cmd "rm -rf */*.tar.gz"
    exit
fi


msg "$(date) :: ${NAME} started..."


if have_command "update_chroot"; then
    msg "Updating the x86_64 clean chroot..."
    run_cmd "sudo ccm64 u"
fi


if [[ ${MODE} != "" ]]; then
    get_kernel_update_funcs

    export SCRIPT_DIR MODE MODE_NAME BUILD SIGN SOURCES UPDATE_PKGBUILDS
    source_safe "src/kernels/${MODE_NAME}.sh"

    for func in "${UPDATE_FUNCS[@]}"; do
        debug "Evaluating '${func}'"
        "${func}"
        if have_command "update"; then
            msg "Updating PKGBUILDs for kernel '${MODE_NAME}'"
            generate_package_files
        fi
        if have_command "make"; then
            build_packages
            sign_packages
            build_sources
        fi
        if have_command "sources"; then
            build_sources
        fi
    done

    if have_command "sign"; then
        sign_packages
    fi
fi
