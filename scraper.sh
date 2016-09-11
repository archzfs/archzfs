#!/bin/bash


#
# A script for scraping data from the web. When ran in cron with a correct email address configured, an alert email will be
# sent notifying the user that either the "linux" kernel package version has changed, a new ZFSonLinux version has been
# released, or a new archiso has been released.
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
    echo "${script_name} - A cheap webpage scraper."
    echo
    echo "Usage: ${script_name} [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dry run."
    echo "    -d:    Show debug info."
    echo
    echo "Examples:"
    echo
    echo "    ${script_name} -d     :: Show debug output."
    echo "    ${script_name} -n     :: Don't run commands, but show output."
    exit 155
}


# Check for internet (thanks Comcast!)
if ! check_internet; then
    error "Could not reach google dns server! (No internet?)"
    exit 155
fi


for (( a = 0; a < $#; a++ )); do
    if [[ ${args[$a]} == "-n" ]]; then
        dry_run=1
    elif [[ ${args[$a]} == "-d" ]]; then
        debug_flag=1
    elif [[ ${args[$a]} == "-h" ]]; then
        usage
    fi
done


msg "$(date) :: ${script_name} started..."


haz_error=0


# Bail if no internet
# Please thank Comcast for this requirement...
if ! check_internet; then
    exit 1
fi


get_kernel_update_funcs
debug_print_default_vars


export script_dir mode kernel_name
source_safe "${script_dir}/src/kernels/linux.sh"
check_linux_kernel
# check_archiso


source_safe "${script_dir}/src/kernels/linux-lts.sh"
check_linux_lts_kernel


check_zol_version


#
# This is the end
# Beautiful friend
# This is the end
# My only friend, the end
#
if [[ ${haz_error} -eq 1 ]]; then
    exit 1;
fi
