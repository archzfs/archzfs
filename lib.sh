shopt -s nullglob


unset ALL_OFF BOLD BLUE GREEN RED YELLOW WHITE

# prefer terminal safe colored and bold text when tput is supported
ALL_OFF="$(tput sgr0 2> /dev/null)"
BOLD="$(tput bold 2> /dev/null)"
BLUE="${BOLD}$(tput setaf 4 2> /dev/null)"
GREEN="${BOLD}$(tput setaf 2 2> /dev/null)"
RED="${BOLD}$(tput setaf 1 2> /dev/null)"
YELLOW="${BOLD}$(tput setaf 3 2> /dev/null)"
WHITE="${BOLD}$(tput setaf 7 2> /dev/null)"
readonly ALL_OFF BOLD BLUE GREEN RED YELLOW

plain() {
    local mesg=$1; shift
    printf "${WHITE}     ○ ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n" "$@"
}

msg() {
    local mesg=$1; shift
    printf "${GREEN}==== ${ALL_OFF}${WHITE}${BOLD} ${mesg}${ALL_OFF}\n" "$@"
}

msg2() {
    local mesg=$1; shift
    printf "${BLUE}++++  ${ALL_OFF}${WHITE}${BOLD}${mesg}${ALL_OFF}\n" "$@"
}

warning() {
    local mesg=$1; shift
    printf "${YELLOW}====  WARNING: ${ALL_OFF}${WHITE}${BOLD} ${mesg}${ALL_OFF}\n" "$@"
}

error() {
    local mesg=$1; shift
    printf "${RED}====  ERROR: ${ALL_OFF}${BOLD}${WHITE}${mesg}${ALL_OFF}\n" "$@" >&2
}

send_email() {
    # $1 = Message
    # $2 = Subject
    # $3 = attachment
    if [[ $3 == "" ]]; then
        echo -e "${1}" | mutt -s "${2}" "${AZB_EMAIL}"
    else
        echo -e "${1}" | mutt -s "${2}" "${AZB_EMAIL}" -a "${3}"
    fi
}

debug() {
    # $1: The message to print.
    if [[ $DEBUG -eq 1 ]]; then
        plain "DEBUG: $1"
    fi
}

run_cmd() {
    # $1: The command to run
    if [[ $DRY_RUN -eq 1 ]]; then
        for pos in $@; do
            plain $pos
        done
    else
        plain "Running command: $@"
        eval "$@"
        plain "Command returned: $?"
    fi
}

cleanup() {
    exit $1 || true
}

abort() {
    msg 'Aborting...'
    cleanup 0
}

trap_abort() {
    trap - EXIT INT QUIT TERM HUP
    abort
}

trap_exit() {
    trap - EXIT INT QUIT TERM HUP
    cleanup
}

die() {
    (( $# )) && error "$@"
    cleanup 1
}

package_arch_from_path() {
    # $1: Package path
    pacman -Qip "$1" | grep "Architecture" | cut -d : -f 2 | tr -d ' '
    return $?
}

package_name_from_path() {
    # $1: Package path
    pacman -Qip "$1" | grep "Name" | cut -d : -f 2 | tr -d ' '
    return $?
}

package_version_from_path() {
    # $1: Package path
    pacman -Qip "$1" | grep "Version" | cut -d : -f 2 | tr -d ' '
    return $?
}

package_version_from_syncdb() {
    # $1: Package name
    pacman -Si "$1" | grep "Version" | cut -d : -f 2 | tr -d ' '
    return $?
}

full_kernel_version() {
    # Determine if the kernel version has the format 3.14 or 3.14.1
    if [[ ${AZB_KERNEL_VERSION} =~ ^[[:digit:]]+\.[[:digit:]]+\.([[:digit:]]+) ]]; then
        debug "full_kernel_version: Have kernel with minor version!"
    fi
    debug "full_kernel_version: BASH_REMATCH[1] == '${BASH_REMATCH[1]}'"
    if [[ ${BASH_REMATCH[1]} != "" ]]; then
        AZB_KERNEL_VERSION_FULL_X32=${AZB_KERNEL_VERSION_X32}
        AZB_KERNEL_VERSION_FULL_X64=${AZB_KERNEL_VERSION_X64}
        AZB_KERNEL_VERSION_CLEAN_X32=$(echo ${AZB_KERNEL_VERSION_X32} | sed s/-/_/g)
        AZB_KERNEL_VERSION_CLEAN_X64=$(echo ${AZB_KERNEL_VERSION_X64} | sed s/-/_/g)
    else
        debug "full_kernel_git_version: Have kernel without minor version!'"
        # Kernel version has the format 3.14, so add a 0.
        AZB_KERNEL_VERSION_FULL_X32=${AZB_KERNEL_VERSION}.0-${AZB_KERNEL_PKGREL_X32}
        AZB_KERNEL_VERSION_FULL_X64=${AZB_KERNEL_VERSION}.0-${AZB_KERNEL_PKGREL_X64}
        AZB_KERNEL_VERSION_CLEAN_X32=$(echo ${AZB_KERNEL_VERSION_FULL_X32} | sed s/-/_/g)
        AZB_KERNEL_VERSION_CLEAN_X64=$(echo ${AZB_KERNEL_VERSION_FULL_X64} | sed s/-/_/g)
    fi
}
