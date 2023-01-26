#!/bin/bash -e

shopt -s nullglob


dry_run=0
debug_flag=0
haz_error=0
modes=()
test_mode=""
kernel_names=() # set by generate_mode_list
mode_list=() # set by generate_mode_list
test_commands_list=() # set by generate_test_commands_list
update_funcs=() # set by generate_mode_list
commands=()


# setup signal traps
trap "trap_quit" TERM HUP QUIT
trap "trap_abort" INT
trap "trap_usr1" USR1
trap "trap_exit" EXIT


# check if messages are to be printed using color
unset all_off bold black blue green red yellow white default cyan magenta
all_off="\e[0m"
bold="\e[1m"
black="${bold}\e[30m"
red="${bold}\e[31m"
green="${bold}\e[32m"
yellow="${bold}\e[33m"
blue="${bold}\e[34m"
magenta="${bold}\e[35m"
cyan="${bold}\e[36m"
white="${bold}\e[37m"
default="${bold}\e[39m"
readonly all_off bold black blue green red yellow white default cyan magenta


plain() {
    local mesg=$1; shift
    printf "${all_off}%s${all_off}\n\n" "${mesg}"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


plain_one_line() {
    local mesg=$1; shift
    printf "${all_off}${all_off}%s %s\n\n" "${mesg}" "${@}"
}


msg() {
    local mesg=$1; shift
    printf "${green}====${all_off} ${bold}%s${all_off}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


msg2() {
    local mesg=$1; shift
    printf "${blue}++++ ${all_off}${bold}${mesg}${all_off}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}"
        printf '\n\n'
    fi
}


warning() {
    local mesg=$1; shift
    printf "${yellow}==== WARNING: ${all_off}${bold}${mesg}${all_off}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


error() {
    local mesg=$1; shift
    printf "${red}==== ERROR: ${all_off}${red}${bold}${mesg}${all_off}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


debug() {
    # $1: The message to print.
    if [[ ${debug_flag} -eq 1 ]]; then
        local mesg=$1; shift
        printf "${magenta}~~~~ DEBUG: ${all_off}${bold}${mesg}${all_off}\n\n" "$mesg" 1>&2
        if [[ $# -gt 0 ]]; then
            printf '%s ' "${@}" 1>&2
            printf '\n\n'
        fi
    fi
}


test_pass() {
    local mesg=$1; shift
    printf "${green}==== PASS: ${all_off}${bold}${mesg}${all_off}\n\n" "$mesg" 1>&2
    if [[ $# -gt 0 ]]; then
        printf '%s ' "${@}" 1>&2
        printf '\n\n'
    fi
}


test_fail() {
    local mesg=$1; shift
    printf "${red}==== FAILED: ${all_off}${red}${bold}${mesg}${all_off}\n\n" "$mesg" 1>&2
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
    printf "${magenta}XXXX NORUN: ${all_off}${bold}${mesg}${all_off}\n\n" "$mesg"
    if [[ $# -gt 0 ]]; then
        printf '%s ' "$@"
        printf '\n\n'
    fi
}


# Runs a command. Ouput is not captured
# To use this function, define the following in your calling script:
# run_cmd_return=""
run_cmd() {
    run_cmd_return=0
    run_cmd_return=0
    # $@: The command and args to run
    if [[ ${dry_run} -eq 1 ]]; then
        norun "CMD:" "$@"
    else
        plain "Running command:" "$@"
        plain_one_line "Output:"
        echo -e "$@" | source /dev/stdin
        run_cmd_return=$?
        echo
        plain_one_line "Command returned:" "${run_cmd_return}"
    fi
}


run_cmd_check() {
    # $1 Exit code
    # $2 Error string if defined with print an error message
    if [[ ${run_cmd_return} -eq 0 ]]; then
        return
    fi
    if [[ -n $2 ]]; then
        error "$2"
    fi
    exit $1
}


# Runs a command. Ouput is not captured. dry_run=1 is ignored.
# To use this function, define the following in your calling script:
# run_cmd_return=""
run_cmd_no_dry_run() {
    run_cmd_return=0
    # $@: The command and args to run
    plain "Running command:" "$@"
    plain_one_line "Output:"
    echo -e "$@" | source /dev/stdin
    run_cmd_return=$?
    echo
    plain_one_line "Command returned:" "${run_cmd_return}"
}


# Runs a command, capture the output in run_cmd_output, but also show stdout.
# To use this function, define the following in your calling script:
# run_cmd_output=""
# run_cmd_return=""
run_cmd_show_and_capture_output() {
    run_cmd_output=""
    run_cmd_return=0
    # $@: The command and args to run
    if [[ ${dry_run} -eq 1 ]]; then
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
        run_cmd_output=$(echo -e "$@" | source /dev/stdin | tee >(cat - >&6); exit ${PIPESTATUS[1]})
        exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
        run_cmd_return=$?
        echo
        plain_one_line "Command returned:" "${run_cmd_return}"
    fi
}


# Runs a command, capture the output in run_cmd_output, but also show stdout. Ignores dry_run=1.
# To use this function, define the following in your calling script:
# run_cmd_output=""
# run_cmd_return=""
run_cmd_show_and_capture_output_no_dry_run() {
    run_cmd_output=""
    run_cmd_return=0
    # $@: The command and args to run
    plain "Running command:" "$@"
    plain_one_line "Output:"
    # The following allows command output to be displayed in jenkins and stored in the variable simultaneously
    # http://www.tldp.org/LDP/abs/html/x17974.html

    # WARNING: This function sometimes results in the following error:
    # lib.sh: line 145: /usr/bin/tee: Argument list too long
    # lib.sh: line 145: /bin/cat: Argument list too long

    exec 6>&1 # Link file descriptor 6 with stdout.
    run_cmd_output=$(echo -e "$@" | source /dev/stdin | tee >(cat - >&6); exit ${PIPESTATUS[1]})
    exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
    run_cmd_return=$?
    echo
    plain_one_line "Command returned:" "${run_cmd_return}"
}


# Runs the command, does not show output to stdout
# To use this function, define the following in your calling script:
# run_cmd_output=""
# run_cmd_return=""
run_cmd_no_output() {
    run_cmd_output=""
    run_cmd_return=0
    # $@: The command and args to run
    if [[ ${dry_run} -eq 1 ]]; then
        norun "CMD:" "$@"
    else
        plain "Running command:" "$@"
        run_cmd_output=$(echo -e "$@" | source /dev/stdin)
        run_cmd_return=$?
        plain_one_line "Command returned:" "${run_cmd_return}"
    fi
}


# Runs the command, does not show output to stdout, ignores dry_run=1
# To use this function, define the following in your calling script:
# run_cmd_output=""
# run_cmd_return=""
run_cmd_no_output_no_dry_run() {
    run_cmd_output=""
    run_cmd_return=0
    # $@: The command and args to run
    plain "Running command:" "${@}"
    run_cmd_output=$(echo -e "${@}" | source /dev/stdin )
    run_cmd_return=$?
    plain_one_line "Command returned:" "${run_cmd_return}"
}


package_arch_from_path() {
    # $1: Package path
    LC_ALL=C pacman -Qip "$1" | grep "Architecture" | cut -d : -f 2 | tr -d ' '
    return $?
}


package_name_from_path() {
    # $1: Package path
    LC_ALL=C pacman -Qip "$1" | grep "Name" | cut -d : -f 2 | tr -d ' '
    return $?
}


package_version_from_path() {
    # $1: Package path
    LC_ALL=C pacman -Qip "$1" | grep "Version" | cut -d : -f 2 | tr -d ' '
    return $?
}


package_version_from_syncdb() {
    # $1: Package name
    LC_ALL=C pacman -Si "$1" | grep "Version" | cut -d : -f 2 | tr -d ' '
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
        if [[ ${1} =~ ^([[:digit:]]+\.[[:digit:]]+)\.?([[:alpha:][:digit:]]+)?\-([[:digit:]]+) ]]; then
            local arg=${BASH_REMATCH[1]}
            local minor=${BASH_REMATCH[2]}
            local rev=${BASH_REMATCH[3]}
            if [[ ${minor} =~ ^[[:alpha:]]+ ]]; then
                printf "${arg}.0.${minor}-${rev}"
                return 0
            fi
        fi
        printf "${arg}.0-${rev}"
        return 0
    fi
    printf ${arg}
}


# Returns the pkg kernel version. If $1 is "3.14-1" then kernel_version_full returns "3.14_1".
kernel_version_no_hyphen() {
    # $1: The full kernel version
    # returns: output is printed to stdout
    echo ${1} | sed s/-/./g
}

reset_variables() {
    kernel_version_pkgver=""
    kernel_version_full=""
    kernel_version=""
    zfs_pkgver=""
    zfs_pkgrel=""
    zfs_makedepends=""
    zfs_src_hash=${zfs_src_hash_conf}
    zfs_conflicts=""
    zfs_pkgname=""
    zfs_utils_pkgname=""
    zfs_pkgbuild_path=""
    zfs_dkms_pkgbuild_path=""
    zfs_src_target=""
    zfs_workdir=""
    linux_depends=""
    linux_headers_depends=""
    zfs_replaces=""
    zfs_set_commit=""
    zfs_replaces=''
    zfs_utils_replaces=''
}

# from makepkg
source_safe() {
    reset_variables
    export script_dir mode kernel_name
    shopt -u extglob
    if ! source "$@"; then
        error "Failed to source $1"
        exit 1
    fi
    shopt -s extglob
}


check_internet() {
    if [[ $(curl -s https://www.google.com/ &> /dev/null; echo $?) -ne 0 ]]; then
        return 1
    fi
    return 0
}

cmd_regex() {
    # $1: the cmd command to run
    # $2: The Perl regex to match with
    run_cmd_no_output "${1}"
    
    if [[ ${dry_run} -eq 1 ]]; then
        return 0
    fi

    if [[ $(echo ${run_cmd_output} | \grep -q "504 Gateway Timeout"; echo $?) -eq 0 ]]; then
        return 55
    elif [[ $(echo ${run_cmd_output} | \grep -q "503 Service Unavailable"; echo $?) -eq 0 ]]; then
        return 55
    elif [[ ${run_cmd_output} == "RETVAL: 7" ]]; then
        return 55
    elif [[ ${run_cmd_return} -eq 7 ]]; then
        return 55
    fi

    regex_match=$(echo "${run_cmd_output}" | \grep -Po -m 1 "${2}")
    debug "Got \"${regex_match}\" from command."
}


get_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    debug "Checking webpage: $1"
    debug "Using regex: `printf "%q" "$2"`"

    cmd_regex "curl -sL ${1}" "${2}"
    webpage_output="${regex_match}"
}


get_repo_package() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    debug "Checking repo files: $1"
    debug "Using regex: `printf "%q" "$2"`"

    cmd_regex "curl -sL ${1} | tar tzv --exclude='*/*'" "${2}"
}

check_webpage() {
    # $1: The url to scrape
    # $2: The Perl regex to match with
    # $3: Expect match
    
    if ! get_webpage "$1" "$2"; then
        return $?
    fi

    debug "Expecting: $3"

    if [[ ${webpage_output} != "$3" ]]; then
        error "Checking '$1' expected '$3' got '${webpage_return}'"
        debug "Returning 1 from check_webpage()"
        return 1
    fi

    return 0
}


check_result() {
    # $1 current line
    # $2 changed line
    # $3 the return code from check_webpage
    if [[ ${3} -eq 0 ]]; then
        msg2 "The $1 version is current."
        haz_error=0
    elif [[ ${3} -eq 1 ]]; then
        error "The $2 is out-of-date!"
        haz_error=1
    elif [[ ${3} -eq 55 ]]; then
        warning "The $2 package page was unreachable!"
        haz_error=0
    else
        error "Check returned ${3}"
        haz_error=1
    fi
}

check_openzfs_version() {
    #
    # Check OpenZFS.org
    #
    msg "Checking openzfs.org for new versions..."
    check_webpage "https://github.com/openzfs/zfs/releases/latest" "(?<=/openzfs/zfs/releases/download/zfs-)[\d\.]*" "${openzfs_version}"
    check_result "OpenZFS stable version" "OpenZFS stable version" "$?"
}


check_mode() {
    # $1 the mode to check for
    debug "check_mode: checking '$1'"

    # add all available modes
    if [[ "${1}" == "all" ]]; then
        for m in "${mode_list[@]}"; do
            mode=("$(echo ${m} | cut -f2 -d:)")

            # do not add archiso or linux-vfio
            if [[ "${mode}" == "iso" ]] || [[ "${mode}" == "vfio" ]]; then
                continue
            fi

            modes+=("${mode}")
            kernel_names+=("$(echo ${m} | cut -f1 -d:)")
        done
    else
        for m in "${mode_list[@]}"; do
            debug "check_mode: on '${m}'"
            local moden=$(echo ${m} | cut -f2 -d:)
            # debug "moden: ${moden}"
            if [[ "${moden}" == "$1" ]]; then
                modes+=("$1")
                kernel_names+=("$(echo ${m} | cut -f1 -d:)")
                return
            fi
        done
        error "Unrecognized argument '$1'"
        usage
        exit 155
    fi
}


check_test_mode() {
    # $1 the mode to check for
    debug "check_test_mode: checking for mode in '$1'"
    for m in "${mode_list[@]}"; do
        debug "check_test_mode: on '${m}'"
        local moden=$(echo ${m} | cut -f2 -d:)
        # debug "moden: ${moden}"
        if [[ "${moden}" == "$1" ]]; then
            if [[ ${mode} != "" ]]; then
                error "Already have mode '${moden}', only one mode can be used at a time!"
                usage
                exit 155
            fi
            mode="$1"
            kernel_name=$(echo ${m} | cut -f1 -d:)
            return
        fi
    done
    debug "check_test_mode: checking for test mode in '$1'"
    for m in "${test_commands_list[@]}"; do
        debug "check_test_mode: on '${m}'"
        local moden=$(echo ${m})
        if [[ ${moden} =~ $1 ]]; then
            debug "Found match! moden: ${moden} \$1: $1"
            if [[ ${test_mode} != "" ]]; then
                error "Already have test mode '${moden}', only one test mode can be used at a time!"
                usage
                exit 155
            fi
            test_mode="${moden}"
            return
        fi
    done
    error "Unrecognized argument '$1'"
    usage
    exit 155
}



have_command() {
    # $1: The command to check for
    # returns 0 if true, and 1 for false
    debug "have_command: checking '$1'"
    for cmd in "${commands[@]}"; do
        # debug "have_command: loop '$cmd'"
        if [[ ${cmd} == $1 ]]; then
            debug "have_command: '$1' is defined"
            return 0
        fi
    done
    debug "have_command: '$1' is not defined"
    return 1
}


have_test_command() {
    # $1: The command to check for
    # returns 0 if true, and 1 for false
    debug "have_test_command: checking '$1'"
    for cmd in "${test_commands_list[@]}"; do
        # debug "have_test_command: loop '$cmd'"
        if [[ ${cmd} == $1 ]]; then
            debug "have_test_command: '$1' is defined"
            return 0
        fi
    done
    debug "have_test_command: '$1' is not defined"
    return 1
}


check_debug() {
    # args must be defined in the source script that loads lib.sh!
    # Returns 0 if debug argument is defined and 1 if not
    for (( a = 0; a < "${#args[@]}"; a++ )); do
        if [[ ${args[$a]} == "-d" ]]; then
            return 0
        fi
    done
    return 1
}


generate_mode_list() {
    # $1: The path where the kernel things can be found, must have trailing slash
    path="$1"
    if [[ ${path} == "" ]]; then
        path="${script_dir}/src/kernels"
    fi
    for m in $(ls ${path}); do
        mn=$(source ${path}/${m}; echo ${mode_name})
        md=$(source ${path}/${m}; echo ${mode_desc})
        mode_list+=("${m%.*}:${mn}:${md}")
    done
}


generate_test_commands_list() {
    # $1: The path where the kernel things can be found, must have trailing slash
    path="$1"
    if [[ ${path} == "" ]]; then
        path="${script_dir}"
    fi
    debug "generate_test_commands_list: path == ${path}"
    for m in $(find ${path} -type d -iname "*archzfs-qemu-*-test-*"); do
        test_commands_list+=("${m}")
    done
}


get_kernel_update_funcs() {
    update_funcs=()

    for kernel in $(ls ${script_dir}/src/kernels); do
        if [[ ${kernel%.*} != ${kernel_name} ]]; then
            continue
        fi
        updatefuncs=$(cat "${script_dir}/src/kernels/${kernel}" | grep -v "^.*#" | grep -oh "update_.*_pkgbuilds")
        for func in ${updatefuncs}; do update_funcs+=("${func}"); done
    done
}

check_skip_build() {
    # $1: Name of package to check
    pkg=${1}

    # get version of any package that has been built previously
    run_cmd_show_and_capture_output "ls \"${script_dir}/packages/${kernel_name}/${pkg}/\"${pkg}*.pkg.tar.zst | grep \"$pkg\" | grep -v \"headers\" | tail -1"
    pkg_path=${run_cmd_output}

    if [[ ${pkg_path} == "" ]]; then
        msg2 "No previously built packages exist for ${pkg}!"
    else
        vers=$(package_version_from_path ${pkg_path})

        # get current version
        eval $(source "${script_dir}/packages/${kernel_name}/${pkg}/PKGBUILD";
               echo current_vers="${pkgver}";
               echo current_rel="${pkgrel}";
        )

        # check if version has already been built
        if [[ ${run_cmd_return} -eq 0 && ${vers} == ${current_vers}-${current_rel} ]]; then
            msg "${pkg}=${vers} has already been built"
            return 0
        fi
    fi

    return 1
}

check_skip_src() {
    # $1: Name of package to check
    pkg=${1}

    # check for any source package that has been generated previously
    run_cmd_show_and_capture_output "ls \"${script_dir}/packages/${kernel_name}/${pkg}/\"${pkg}*.src.tar.gz | grep \"$pkg\" | grep -v \"headers\" | tail -1"
    pkg_path=${run_cmd_output}

    if [[ ${pkg_path} == "" ]]; then
        msg2 "No previously generated source package exist for ${pkg}!"
    else
        msg "sources for ${pkg} have already been built"
        return 0
    fi

    return 1
}

debug_print_default_vars() {
    debug "dry_run: "${dry_run}
    debug "debug_flag: "${debug_flag}
    debug "mode: ${mode}"
    debug "kernel_name: ${kernel_name}"
    if [[ ${#mode_list[@]} -gt 0 ]]; then
        debug_print_array "mode_list" "${mode_list[@]}"
    fi
    if [[ ${#update_funcs[@]} -gt 0 ]]; then
        debug_print_array "update_funcs" "${update_funcs[@]}"
    fi
    if [[ ${#commands[@]} -gt 0 ]]; then
        debug_print_array "commands" "${commands[@]}"
    fi
}


debug_print_array() {
    # $1 array name
    # $2 array
    if [[ $# -lt 2 ]]; then
        warning "debug_print_array: Array '$1' is empty"
        return
    fi
    local name=$1; shift
    for item in "${@}"; do
        debug "${name} (array item): ${item}"
    done
}


# Do this early so it is possible to see the output
if check_debug; then
    debug_flag=1
    debug "debug mode is enabled"
fi


pkgbuild_cleanup() {
    # $1 the file to process
    # Strip all blanklines
    sed -i '/^\s*$/d' $1
    sed -i 's/"\ )$/")/g' $1
    # Readd blanklines above build and package
    sed -i '/^pkgver\(\)/{x;p;x;}' $1
    sed -i '/^build\(\)/{x;p;x;}' $1
    sed -i '/^package\(\)/{x;p;x;}' $1
}


git_check_repo() {
    for pkg in "${pkg_list[@]}"; do
        local reponame="zfs"
        local url="${zfs_git_url}"
        local repopath="${script_dir}/packages/${kernel_name}/${pkg}/${reponame}"
        local temprepopath="${script_dir}/temp/${reponame}"

        debug "GIT URL: ${url}"
        debug "GIT REPO: ${repopath}"

        if [[ ! -d "${repopath}"  ]]; then
            msg2 "Cloning repo '${repopath}'"
            
            # clone into temp directory
            if [[ ! -d "${temprepopath}"  ]]; then
                run_cmd_no_dry_run "git clone --mirror '${url}' '${temprepopath}'"
                if [[ ${run_cmd_return} -ne 0 ]]; then
                    error "Failure while cloning ${url} repo"
                    exit 1
                fi
            fi
            
            # copy into package directory from temp
            run_cmd_no_dry_run "cp -r '${temprepopath}' '${repopath}'"
        fi
    
        msg2 "Updating repo '${repopath}'"
        run_cmd_no_dry_run "cd ${repopath} && git fetch --all -p"
        if [[ ${run_cmd_return} -ne 0 ]]; then
            error "Failure while fetching ${url} repo"
            exit 1
        fi
    done
}


git_calc_pkgver() {
    msg2 "Cloning working copy for zfs"
    local kernvers=${kernel_version_pkgver}
    local sha=${zfs_git_commit}

    # use utils package, if no kernel version is set and not on dkms
    if [[ -z ${zfs_dkms_pkgbuild_path} && -z "${kernvers}" ]]; then
        pkg=${zfs_utils_pkgname}
    else
        pkg=${zfs_pkgname}
    fi

    debug "Using package '${pkg}'"

    # Checkout the git repo to a work directory
    local cmd="/usr/bin/bash -s << EOF 2>/dev/null\\n"
    cmd+="[[ -d temp/version ]] && rm -r temp/version\\n"
    cmd+="mkdir temp/version && cd temp/version\\n"
    cmd+="git clone ../../packages/${kernel_name}/${pkg}/zfs && cd zfs\\n"
    cmd+="git checkout -b azb ${sha}\\n"
    cmd+="EOF"
    run_cmd_no_output_no_dry_run "${cmd}"

    # Get the version number past the last tag
    msg2 "Calculating PKGVER"
    cmd="cd temp/version/zfs && "
    cmd+='printf "%s.r%s.g%s" "$(git log -n 1 --pretty=format:"%cd" --date=short | sed "s/-/./g")" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"'

    run_cmd_no_output_no_dry_run "${cmd}"

    zfs_git_ver=${run_cmd_output}
    zfs_pkgver=${zfs_git_ver};
    debug "zfs_pkgver: ${zfs_pkgver}"

    # get latest commit sha
    cmd="cd temp/version/zfs && "
    cmd+="git rev-parse HEAD"
    run_cmd_no_output_no_dry_run "${cmd}"
    latest_zfs_git_commit=${run_cmd_output}

    # Cleanup
    msg2 "Removing working directory"
    run_cmd_no_output_no_dry_run "rm -vrf temp/version"
}
