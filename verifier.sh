#!/bin/bash


#
# Makes sure the local archzfs repo matches what is live on archzfs.com
#


args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/conf.sh"


usage() {
    echo "${script_name} - Compares repository hashes."
    echo
    echo "Usage: ${script_name} [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -d:    Show debug info."
    echo
    echo "Examples:"
    echo
    echo "    ${script_name} -d    :: Show debug output."
    exit 155
}


for (( a = 0; a < $#; a++ )); do
    if [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    fi
done


compute_local_repo_hash() {
    # $1: The repository to compute
    # Sets local_repo_hash
    msg2 "Computing local $1 repository hashes..."
    run_cmd_show_and_capture_output "cd ${repo_basepath}; sha256sum $1/*/*"
    if [[ ${run_cmd_return} != 0 ]]; then
        error "Could not run local hash!"
        exit 1
    fi
    lfiles=$(echo ${run_cmd_output} | sort -r)
    local_repo_hash=$(echo "${lfiles}" | sha256sum | cut -f 1 -d' ')
    msg2 "Local hash: ${local_repo_hash}"
}


compute_remote_repo_hash() {
    # $1: The repository to compute
    # Sets remote_repo_hash
    msg2 "Computing remote $1 repository hashes..."
    run_cmd_show_and_capture_output "ssh ${remote_login} 'cd webapps/default; sha256sum $1/*/*'"
    if [[ ${run_cmd_return} != 0 ]]; then
        error "Could not run remote hash!"
        exit 1
    fi
    rfiles=$(echo ${run_cmd_output} | sort -r)
    remote_repo_hash=$(echo "${rfiles}" | sha256sum | cut -f 1 -d' ')
    msg2 "Remote hash: $remote_repo_hash"
}


msg "$(date) :: ${script_name} started..."


# Bail if no internet
# Please thank Comcast for this requirement...
if [[ $(ping -w 1 -c 1 8.8.8.8 &> /dev/null; echo $?) != 0 ]]; then
    exit 0;
fi


has_error=0
local_repo_hash=""
remote_repo_hash=""


for repo in 'archzfs'; do
    msg "Checking ${repo}..."
    # compare_repo $repo
    compute_local_repo_hash ${repo}
    compute_remote_repo_hash ${repo}
    if [[ ${local_repo_hash} != ${remote_repo_hash} ]]; then
        error "The ${repo} is out of sync!"
        has_error=1
        continue
    fi
    msg2 "${repo} is in sync"
done


if [[ ${has_error} -eq 1 ]]; then
    exit 1
fi
