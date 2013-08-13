set -e

shopt -s nullglob

# check if messages are to be printed using color
unset ALL_OFF BOLD BLUE GREEN RED YELLOW

# prefer terminal safe colored and bold text when tput is supported
if tput setaf 0 &>/dev/null; then
    ALL_OFF="$(tput sgr0)"
    BOLD="$(tput bold)"
    BLUE="${BOLD}$(tput setaf 4)"
    GREEN="${BOLD}$(tput setaf 2)"
    RED="${BOLD}$(tput setaf 1)"
    YELLOW="${BOLD}$(tput setaf 3)"
else
    ALL_OFF="\e[1;0m"
    BOLD="\e[1;1m"
    BLUE="${BOLD}\e[1;34m"
    GREEN="${BOLD}\e[1;32m"
    RED="${BOLD}\e[1;31m"
    YELLOW="${BOLD}\e[1;33m"
fi
readonly ALL_OFF BOLD BLUE GREEN RED YELLOW

plain() {
	local mesg=$1; shift
	printf "${BOLD}    ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg() {
	local mesg=$1; shift
	printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg2() {
	local mesg=$1; shift
	printf "${BLUE}  ->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

warning() {
	local mesg=$1; shift
	printf "${YELLOW}==> $(gettext "WARNING:")${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

error() {
	local mesg=$1; shift
	printf "${RED}==> $(gettext "ERROR:")${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}
