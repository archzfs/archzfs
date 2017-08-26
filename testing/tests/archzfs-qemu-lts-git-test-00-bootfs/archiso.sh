# We need an archiso with the lts kernel used by default
test_build_archiso() {
    msg "Building archiso"
    cd ${test_root_dir}/../../../archiso/ &> /dev/null
    if [[ -d ${packer_work_dir}/out ]] && [[ $(ls -1 | wc -l) -gt 0 ]]; then
        run_cmd "rm -rf ${test_root_dir}/archiso/out/archlinux*"
    fi
    run_cmd "./build.sh -v"
    msg2 "Copying archiso to packer_work_dir"
    run_cmd "cp ${test_root_dir}/../../../archiso/out/archlinux* ${packer_work_dir} && rm -rf ${test_root_dir}/archiso/work"
    cd - &> /dev/null
}
