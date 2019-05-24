#!/bin/bash


#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager) is required!
#


args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/conf.sh"

# save conf variables
zfs_src_hash_conf=${zfs_src_hash}

usage() {
    echo "${script_name} - A build script for archzfs"
    echo
    echo "Usage: ${script_name} [options] mode command [command ...]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    echo "    -s:    Skip git packages and only build stable packages"
    echo "    -R:    Perform git reset in packages directory for Mode."
    echo "    -u:    Perform an update in the clean chroot."
    echo "    -U:    Update the file sums in conf.sh."
    echo "    -C:    Remove all files that are not package sources."
    echo
    echo "Modes:"
    echo
    for ml in "${mode_list[@]}"; do
        mn=$(echo ${ml} | cut -f2 -d:)
        md=$(echo ${ml} | cut -f3 -d:)
        if [[ ${#mn} -gt 3 ]]; then
            echo -e "    ${mn}\t  ${md}"
        else
            echo -e "    ${mn}\t\t  ${md}"
        fi
    done
    echo "    all           Select and use all available packages"
    echo
    echo "Commands:"
    echo
    echo "    make          Build all packages."
    echo "    test          Build test packages."
    echo "    update        Update all git PKGBUILDs using conf.sh variables."
    echo "    update-test   Update all git PKGBUILDs using the testing conf.sh variables."
    echo "    sources       Build the package sources. This is done by default when using the make command."
    echo
    echo "Examples:"
    echo
    echo "    ${script_name} std -C                   :: Remove all compiled packages for the standard kernels"
    echo "    ${script_name} std make -u              :: Update the chroot and build all of the packages"
    echo "    ${script_name} lts update               :: Update PKGBUILDS only"
    echo "    ${script_name} std update make -u       :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo "    ${script_name} lts update-test test -u  :: Update PKGBUILDs (use testing versions), update the chroot, and make all of the packages"
    exit 155
}


cleanup() {
    # $1: the package name
    msg "Cleaning up work files..."
    fincs='-iname "*.log" -o -iname "*.pkg.tar.xz*" -o -iname "*.src.tar.gz"'
    run_cmd "find ${script_dir}/packages/${kernel_name}/$1 \( ${fincs} \) -print -exec rm -rf {} \\;"
    run_cmd "rm -rf  */src"
    run_cmd "rm -rf */*.tar.gz"
}


build_sources() {
    for pkg in "${pkg_list[@]}"; do

        if check_skip_src $pkg; then
            msg "skipping"
            continue;
        fi

        msg "Building source for ${pkg}";
        run_cmd "chown -R ${makepkg_nonpriv_user}: '${script_dir}/packages/${kernel_name}/${pkg}'"
        run_cmd "su - ${makepkg_nonpriv_user} -s /bin/sh -c 'cd \"${script_dir}/packages/${kernel_name}/${pkg}\" && makepkg --printsrcinfo > .SRCINFO && makepkg --source'"
    done
}


generate_package_files() {
    debug "kernel_version_full: ${kernel_version_full}"
    debug "kernel_mod_path: ${kernel_mod_path}"
    debug "archzfs_package_group: ${archzfs_package_group}"
    debug "header: ${header}"
    debug "zfs_pkgver: ${zfs_pkgver}"
    debug "zfs_pkgrel: ${zfs_pkgrel}"
    debug "zfs_makedepends: ${zfs_makedepends}"
    debug "zol_version: ${zol_version}"
    debug "zfs_utils_pkgname: ${zfs_utils_pkgname}"
    debug "zfs_pkgname: ${zfs_pkgname}"
    debug "zfs_utils_pkgbuild_path: ${zfs_utils_pkgbuild_path}"
    debug "zfs_pkgbuild_path: ${zfs_pkgbuild_path}"
    debug "zfs_workdir: ${zfs_workdir}"
    debug "zfs_src_target: ${zfs_src_target}"
    debug "zfs_src_hash: ${zfs_src_hash}"
    debug "zfs_initcpio_install_hash: ${zfs_initcpio_install_hash}"
    debug "zfs_initcpio_hook_hash: ${zfs_initcpio_hook_hash}"

    # Make sure our target directory exists
    if [[ "${kernel_name}" == "_utils" ]]; then
        run_cmd_no_output "[[ -d "${zfs_utils_pkgbuild_path}" ]] || mkdir -p ${zfs_utils_pkgbuild_path}"
    elif [[ "${kernel_name}" == "dkms" ]]; then
        run_cmd_no_output "[[ -d "${zfs_dkms_pkgbuild_path}" ]] || mkdir -p ${zfs_dkms_pkgbuild_path}"
    else
        run_cmd_no_output "[[ -d "${zfs_pkgbuild_path}" ]] || mkdir -p ${zfs_pkgbuild_path}"
    fi

    # Finally, generate the update packages ...
    if [[ "${kernel_name}" == "_utils" ]]; then
        msg2 "Removing old zfs-utils patches (if any)"
        run_cmd_no_output "rm -f ${zfs_utils_pkgbuild_path}/*.patch"
        msg2 "Removing old bash completion file"
        run_cmd_no_output "rm -f ${zfs_utils_pkgbuild_path}/zfs-utils.bash-completion-r1"
        msg2 "Copying zfs-utils patches (if any)"
        run_cmd_no_output "find ${script_dir}/src/zfs-utils -name \*.patch -exec cp {} ${zfs_utils_pkgbuild_path} \;"
        msg2 "Creating zfs-utils PKGBUILD"
        run_cmd_no_output "source ${script_dir}/src/zfs-utils/PKGBUILD.sh"
        msg2 "Creating zfs-utils.install"
        run_cmd_no_output "source ${script_dir}/src/zfs-utils/zfs-utils.install.sh"
        msg2 "Copying zfs-utils hooks"
        run_cmd_no_output "cp ${script_dir}/src/zfs-utils/*.hook ${zfs_utils_pkgbuild_path}/"
        msg2 "Copying zfs-utils hook install files"
        run_cmd_no_output "cp ${script_dir}/src/zfs-utils/*.install ${zfs_utils_pkgbuild_path}/"
    elif [[ "${kernel_name}" == "dkms" ]]; then
        msg2 "Removing old zfs patches (if any)"
        run_cmd_no_output "rm -f ${zfs_dkms_pkgbuild_path}/*.patch"
        msg2 "Copying zfs patches (if any)"
        run_cmd_no_output "find ${script_dir}/src/zfs-dkms -name \*.patch -exec cp {} ${zfs_dkms_pkgbuild_path} \;"
        msg2 "Creating zfs-dkms PKGBUILD"
        run_cmd_no_output "source ${script_dir}/src/zfs-dkms/PKGBUILD.sh"
    else
        msg2 "Removing old zfs patches (if any)"
        run_cmd_no_output "rm -f ${zfs_pkgbuild_path}/*.patch"
        msg2 "Copying zfs patches (if any)"
        run_cmd_no_output "find ${script_dir}/src/zfs -name \*.patch -exec cp {} ${zfs_pkgbuild_path} \;"
        msg2 "Creating zfs PKGBUILD"
        run_cmd_no_output "source ${script_dir}/src/zfs/PKGBUILD.sh"
        msg2 "Creating zfs.install"
        run_cmd_no_output "source ${script_dir}/src/zfs/zfs.install.sh"
    fi

    msg "Update diffs ..."
    if [[ ! -z ${zfs_utils_pkgbuild_path} ]]; then
        run_cmd "cd ${script_dir}/${zfs_utils_pkgbuild_path} && git --no-pager diff"
    fi

    if [[ ! -z ${zfs_pkgbuild_path} ]]; then
        run_cmd "cd ${script_dir}/${zfs_pkgbuild_path} && git --no-pager diff"
    fi

    msg "Resetting ownership"
    run_cmd "chown -R ${makepkg_nonpriv_user}: '${script_dir}/packages/${kernel_name}/'"
}


build_packages() {
    for pkg in "${pkg_list[@]}"; do

        if check_skip_build $pkg; then
            msg "skipping"
            continue;
        fi

        msg "Building ${pkg}..."

        # Cleanup all previously built packages for the current package
        cleanup ${pkg}

        run_cmd "cd \"${script_dir}/packages/${kernel_name}/${pkg}\" && ccm64 s"
        if [[ ${run_cmd_return} -ne 0 ]]; then
            error "A problem occurred building the package"
            exit 1
        fi
    done
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
}


generate_mode_list


if [[ $# -lt 1 ]]; then
    usage
fi


if [[ ${EUID} -ne 0 ]]; then
    error "This script must be run as root."
    exit 155;
fi


for (( a = 0; a < $#; a++ )); do
    if [[ ${args[$a]} == "make" ]]; then
        commands+=("make")
    elif [[ ${args[$a]} == "test" ]]; then
        commands+=("test")
    elif [[ ${args[$a]} == "update" ]]; then
        commands+=("update")
    elif [[ ${args[$a]} == "update-test" ]]; then
        commands+=("update-test")
    elif [[ ${args[$a]} == "sources" ]]; then
        commands+=("sources")
    elif [[ ${args[$a]} == "-C" ]]; then
        commands+=("cleanup")
    elif [[ ${args[$a]} == "-u" ]]; then
        commands+=("update_chroot")
    elif [[ ${args[$a]} == "-U" ]]; then
        commands+=("update_sums")
    elif [[ ${args[$a]} == "-R" ]]; then
        commands+=("reset_pkgs")
    elif [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-s" ]]; then
        only_stable=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    else
        check_mode "${args[$a]}"
        debug "have modes '${modes[*]}'"
    fi
done


if [[ ${#commands[@]} -eq 0 && ${#modes[@]} -eq 0 ]]; then
    echo
    error "A build mode or command must be selected!"
    usage
fi


# Check for internet (thanks Comcast!)
# Please thank Comcast for this requirement...
if ! check_internet; then
    error "Could not reach google dns server! (No internet?)"
    exit 155
fi


msg "$(date) :: ${script_name} started..."

if have_command "update_sums"; then
    # Only the files in the zfs-utils package will be updated
    run_cmd_show_and_capture_output "sha256sum ${script_dir}/src/zfs-utils/zfs-utils.initcpio.hook"
    azsha2=$(echo ${run_cmd_output} | awk '{ print $1 }')
    run_cmd_no_output "sed -e 's/^zfs_initcpio_hook_hash.*/zfs_initcpio_hook_hash=\"${azsha2}\"/g' -i ${script_dir}/conf.sh"

    run_cmd_show_and_capture_output "sha256sum ${script_dir}/src/zfs-utils/zfs-utils.initcpio.install"
    azsha3=$(echo ${run_cmd_output} | awk '{ print $1 }')
    run_cmd_no_output "sed -e 's/^zfs_initcpio_install_hash.*/zfs_initcpio_install_hash=\"${azsha3}\"/g' -i ${script_dir}/conf.sh"

    run_cmd_show_and_capture_output "sha256sum ${script_dir}/src/zfs-utils/zfs-utils.initcpio.zfsencryptssh.install"
    azsha3=$(echo ${run_cmd_output} | awk '{ print $1 }')
    run_cmd_no_output "sed -e 's/^zfs_initcpio_zfsencryptssh_install.*/zfs_initcpio_zfsencryptssh_install=\"${azsha3}\"/g' -i ${script_dir}/conf.sh"

    source_safe "${script_dir}/conf.sh"
fi


if have_command "update_chroot"; then
    msg "Updating the x86_64 clean chroot..."
    run_cmd "ccm64 u"
fi

for (( i = 0; i < ${#modes[@]}; i++ )); do
    mode=${modes[i]}
    kernel_name=${kernel_names[i]}

    get_kernel_update_funcs
    debug_print_default_vars

    export script_dir mode kernel_name
    source_safe "src/kernels/${kernel_name}.sh"


    if have_command "cleanup"; then
        cleanup
        # exit
    fi


    if have_command "reset_pkgs"; then
        msg "Performing git reset for packages/${kernel_name}/*"
            msg "${update_funcs[@]}"
        for func in "${update_funcs[@]}"; do
            debug "Evaluating '${func}'"
            reset_variables
            "${func}"
            msg "${pkg_list[@]}"
            for pkg in "${pkg_list[@]}"; do
                run_cmd "cd '${script_dir}/packages/${kernel_name}/${pkg}' && git reset --hard HEAD"
            done
        done
    fi


    for func in "${update_funcs[@]}"; do
        debug "Evaluating '${func}'"

        # skip git packages if -s was used
        if [[ ${only_stable} -eq 1 && ( ${func} =~ git_pkgbuilds$ || ${func} =~ rc_pkgbuilds$ ) ]]; then
            debug "Skipping '${func}' (non stable)"
            continue
        fi
        reset_variables
        "${func}"
        if have_command "update"; then
            msg "Updating PKGBUILDs for kernel '${kernel_name}'"
            generate_package_files
        fi
        if have_command "make"; then
            build_packages
            build_sources
        fi
        if have_command "sources"; then
            build_sources
        fi
    done
done
