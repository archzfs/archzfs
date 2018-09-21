#!/bin/bash


#
# repo.sh adds the archzfs packages to the archzfs repository or archzfs-testing repository
#


args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
repo_name="" # The destination repo for the packages
package_list=() # A list of packages to add. Array items are in the form of "name;pkg.tar.xz;repo_path".
package_src_list=() # A list of package sources to move
package_exist_list=()
all_added_pkgs=() # A list of all packages, that were added to the repo
haz_error=0


if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/conf.sh"


usage() {
    echo "${script_name} - Adds the compiled packages to the archzfs repo."
    echo
    echo "Usage: ${script_name} [options] (mode) (repo)"
    echo
    echo "Options:"
    echo
    echo "    -h:           Show help information."
    echo "    -n:           Dryrun; Output commands, but don't do anything."
    echo "    -d:           Show debug info."
    echo "    -s:           Sign packages only."
    echo "    -p:           Do not sync from remote repo."
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
    echo "Repository target:"
    echo
    echo "    azfs          Use the archzfs repo. Used by default."
    echo "    test          Use the archzfs-testing repo."
    echo "    ccm           Install packages to the clean-chroot-manager's repo. Useful incase the chroot neeeds to be nuked."
    echo "    repo=<repo>   Install packages to a custom repo."
    echo
    echo "Example Usage:"
    echo
    echo "    ${script_name} lts azfs -n -d             :: Show output commands and debug info."
    exit 155
}


generate_mode_list


if [[ $# -lt 1 ]]; then
    usage
fi


for (( a = 0; a < $#; a++ )); do
    if [[ ${args[$a]} == "azfs" ]]; then
        repo_name=${repo_basename}
        pull_remote_repo=1
    elif [[ ${args[$a]} == "test" ]]; then
        repo_name="${repo_basename}-testing"
        pull_remote_testing_repo=1
    elif [[ ${args[$a]} =~ repo=(.*) ]]; then
        repo_name=${BASH_REMATCH[1]}
    elif [[ ${args[$a]} == "ccm" ]]; then
        repo_name="clean-chroot-manager"
    elif [[ ${args[$a]} == "-s" ]]; then
        sign_packages=1
    elif [[ ${args[$a]} == "-p" ]]; then
        no_pull_remote=1
    elif [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    else
        check_mode "${args[$a]}"
        debug "have modes '${modes[*]}'"
    fi
done

package_backup_dir="${repo_basepath}/archive_${repo_name}"


if [[ $# -lt 1 ]]; then
    usage
fi


if [[ ${#modes[@]} -eq 0 ]]; then
    echo
    error "A mode must be selected!"
    usage
fi


if [[ ${repo_name} == "" ]]; then
    error "No destination repo specified!"
    exit 155
fi

pull_repo() {
    msg "Downloading remote repo..."
    if [[ ${dry_run} -eq 1 ]]; then
        dry="-n"
    fi
    run_cmd "rsync -vrtlh --delete-before ${remote_login}:${repo_remote_basepath}/${repo_name} ${remote_login}:${repo_remote_basepath}/archive_${repo_basename} ${repo_basepath}/ ${dry}"
    run_cmd_check 1 "Could not pull packages from remote repo!"
}

pull_testing_repo() {
    msg "Downloading remote testing repo..."
    if [[ ${dry_run} -eq 1 ]]; then
        dry="-n"
    fi
    run_cmd "rsync -vrtlh --delete-before ${remote_login}:${repo_remote_basepath}/${repo_basename}-testing ${remote_login}:${repo_remote_basepath}/archive_${repo_basename}-testing ${repo_basepath}/ ${dry}"
    run_cmd_check 1 "Could not pull packages from remote testing repo!"
}

repo_package_list() {
    msg "Generating a list of packages to add..."
    debug_print_array "pkg_list" "${pkg_list[@]}"

    package_list=()
    local pkgs=()
    if [[ ${#pkg_list[@]} -eq 1 ]]; then
        local pkg_list_find=${pkg_list[0]}
    else
        local pkg_list_find="{$(printf '%s,' ${pkg_list[@]} | cut -d ',' -f 1-${#pkg_list[@]})}"
    fi

    # Get packages from the backup directory
    path="packages/${kernel_name}/${pkg_list_find}/"
    if [[ ! -z ${kernel_version_full_pkgver} ]]; then
        debug "kernel_version_full_pkgver: ${kernel_version_full_pkgver}"
        fcmd="find ${path} -iname '*${kernel_version_full_pkgver}-${zfs_pkgrel}*.pkg.tar.xz' "
        run_cmd_no_output_no_dry_run "${fcmd}"
        for pkg in ${run_cmd_output}; do
            pkgs+=(${pkg})
        done
    elif [[ ! -z ${zfs_pkgver} ]]; then
        debug "zfs_pkgver: ${zfs_pkgver}"
        fcmd="find ${path} -iname '*${zfs_pkgver}-${zfs_pkgrel}*.pkg.tar.xz' "
        run_cmd_no_output_no_dry_run "${fcmd}"
        for pkg in ${run_cmd_output}; do
            pkgs+=(${pkg})
        done
    else
        debug "kernel_version_full_pkgver and zfs_pkgver not set!"
        debug "Falling back to newest package by mod time for zfs"
        for z in $(printf '%s ' ${pkg_list[@]} ); do
            # fcmd="find ${path} -iname '*${kernel_name}*-${spl_pkgrel}*.pkg.tar.xz' -o -iname '*${zfs_pkgver}-${zfs_pkgrel}*.pkg.tar.xz' "
            fcmd="find packages/${kernel_name} -iname '*${z}*.pkg.tar.xz' -printf '%T@ %p\\n' | sort -n | tail -1 | cut -f2- -d' '"
            run_cmd_no_output_no_dry_run "${fcmd}"
            for pkg in ${run_cmd_output}; do
                pkgs+=(${pkg})
            done
        done
    fi

    debug_print_array "pkgs" ${pkgs[@]}

    for pkg in ${pkgs[@]}; do
        arch=$(package_arch_from_path ${pkg})
        name=$(package_name_from_path ${pkg})
        vers=$(package_version_from_path ${pkg})


        if ! [[ ${name} =~ .*-git ]]; then
            # Version match check: arch: x86_64 name: spl-utils-linux-git vers: 0.7.0_rc1_r0_g4fd75d3_4.7.2_1-4 vers_match: 0.6.5.8.*4.7.2_1-4
            debug "zfs_pkgver: ${zfs_pkgver}"
            debug "kernel_version_full_pkgver: ${kernel_version_full_pkgver}"

            kernvers=""
            # append kernel version if set
            if [ ! -z "${kernel_version_full_pkgver}" ]; then
              kernvers="_${kernel_version_full_pkgver}";
            fi
            match="${zfs_pkgver}${kernvers}-${zfs_pkgrel}"

            debug "Version match check: arch: ${arch} name: ${name} vers: ${vers} vers_match: ${match}"

            if ! [[ ${vers} =~ ^${match} ]] ; then
                debug "Version mismatch!"
                continue
            fi
        fi

        # check if package version is already in repo
        if [ -f "${repo_target}/${arch}/${name}-${vers}-${arch}.pkg.tar.xz" ]; then
            msg2 "Package ${name}=${vers} already in repo. Skipping"
            continue
        fi

        debug "Using: pkgname: ${name} pkgver: ${vers} pkgpath: ${pkg} pkgdest: ${repo_target}/${arch}"
        if [[ ${repo_name} == "chroot_local" ]]; then
            package_list+=("${name};${vers};${pkg};${repo_target}")
        else
            package_list+=("${name};${vers};${pkg};${repo_target}/${arch}")
        fi

        pkgsrc="packages/${kernel_name}/${name}/${name}-${vers}.src.tar.gz"
        if [[ -f  "${pkgsrc}" ]]; then
            package_src_list+=("${pkgsrc}")
        fi
    done

    debug_print_array "package_list" ${package_list[@]}
    debug_print_array "package_src_list" ${package_src_list[@]}
}


repo_package_backup() {
    msg "Getting a list of packages to backup..."

    local pkgs=()
    for ipkg in ${package_list[@]}; do
        IFS=';' read -a pkgopt <<< "${ipkg}"

        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pkgp="${pkgopt[2]}"
        dest="${pkgopt[3]}"

        debug "pkg: ${name}"
        local o=""
        if [[ ${#pkgs[@]} -ne 0 ]]; then
            local o="-o"
        fi

        pkgs+=("$o -regextype egrep -regex '.*${name}-[a-z0-9\.\_]+-[0-9]+-x86_64.pkg.tar.xz'")
    done

    # backup old spl packages
    local o=""
    if [[ ${#pkgs[@]} -ne 0 ]]; then
        local o="-o"
    fi

    pkgs+=("$o -regextype egrep -regex '.*spl-[a-z\-]+-[a-z0-9\.\_]+-[0-9]+-x86_64.pkg.tar.xz'")

    # only run find, if new packages will be copied
    if [[ ! ${#pkgs[@]} -eq 0 ]]; then
        run_cmd_show_and_capture_output_no_dry_run "find ${repo_target} -type f ${pkgs[@]}"

        for x in ${run_cmd_output}; do
            debug "Evaluating ${x}"
            pkgname=$(package_name_from_path ${x})
            pkgvers=$(package_version_from_path ${x})
            debug "pkgname: ${pkgname}"
            debug "pkgvers: ${pkgvers}"
            # asterisk globs the package signature
            epkg="${repo_target}/x86_64/${pkgname}-${pkgvers}*"
            debug "backing up package: ${epkg}"
            package_exist_list+=("${epkg}")
        done
    fi

    if [[ ${#package_exist_list[@]} -eq 0 ]]; then
        msg2 "No packages found for backup."
        return
    fi

    debug_print_array "package_exist_list" "${package_exist_list[@]}"
    msg "Backing up existing packages..."
    run_cmd "mv ${package_exist_list[@]} ${package_backup_dir}/"
}


repo_add() {
    if [[ ${#package_list[@]} == 0 ]]; then
        error "No packages to process!"
        return
    fi

    debug_print_array "package_list" ${#package_list}
    local pkg_cp_list=()
    local pkg_add_list=()
    local dest=""
    local arch="x86_64"

    for ipkg in ${package_list[@]}; do
        IFS=';' read -a pkgopt <<< "${ipkg}"

        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pkgp="${pkgopt[2]}"
        dest="${pkgopt[3]}"

        msg2 "Processing package ${name}-${vers} to ${dest}"
        [[ ! -d ${dest} ]] && run_cmd "mkdir -p ${dest}"

        debug "name: ${name} vers: ${vers} pkgp: ${pkgp} dest: ${dest}"

        pkg_cp_list+=("${pkgp}")
        pkg_cp_list+=("${pkgp}.sig")

        bname=$(basename ${pkgp})
        pkg_add_list+=("${dest}/${bname}")
        all_added_pkgs+=("${bname}")
    done

    debug_print_array "pkg_cp_list" "${pkg_cp_list[@]}"
    debug_print_array "pkg_add_list" "${pkg_add_list[@]}"

    msg "Copying the new ${arch} packages to the repo..."


    if [[ ${repo_name} == "chroot_local" ]]; then
        run_cmd "cp -fv ${pkg_cp_list[@]} ${package_src_list[@]} ${repo_target}/"
    else
        run_cmd "cp -fv ${pkg_cp_list[@]} ${package_src_list[@]} ${repo_target}/${arch}/"
    fi
    if [[ ${run_cmd_return} -ne 0 ]]; then
        error "An error occurred copying the packages to the repo!"
        exit 1
    fi

    if [[ ${repo_name} == "chroot_local" ]]; then
        run_cmd "repo-add ${repo_target}/${repo_name}.db.tar.gz ${pkg_add_list[@]}"
        # append the local repo to the chroot's pacman.conf
        repo_root=$(dirname ${repo_target})
        if [[ -z $(grep clean-chroot ${repo_root}/etc/pacman.conf) ]]; then
            # add a local repo to chroot
            run_cmd_no_output "sed -i '/\\\[testing\\\]/i # Added by clean-chroot-manager\\\n\\\[chroot_local\\\]\\\nSigLevel = Never\\\nServer = file:///repo\\\n' ${repo_root}/etc/pacman.conf $(realpath ${repo_root}/../)/${makepkg_nonpriv_user}/etc/pacman.conf"
        fi
        run_cmd_no_output "sudo rsync --chown=${makepkg_nonpriv_user}: -ax ${repo_root}/repo/ $(realpath ${repo_root}/../)/${makepkg_nonpriv_user}/repo/"
    else
        # remove old spl packages
        run_cmd "repo-remove -k ${gpg_sign_key} -s -v ${repo_target}/${arch}/${repo_name}.db.tar.xz spl-utils-common-git spl-linux-git spl-linux-git-headers spl-linux-lts-git spl-linux-lts-git-headers spl-linux-hardened-git spl-linux-hardened-git-headers spl-linux-zen-git spl-linux-zen-git-headers spl-linux-vfio-git spl-linux-vfio-git-headers spl-dkms-git spl-utils-common spl-linux spl-linux-headers spl-linux-lts spl-linux-lts-headers spl-linux-hardened spl-linux-hardened-headers spl-linux-zen spl-linux-zen-headers spl-linux-vfio spl-linux-vfio-headers spl-dkms"

        run_cmd "repo-add -k ${gpg_sign_key} -s -v ${repo_target}/${arch}/${repo_name}.db.tar.xz ${pkg_add_list[@]}"
    fi

    if [[ ${run_cmd_return} -ne 0 ]]; then
        error "An error occurred adding the package to the repo!"
        exit 1
    fi

}

sign_packages() {
    if [[ ${#package_list[@]} == 0 ]]; then
        error "No packages to process!"
        return
    fi

    for ipkg in "${package_list[@]}"; do
        IFS=';' read -a pkgopt <<< "${ipkg}"
        name="${pkgopt[0]}"
        vers="${pkgopt[1]}"
        pkgp="${pkgopt[2]}"
        dest="${pkgopt[3]}"

        if [[ ! -f "${pkgp}.sig" ]]; then
            msg2 "Signing ${pkgp}"
            # GPG_TTY prevents "gpg: signing failed: Inappropriate ioctl for device"
            if [[ "$(tty)" == "not a tty" ]]; then
                tty=""
            else
                tty="GPG_TTY=$(tty) "
            fi
            run_cmd_no_output "${tty}gpg --batch --yes --detach-sign --use-agent -u ${gpg_sign_key} \"${script_dir}/${pkgp}\""
            if [[ ${run_cmd_return} -ne 0 ]]; then
                exit 1
            fi
        fi
    done
}


msg "$(date) :: ${script_name} started..."


# The abs path to the repo
if [[ ${repo_name} == "clean-chroot-manager" ]]; then
    repo_name="chroot_local"
    repo_target="$(dirname ${chroot_path})/root/repo"
    if [[ ! -d ${repo_target} ]]; then
        # XXX: NEED TO TEST THIS
        run_cmd_no_output_no_dry_run "sudo mkdir -p ${repo_target} && sudo chown ${makepkg_nonpriv_user}: -R ${repo_target}"
    fi
else
    repo_target=${repo_basepath}/${repo_name}
fi


debug "repo_name: ${repo_name}"
debug "repo_target: ${repo_target}"

if [[ ${pull_remote_repo} -eq 1 ]] && [[ ${no_pull_remote} -ne 1 ]]; then
    pull_repo
fi
if [[ ${pull_remote_testing_repo} -eq 1 ]] && [[ ${no_pull_remote} -ne 1 ]]; then
    pull_testing_repo
fi

if [[ ${sign_packages} -eq 1 ]]; then
    for (( i = 0; i < ${#modes[@]}; i++ )); do
        mode=${modes[i]}
        kernel_name=${kernel_names[i]}

        get_kernel_update_funcs
        debug_print_default_vars

        export script_dir mode kernel_name
        source_safe "src/kernels/${kernel_name}.sh"

        export zfs_pkgver=""

        for func in ${update_funcs[@]}; do
            debug "Evaluating '${func}'"
            "${func}"
            repo_package_list
            sign_packages
        done
    done
    exit 0
fi

for (( i = 0; i < ${#modes[@]}; i++ )); do
    mode=${modes[i]}
    kernel_name=${kernel_names[i]}

    get_kernel_update_funcs
    debug_print_default_vars

    export script_dir mode kernel_name
    source_safe "src/kernels/${kernel_name}.sh"

    export zfs_pkgver=""

    for func in ${update_funcs[@]}; do
        debug "Evaluating '${func}'"
        "${func}"
        repo_package_list
        if [[ ${repo_name} != "chroot_local" ]]; then
            repo_package_backup
        fi
        sign_packages
        repo_add
    done
done

if [[ ${#all_added_pkgs[@]} -gt 0 ]]; then
    msg2 "${#all_added_pkgs[@]} packages were added to the repo:"
    printf '%s\n' "${all_added_pkgs[@]}"
else
    msg2 "No packages were added to the repo"
fi

if [[ ${haz_error} -ne 0 ]]; then
    warning "An error has been detected! Inspect output above closely..."
fi
