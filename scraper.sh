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


check_webpage_retval=0
has_error=0


check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"
    debug "Expecting: $3"

    run_cmd_no_output "curl -sL ${1}"

    if [[ ${dry_run} -eq 1 ]]; then
        return
    fi

    if [[ $(echo ${run_cmd_output} | \grep -q "504 Gateway Timeout"; echo $?) -eq 0 ]]; then
        check_webpage_retval=-1
        return
    elif [[ $(echo ${run_cmd_output} | \grep -q "503 Service Unavailable"; echo $?) -eq 0 ]]; then
        check_webpage_retval=-1
        return
    elif [[ ${run_cmd_output} == "RETVAL: 7" ]]; then
        check_webpage_retval=-1
        return
    fi

    local scraped_string=$(echo "${run_cmd_output}" | \grep -Po -m 1 "${2}")
    debug "Got \"${scraped_string}\" from webpage."

    if [[ ${scraped_string} != "$3" ]]; then
        error "Checking '$1' expected '$3' got '${scraped_string}'"
        debug "Returning 1 from check_webpage()"
        check_webpage_retval=1
        return
    fi

    check_webpage_retval=0
    return
}


check_result() {
    # $1 current line
    # $2 changed line
    if [[ ${check_webpage_retval} -eq 0 ]]; then
        msg2 "The $1 version is current."
    elif [[ ${check_webpage_retval} -eq 1 ]]; then
        error "The $2 is out-of-date!"
        has_error=1
    elif [[ ${check_webpage_retval} -eq -1 ]]; then
        warning "The $2 package page was unreachable!"
    else
        error "Check returned ${check_webpage_retval}"
        has_error=1
    fi
}


# Bail if no internet
# Please thank Comcast for this requirement...
if [[ $(ping -w 1 -c 1 8.8.8.8 &> /dev/null; echo $?) != 0 ]]; then
    exit 0;
fi


check_archiso() {
    #
    # Check archiso kernel version (this will change when the archiso is updated)
    #
    msg "Checking archiso download page for linux kernel version changes..."
    check_webpage "https://www.archlinux.org/download/" "(?<=Included Kernel:</strong> )[\d\.]+" \
        "${ARCHISO_KERNEL_VERSION}"
    check_result "archiso kernel version" "archiso"
}


check_linux_kernel() {
    #
    # Check x86_64 linux kernel version
    #
    msg "Checking the online package database for x86_64 linux kernel version changes..."
    check_webpage "https://www.archlinux.org/packages/core/x86_64/linux/" "(?<=<h2>linux )[\d\.-]+(?=</h2>)" \
        "${STD_KERNEL_VERSION}"
    check_result "x86_64 linux kernel package" "linux x86_64"
}


check_linux_lts_kernel() {
    #
    # Check x86_64 linux-lts kernel version
    #
    msg "Checking the online package database for x86_64 linux-lts kernel version changes..."
    check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" \
        "${LTS_KERNEL_VERSION}"
    check_result "x86_64 linux-lts kernel package" "linux-lts x86_64"
}


check_zol_version() {
    #
    # Check ZFSonLinux.org
    #
    msg "Checking zfsonlinux.org for new versions..."
    check_webpage "http://zfsonlinux.org/" "(?<=downloads/zfsonlinux/spl/spl-)[\d\.]+(?=.tar.gz)" "${zol_version}"
    check_result "ZOL stable version" "ZOL stable version"
}


check_archiso
check_linux_kernel
check_linux_lts_kernel
check_zol_version


#
# This is the end
# Beautiful friend
# This is the end
# My only friend, the end
#
if [[ ${has_error} -eq 1 ]]; then
    exit 1;
fi
