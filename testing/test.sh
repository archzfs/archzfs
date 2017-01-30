#!/bin/bash


args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${script_dir}/../lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/../conf.sh"


ssh_cmd="/usr/sbin/ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=3 -p 2222"
ssh_pass="sshpass -p azfstest"
ssh="${ssh_pass} ${ssh_cmd}"
test_pkg_workdir="archzfs"


export packer_work_dir="${script_dir}/files/packer_work"
export base_image_output_dir="${script_dir}/files"


# Build the archiso with linux-lts if needed
archiso_build() {
    msg "Building the archiso if required"
    local build_archiso=0
    # Check the linux-lts version last used in the archiso
    run_cmd_no_output "cat ${script_dir}/../archiso/work/iso/arch/pkglist.x86_64.txt 2> /dev/null | grep linux-lts | grep -oP '(?<=core/linux-lts-).*$'"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        build_archiso=1
    elif [[ ! -f "$(find ${packer_work_dir} -maxdepth 1 -name 'archlinux*.iso' -print -quit)" ]]; then
        msg2 "archzfs archiso does not exist!"
        build_archiso=1
    else
        current_archiso_lts_vers="${run_cmd_output}"
        debug "current_archiso_lts_vers: ${current_archiso_lts_vers}"
        if ! check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "${current_archiso_lts_vers}"; then
            debug "Setting build_archiso to 1"
            build_archiso=1
        fi
    fi

    if [[ ${build_archiso} -eq 0 ]]; then
        msg2 "archiso is up-to-date!"
        return
    fi

    # Ensure no mounts exist in archiso output directories, exit if mounts are detected
    run_cmd "mount | grep airootfs"
    if [[ ${run_cmd_return} -eq 0 ]]; then
        error "airootfs bind mounds detected! Please unmount before continuing!"
        exit 1
    fi

    # Delete the working directories since we are out-of-date
    run_cmd_no_output "rm -rf ${script_dir}/../archiso/out ${script_dir}/../archiso/work ${packer_work_dir}/*.iso"

    source_safe "${test_mode}/conf.sh" && source_safe "${test_mode}/archiso.sh" && test_build_archiso
}


archiso_init_vars() {
    export archiso_iso_name=$(find ${packer_work_dir}/ -iname "archlinux*.iso" | xargs basename 2> /dev/null )
    export archiso_sha=$(sha1sum ${packer_work_dir}/${archiso_iso_name} 2> /dev/null | awk '{ print $1 }')
    export archiso_url="${packer_work_dir}/${archiso_iso_name}"
    debug "archiso_iso_name=${archiso_iso_name}"
    debug "archiso_sha=${archiso_sha}"
    debug "archiso_url=${archiso_url}"
}


base_image_name() {
    export base_image_basename="$(basename ${test_mode})-archiso-${archiso_iso_name:10:-4}"
    debug "base_image_basename=${base_image_basename}"
    run_cmd_output=$(find ${script_dir} -iname "*$(basename ${test_mode})-*" -printf "%P\\n" | sort -r | head -n 1)
    if [[ ${run_cmd_output} == "" ]]; then
        export base_image_name="${base_image_basename}-build-$(date +%Y.%m.%d).qcow2"
    else
        export base_image_name="${run_cmd_output}"
    fi
    export base_image_path="${script_dir}/${base_image_name}"
    export work_image_randname="${base_image_name%.qcow2}_${RANDOM}.qcow2"
}


usage() {
    echo "${script_name} - A test script for archzfs"
    echo
    echo "Usage: ${script_name} [options] [mode] [command [command option] [...]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    # echo "    -R:    Re-use existing archzfs test packages."
    # echo
    # echo "Modes:"
    # echo
    # for ml in "${mode_list[@]}"; do
        # mn=$(echo ${ml} | cut -f2 -d:)
        # md=$(echo ${ml} | cut -f3 -d:)
        # echo -e "    ${mn}    ${md}"
    # done
    echo
    echo "Commands:"
    echo
    for ml in "${test_commands_list[@]}"; do
        mn=$(basename ${ml})
        echo -e "    ${mn#archzfs-qemu-}"
    done
    exit 155
}


generate_test_commands_list
debug_print_array "test_commands_list" "${test_commands_list[@]}"


# generate_mode_list "${script_dir}/../src/kernels"


for (( a = 0; a < $#; a++ )); do
    # if [[ ${args[$a]} == "-R" ]]; then
        # commands+=("reuse")
    if [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    else
        check_test_mode "${args[$a]}"
        debug "have mode '${mode}'"
        debug "have test mode '${test_mode}'"
    fi
done


if [[ $# -lt 1 ]]; then
    usage
fi


if [[ ${test_mode} == "" ]]; then
    echo
    error "A test command must be selected!"
    usage
fi


# Check for internet (thanks Comcast!)
if ! check_internet; then
    error "Could not reach google dns server! (No internet?)"
    exit 155
fi


if [[ ${EUID} -ne 0 ]]; then
    error "This script must be run as root."
    exit 155;
fi


if [[ "${test_mode}" != "" ]]; then

    msg "Building arch base image"

    if [[ ! -d "${packer_work_dir}" ]]; then
        run_cmd "mkdir -p ${packer_work_dir}"
    fi

    if [[ -d "${packer_work_dir}/output-qemu" ]]; then
        msg2 "Deleting '${packer_work_dir}/output-qemu' because it should not exist"
        run_cmd "rm -rf ${packer_work_dir}/output-qemu"
    fi

    if [[ ! -d "${packer_work_dir}" ]]; then
        msg2 "Creating '${packer_work_dir}' because it does not exist"
        run_cmd "mkdir ${packer_work_dir}"
    fi

    # Clear out everything except packer_cache and the archiso
    run_cmd "find ${packer_work_dir} -mindepth 1 ! -iname 'mirrorlist' ! -iname 'archlinux*.iso' ! -iname 'packer_cache' -exec rm -rf {} \;"

    if [[ ! -f "${packer_work_dir}/mirrorlist" ]]; then
        msg2 "Generating pacman mirrorlist"
        run_cmd "/usr/bin/reflector -c US -l 5 -f 5 --sort rate 2>&1 > ${packer_work_dir}/mirrorlist"
    fi

    msg2 "Using packer to build the base image ..."

    # Base files
    run_cmd "check_symlink '${script_dir}/tests/archzfs-qemu-base/packages' '${packer_work_dir}/packages'"
    run_cmd "check_symlink '${script_dir}/tests/archzfs-qemu-base/packer.json' '${packer_work_dir}/packer.json'"
    run_cmd "check_symlink '${script_dir}/tests/archzfs-qemu-base/setup.sh' '${packer_work_dir}/setup.sh'"
    run_cmd "check_symlink '${script_dir}/../lib.sh' '${packer_work_dir}/lib.sh'"
    run_cmd "check_symlink '${script_dir}/../conf.sh' '${packer_work_dir}/archzfs-conf.sh'"
    run_cmd "check_symlink '${script_dir}/files/poweroff.timer' '${packer_work_dir}/poweroff.timer'"

    # Test files
    run_cmd "check_symlink '${test_mode}/archiso.sh' '${packer_work_dir}/test-archiso.sh'"
    run_cmd "check_symlink '${test_mode}/boot.sh' '${packer_work_dir}/test-boot.sh'"
    run_cmd "check_symlink '${test_mode}/chroot.sh' '${packer_work_dir}/test-chroot.sh'"
    run_cmd "check_symlink '${test_mode}/conf.sh' '${packer_work_dir}/test-conf.sh'"
    run_cmd "check_symlink '${test_mode}/fs.sh' '${packer_work_dir}/test-fs.sh'"
    run_cmd "check_symlink '${test_mode}/hooks.sh' '${packer_work_dir}/test-hooks.sh'"
    run_cmd "check_symlink '${test_mode}/pacman.sh' '${packer_work_dir}/test-pacman.sh'"
    run_cmd "check_symlink '${test_mode}/config.sh' '${packer_work_dir}/test-config.sh'"
    run_cmd "check_symlink '${test_mode}/syslinux.cfg' '${packer_work_dir}/syslinux.cfg'"

    # Make it easy to get the files into the archiso environment
    run_cmd "tar --exclude='*.iso' --exclude=packer_cache --exclude=b.tar -C ${packer_work_dir} -cvhf ${packer_work_dir}/b.tar ."

    archiso_build
    archiso_init_vars
    base_image_name

    # Uncomment to enable packer debug
    export PACKER_LOG=1
    export PACKER_CACHE_DIR="${packer_work_dir}/packer_cache"

    # run_cmd "cd ${packer_work_dir} && packer-io build -debug packer.json"
    run_cmd "cd ${packer_work_dir} && packer-io build packer.json"

    # msg "Moving the compiled base image"
    # run_cmd "mv -f ${base_image_output_dir}/output-qemu/packer-qemu ${base_image_path}"
fi


# if have_command "test";  then
    # msg "Testing package target '${mode}'"

    # if ! have_command "reuse"; then
        # msg2 "Building test packages"
        # build_test_packages
    # fi

    # msg2 "Copying test packages"
    # copy_latest_packages

    # msg2 "Cloning ${base_image_path}"
    # run_cmd "cp ${base_image_path} ${work_image_randname}"

    # msg "Booting VM clone..."
    # cmd="qemu-system-x86_64 -enable-kvm "
    # cmd+="-m 4096 -smp 2 -redir tcp:2222::22 -drive "
    # cmd+="file=${work_image_randname},if=virtio"
    # run_cmd "${cmd}" &

    # if [[ -z "${debug_flag}" ]]; then
        # msg "Waiting for SSH..."
        # while :; do
            # run_cmd "${ssh} root@localhost echo &> /dev/null"
            # if [[ ${run_cmd_return} -eq 0 ]]; then
                # break
            # fi
        # done
    # fi

    # msg2 "Copying the latest packages to the VM"
    # copy_latest_packages
    # run_cmd "rsync -vrthP -e '${ssh}' archzfs/x64/ root@localhost:"
    # run_cmd "${ssh} root@localhost pacman -U --noconfirm '*.pkg.tar.xz'"

    # # msg2 "Cloning ZFS test suite"
    # # run_cmd "${ssh} root@localhost git clone https://github.com/zfsonlinux/zfs-test.git /usr/src/zfs-test"
    # # run_cmd "${ssh} root@localhost chown -R zfs-tests: /usr/src/zfs-test/"

    # # msg2 "Building ZFS test suite"
    # # run_cmd "${ssh} root@localhost 'cd /usr/src/zfs-test && ./autogen.sh && ./configure'"
    # # run_cmd "${ssh} root@localhost 'cd /usr/src/zfs-test && ./autogen.sh && ./configure && make test'"

    # # msg2 "Cause I'm housin"
    # # run_cmd "${ssh} root@localhost systemctl poweroff &> /dev/null"

    # # wait
# fi
