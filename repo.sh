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
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo
    echo "Modes:"
    echo
    for ml in "${mode_list[@]}"; do
        mn=$(echo ${ml} | cut -f2 -d:)
        md=$(echo ${ml} | cut -f3 -d:)
        echo -e "    ${mn}    ${md}"
    done
    echo
    echo "Repository target:"
    echo
    echo "    azfs      Use the archzfs repo. Used by default."
    echo "    test      Use the archzfs-testing repo."
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
        repo_name="archzfs"
    elif [[ ${args[$a]} == "test" ]]; then
        repo_name="archzfs-testing"
    elif [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    else
        check_mode "${args[$a]}"
        debug "have mode '${mode}'"
    fi
done


if [[ $# -lt 1 ]]; then
    usage
fi


if [[ ${mode} == "" ]]; then
    echo
    error "A mode must be selected!"
    usage
fi


if [[ ${repo_name} == "" ]]; then
    error "No destination repo specified!"
    exit 155
fi


repo_package_list() {
    msg "Generating a list of packages to add..."
    debug_print_array "pkg_list" "${pkg_list[@]}"

    package_list=()
    local pkgs=()

    # Get packages from the backup directory
    path="packages/${kernel_name}/{$(printf '%s,' ${pkg_list[@]} | cut -d ',' -f 1-${#pkg_list[@]})}/"
    run_cmd_show_and_capture_output_no_dry_run "find ${path} -iname '*${kernel_version_full_pkgver}*.pkg.tar.xz'"
    for pkg in ${run_cmd_output}; do
        pkgs+=(${pkg})
    done

    for pkg in ${pkgs[@]}; do
        arch=$(package_arch_from_path ${pkg})
        name=$(package_name_from_path ${pkg})
        vers=$(package_version_from_path ${pkg})


        # Version match check: arch: x86_64 name: spl-utils-linux-git vers: 0.7.0_rc1_r0_g4fd75d3_4.7.2_1-4 vers_match: 0.6.5.8.*4.7.2_1-4
        debug "spl_pkgver: ${spl_pkgver}"
        debug "zfs_pkgver: ${zfs_pkgver}"

        if [[ ${pkg} =~ .*spl-.* ]]; then
            match="${spl_pkgver}-${spl_pkgrel}"
        elif [[ ${pkg} =~ .*zfs-.* ]]; then
            match="${zfs_pkgver}-${zfs_pkgrel}"
        fi
        debug "Version match check: arch: ${arch} name: ${name} vers: ${vers} vers_match: ${match}"

        if ! [[ ${vers} =~ ^${match} ]] ; then
            debug "Version mismatch!"
            if [[ ${name} =~ .*-git ]]; then
                error "Attempting to add Git packages that are out of date!"
                error "package version from filesystem: ${vers}"
                error "calculated version from git: ${match}"
                haz_error=1
                if [[ ${dry_run} -ne 1 ]]; then
                    exit 1
                fi
            fi
            continue
        fi

        debug "Using: pkgname: ${name} pkgver: ${vers} pkgpath: ${pkg} pkgdest: ${repo_target}/${arch}"
        package_list+=("${name};${vers};${pkg};${repo_target}/${arch}")
        package_src_list+=("packages/${kernel_name}/${name}/${name}-${vers}.src.tar.gz")
    done

    debug_print_array "package_list" ${package_list[@]}
}


repo_package_backup() {
    msg "Getting a list of packages to backup..."
    local pkgs=()
    for pkg in ${pkg_list[@]}; do
        local o=""
        if [[ ${#pkgs[@]} -ne 0 ]]; then
            local o="-o"
        fi
        pkgs+=("${o} -iname '*${pkg}-[0-9]*.pkg.tar.xz'")
    done
    run_cmd_show_and_capture_output_no_dry_run "find ${repo_target} -type f ${pkgs[@]}"
    for x in ${run_cmd_output}; do
        ename=$(package_name_from_path ${x})
        evers=$(package_version_from_path ${x})
        debug "repo_package_backup: evers: ${evers}"
        debug "repo_package_backup: kernel_vers: ${kernel_version_full_pkgver}"
        # Ignore current packages if they exist
        if [[ ${evers} == *"${kernel_version_full_pkgver}-${spl_pkgrel}"* ]] || \
            [[ ${evers} == *"${kernel_version_full_pkgver}-${zfs_pkgrel}"* ]]; then
            debug "repo_package_backup: Ignoring package '${x}'"
            continue
        fi
        # asterisk globs the package signature
        epkg="${repo_target}/x86_64/${ename}-${evers}*"
        debug "repo_package_backup epkg: ${epkg}"
        package_exist_list+=("${epkg}")
    done
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
        exit 1
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
    done

    debug_print_array "pkg_cp_list" "${pkg_cp_list[@]}"
    debug_print_array "pkg_add_list" "${pkg_add_list[@]}"

    msg "Copying the new ${arch} packages to the repo..."

    run_cmd "cp -fv ${pkg_cp_list[@]} ${package_src_list[@]} ${repo_target}/${arch}/"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        error "An error occurred copying the packages to the repo!"
        exit 1
    fi

    run_cmd "repo-add -k ${gpg_sign_key} -s -v ${repo_target}/${arch}/${repo_name}.db.tar.xz ${pkg_add_list[@]}"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        error "An error occurred adding the package to the repo!"
        exit 1
    fi
}


msg "$(date) :: ${script_name} started..."


# The abs path to the repo
repo_target=${repo_basepath}/${repo_name}


get_kernel_update_funcs
debug_print_default_vars
debug "repo_name: ${repo_name}"
debug "repo_target: ${repo_target}"


source_safe "src/kernels/${kernel_name}.sh"


export zfs_pkgver=""
export spl_pkgver=""

for func in ${update_funcs[@]}; do
    debug "Evaluating '${func}'"
    if [[ ${func} =~ .*_git_.* ]]; then
        # Update the local zfs/spl git repositories, this will change the calculated pkgver version of the PKGBUILD.
        commands+=("update")
    fi
    "${func}"
    repo_package_list
    repo_package_backup
    repo_add
done

if [[ ${haz_error} -ne 0 ]]; then
    warning "An error has been detected! Inspect output above closely..."
fi
