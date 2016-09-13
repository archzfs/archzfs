#!/bin/bash


#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs.com website
#


args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
push=0
push_repo=0


if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/conf.sh"


usage() {
    echo "${script_name} - Pushes the packages sources to AUR using burp."
    echo
    echo "Usage: ${script_name} [options] [mode]"
    echo
    echo "Options:"
    echo
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo "    -r:       Push the archzfs repositories."
    echo "    -p:       Commit changes and push."
    echo
    echo "Modes:"
    echo
    for ml in "${mode_list[@]}"; do
        mn=$(echo ${ml} | cut -f2 -d:)
        md=$(echo ${ml} | cut -f3 -d:)
        echo -e "    ${mn}    ${md}"
    done
    echo
    echo "Example Usage:"
    echo
    echo "    ${script_name} std     :: Show package changes."
    echo "    ${script_name} std -p  :: Push the default package sources."
    echo "    ${script_name} lts -p  :: Push the lts package sources."
    exit 155
}


generate_mode_list


if [[ $# -lt 1 ]]; then
    usage
fi


for (( a = 0; a < $#; a++ )); do
    if [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-p" ]]; then
        push=1
    elif [[ ${args[$a]} == "-r" ]]; then
        push_repo=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    else
        check_mode "${args[$a]}"
        debug "have mode '${mode}'"
    fi
done


if [[ ${mode} == "" && ${push_repo} -eq 0 ]]; then
    echo
    error "A mode must be selected!"
    usage
fi


msg "$(date) :: ${script_name} started..."


push_packages() {
    for pkg in "${pkg_list[@]}"; do
        msg "Packaging ${pkg}..."
        debug "PWD=${PWD}"
        local cmd="cd \"${script_dir}/packages/${kernel_name}/${pkg}\" && "
        if [[ ${push} -eq 1 ]]; then
            cmd+="git --no-pager diff && echo && echo && git checkout master && git add . && "
            cmd+="git commit -m 'Semi-automated update for $(kernel_version_full_no_hyphen ${kernel_version_full})-${zfs_pkgrel}'; git push"
        else
            cmd+="git --no-pager diff"
        fi
        run_cmd "${cmd}"
    done
}


push_repo() {
    if [[ ${dry_run} -eq 1 ]]; then
        dry="-n"
    elif [[ ${push_repo} -ne 1 ]]; then
        return
    fi
    run_cmd "rsync -vrtlh --delete-before ${repo_basepath}/${repo_name} ${package_backup_dir} webfaction:/home/jalvarez/webapps/default/ ${dry}"
}


push_repo
if [[ ${mode} == "" ]]; then
    exit
fi


get_kernel_update_funcs
debug_print_default_vars


export script_dir mode kernel_name
source_safe "src/kernels/${kernel_name}.sh"

for func in "${update_funcs[@]}"; do
    debug "Evaluating '${func}'"
    "${func}"
    push_packages
done


# Build the documentation and push it to the remote host
# msg "Building the documentation..."
# rst2html2 web_archzfs.rst > /tmp/archzfs_index.html
# msg2 "Pushing the documentation to the remote host..."
# scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
