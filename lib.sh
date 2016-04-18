#!/bin/bash -e

shopt -s nullglob

# check if messages are to be printed using color
unset ALL_OFF BOLD BLACK BLUE GREEN RED YELLOW WHITE DEFAULT CYAN MAGENTA
ALL_OFF="\e[0m"
BOLD="\e[1m"
BLACK="${BOLD}\e[30m"
RED="${BOLD}\e[31m"
GREEN="${BOLD}\e[32m"
YELLOW="${BOLD}\e[33m"
BLUE="${BOLD}\e[34m"
MAGENTA="${BOLD}\e[35m"
CYAN="${BOLD}\e[36m"
WHITE="${BOLD}\e[37m"
DEFAULT="${BOLD}\e[39m"
readonly ALL_OFF BOLD BLACK BLUE GREEN RED YELLOW WHITE DEFAULT CYAN MAGENTA


plain() {
    local mesg=$1; shift
    printf "${ALL_OFF}${BLACK}%s${ALL_OFF}\n\n" "${mesg}"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


plain_one_line() {
    local mesg=$1; shift
    printf "○ ${ALL_OFF}${BLACK}%s${ALL_OFF} %s\n\n" "${mesg}" "${@}"
}


msg() {
    local mesg=$1; shift
    printf "${GREEN}====${ALL_OFF} ${BLACK}${BOLD}%s${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


msg2() {
    local mesg=$1; shift
    printf "${BLUE}++++ ${ALL_OFF}${BLACK}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


warning() {
    local mesg=$1; shift
    printf "${YELLOW}==== WARNING: ${ALL_OFF}${BLACK}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


error() {
    local mesg=$1; shift
    printf "${RED}==== ERROR: ${ALL_OFF}${RED}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


debug() {
    # $1: The message to print.
    if [[ $DEBUG -eq 1 ]]; then
        local mesg=$1; shift
        printf "${MAGENTA}~~~~ DEBUG: ${ALL_OFF}${BLACK}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
        if [[ $# -gt 0 ]]; then
            printf '%s ' "${@}" 1>&2
            printf '\n\n'
        fi
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
    trap - INT QUIT TERM HUP
    msg "Got INT QUIT TERM HUP signal!"
    abort
}


trap_exit() {
    trap - EXIT
    msg "$(date) :: All Done!"
    cleanup
}


# Check a symlink, re-create it if the target is not correct
function check_symlink() {
    # $1 = Symlink
    # $2 = Symlink target
    if [[ "$1" = "$(readlink $2)" ]]; then
        return
    elif [[ -L "$2" ]]; then
        rm "$2"
    fi
    ln -s "$1" "$2"
}


# Converts an absolute path into a relative path using python and prints on
# stdout.
function relativePath() {
    # $1: Path that should be converted to relative path
    # $2: The start path, usually $PWD
    python -c "import os.path; print(os.path.relpath('$1', '$2'))"
}


norun() {
    local mesg=$1; shift
    printf "${MAGENTA}XXXX NORUN: ${ALL_OFF}${BLACK}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf "%s\n\n" "$@"
    fi
}


# Runs a command. Ouput is not captured
# To use this function, define the following in your calling script:
# RUN_CMD_RETURN=""
run_cmd() {
    # $@: The command and args to run
    if [[ $DRY_RUN -eq 1 ]]; then
        norun "CMD:" "$@"
    else
        plain "Running command:" "$@"
        plain_one_line "Output:"
        echo -e "$@" | source /dev/stdin
        RUN_CMD_RETURN=$?
        echo
        plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
    fi
}


# Runs a command, capture the output in RUN_CMD_OUTPUT, but also show stdout.
# To use this function, define the following in your calling script:
# RUN_CMD_RETURN=""
run_cmd_show_and_capture_output() {
    # $@: The command and args to run
    if [[ $DRY_RUN -eq 1 ]]; then
        norun "CMD:" $@
    else
        plain "Running command:" $@
        plain_one_line "Output:"
        # The following allows command output to be displayed in jenkins and stored in the variable simultaneously
        # http://www.tldp.org/LDP/abs/html/x17974.html

        # WARNING: This function sometimes results in the following error:
        # lib.sh: line 145: /usr/bin/tee: Argument list too long
        # lib.sh: line 145: /bin/cat: Argument list too long

        exec 6>&1 # Link file descriptor 6 with stdout.
        RUN_CMD_OUTPUT=$(echo -e "$@" | source /dev/stdin | tee >(cat - >&6); exit ${PIPESTATUS[1]})
        exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
        RUN_CMD_RETURN=$?
        echo -e "\n"
        plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
    fi
}


# Runs the command, does not show output to stdout
# To use this function, define the following in your calling script:
# RUN_CMD_OUTPUT=""
# RUN_CMD_RETURN=""
run_cmd_no_output() {
    # $@: The command and args to run
    if [[ $DRY_RUN -eq 1 ]]; then
        norun "CMD:" $@
    else
        plain "Running command:" "$@"
        RUN_CMD_OUTPUT=$(printf "$@" | source /dev/stdin)
        RUN_CMD_RETURN=$?
        plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
    fi
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
