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
    printf "${ALL_OFF}%s${ALL_OFF}\n\n" "${mesg}"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


plain_one_line() {
    local mesg=$1; shift
    printf "${ALL_OFF}${ALL_OFF}%s %s\n\n" "${mesg}" "${@}"
}


msg() {
    local mesg=$1; shift
    printf "${GREEN}====${ALL_OFF} ${BOLD}%s${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


msg2() {
    local mesg=$1; shift
    printf "${BLUE}++++ ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


warning() {
    local mesg=$1; shift
    printf "${YELLOW}==== WARNING: ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
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
        printf "${MAGENTA}~~~~ DEBUG: ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
        if [[ $# -gt 0 ]]; then
            printf '%s ' "${@}" 1>&2
            printf '\n\n'
        fi
    fi
}


test_pass() {
    local mesg=$1; shift
    printf "${GREEN}==== PASS: ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


test_fail() {
    local mesg=$1; shift
    printf "${RED}==== FAILED: ${ALL_OFF}${RED}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


trap_exit() {
    local sig=$?
    debug "trap_exit: args \$?=$?"
    if [[ ${sig} -eq 0 ]]; then
        msg "$(date) :: Done"
    # 155 is set when command args are not met, we don't need to print anything in that case
    elif [[ ${sig} -eq 1 && ${sig} -ne 155 ]]; then
        msg "$(date) :: EXIT"
    fi
}


trap_abort() {
    debug "trap_abort: args \$?=$?"
    msg "$(date) :: EXIT (abort)"
}


trap_quit() {
    debug "trap_quit: args \$?=$?"
    msg "$(date) :: EXIT (TERM, HUP, QUIT)"
}


trap_usr1() {
    debug "trap_usr1: args \$?=$?"
    error "$(date) :: EXIT: An unkown error has occurred."
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
    printf "${MAGENTA}XXXX NORUN: ${ALL_OFF}${BOLD}${mesg}${ALL_OFF}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "$@"
        printf '\n\n'
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


# Runs a command. Ouput is not captured. DRY_RUN=1 is ignored.
# To use this function, define the following in your calling script:
# RUN_CMD_RETURN=""
run_cmd_no_dry_run() {
    # $@: The command and args to run
    plain "Running command:" "$@"
    plain_one_line "Output:"
    echo -e "$@" | source /dev/stdin
    RUN_CMD_RETURN=$?
    echo
    plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
}


# Runs a command, capture the output in RUN_CMD_OUTPUT, but also show stdout.
# To use this function, define the following in your calling script:
# RUN_CMD_OUTPUT=""
# RUN_CMD_RETURN=""
run_cmd_show_and_capture_output() {
    # $@: The command and args to run
    if [[ $DRY_RUN -eq 1 ]]; then
        norun "CMD:" "$@"
    else
        plain "Running command:" "$@"
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
        echo
        plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
    fi
}


# Runs a command, capture the output in RUN_CMD_OUTPUT, but also show stdout. Ignores DRY_RUN=1.
# To use this function, define the following in your calling script:
# RUN_CMD_OUTPUT=""
# RUN_CMD_RETURN=""
run_cmd_show_and_capture_output_no_dry_run() {
    # $@: The command and args to run
    plain "Running command:" "$@"
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
    echo
    plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
}


# Runs the command, does not show output to stdout
# To use this function, define the following in your calling script:
# RUN_CMD_OUTPUT=""
# RUN_CMD_RETURN=""
run_cmd_no_output() {
    # $@: The command and args to run
    if [[ $DRY_RUN -eq 1 ]]; then
        norun "CMD:" "$@"
    else
        plain "Running command:" "$@"
        RUN_CMD_OUTPUT=$(echo -e "$@" | source /dev/stdin)
        RUN_CMD_RETURN=$?
        plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
    fi
}


# Runs the command, does not show output to stdout, ignores DRY_RUN=1
# To use this function, define the following in your calling script:
# RUN_CMD_OUTPUT=""
# RUN_CMD_RETURN=""
run_cmd_no_output_no_dry_run() {
    # $@: The command and args to run
    plain "Running command:" "$@"
    RUN_CMD_OUTPUT=$(echo -e "$@" | source /dev/stdin)
    RUN_CMD_RETURN=$?
    plain_one_line "Command returned:" "${RUN_CMD_RETURN}"
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


kernel_version_has_minor_version() {
    # $1: the kernel version
    # returns: 0 if the version contains a minor version and 1 if it does not
    if [[ ${1} =~ ^[[:digit:]]+\.[[:digit:]]+\.([[:digit:]]+) ]]; then
        debug "kernel_version_has_minor_version: Have kernel with minor version!"
        return 0
    fi
    debug "kernel_version_has_minor_version: Have kernel without minor version!"
    return 1
}


# Returns the full kernel version. If $1 is "3.14-1" then kernel_version_full returns "3.14.0-1".
kernel_version_full() {
    # $1: the kernel version
    local arg=$1
    if ! kernel_version_has_minor_version $1; then
        debug "kernel_version_full: Have kernel without minor version!"
        # Kernel version has the format 3.14, so add a 0.
        local arg=$(echo ${arg} | cut -f1 -d-)
        local rev=$(echo ${1} | cut -f2 -d-)
        printf "${arg}.0-${rev}"
        return 0
    fi
    printf ${arg}
}


# Returns the full kernel version. If $1 is "3.14-1" then kernel_version_full returns "3.14.0_1".
kernel_version_full_no_hyphen() {
    # $1: The full kernel version
    # returns: output is printed to stdout
    echo $(kernel_version_full ${1} | sed s/-/_/g)
}

# from makepkg
source_safe() {
	shopt -u extglob
	if ! source "$@"; then
		error "Failed to source $1"
		exit 1
	fi
	shopt -s extglob
}


check_mode() {
    # $1 the mode to check for
    for mode in "${MODE_LIST[@]}"; do
        debug "check_mode: on '${mode}'"
        local moden=$(echo ${mode} | cut -f2 -d:)
        if [[ "${moden}" == "$1" ]]; then
            if [[ ${MODE} != "" ]]; then
                error "Already have mode '${MODE}', only one mode can be used at a time!"
                usage
                exit 1
            fi
            MODE="$1"
            MODE_NAME=$(echo ${mode} | cut -f1 -d:)
            return
        fi
    done
    error "Unrecognized argument '$1'"
    usage
    exit 1
}

have_command() {
    # $1: The command to check for
    # returns 0 if true, and 1 for false
    debug "have_command: checking '$1'"
    for cmd in "${COMMANDS[@]}"; do
        debug "have_command: loop '$cmd'"
        if [[ ${cmd} == $1 ]]; then
            debug "have_command: '$1' is defined"
            return 0
        fi
    done
    return 1
}


check_debug() {
    # Returns 0 if DEBUG argument is defined and 1 if not
    for (( a = 0; a < $#; a++ )); do
        if [[ ${ARGS[$a]} == "-d" ]]; then
            return 0
        fi
    done
    return 1
}
