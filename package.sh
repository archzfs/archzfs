#!/bin/sh

unset ALL_OFF BOLD BLUE GREEN RED YELLOW
if [[ -t 2 && ! $USE_COLOR = "n" ]]; then
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
	printf "${YELLOW}==> WARNING:${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

error() {
	local mesg=$1; shift
	printf "${RED}==> ERROR:${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

chroot_build() {
    awk -v newsums="$(makepkg -g)" '
    BEGIN {
    if (!newsums) exit 1
    }

    /^[[:blank:]]*(md|sha)[[:digit:]]+sums=/,/\)[[:blank:]]*$/ {
    if (!i) print newsums; i++
    next
    }

    1
    ' PKGBUILD > PKGBUILD.new && mv PKGBUILD{.new,}
    sudo makechrootpkg -r /opt/chroot/extra-x86_64 -l zfs64 -- -i
    if [[ $? != "0" ]]; then
        error "Failed building \"${1}\""
        exit 1;
    fi
    gpg --detach-sign -u 0EE7A126 --use-agent ${1}-*.pkg.tar.xz
    if [[ $? != "0" ]]; then
        warning "Failed signing \"${1}\""
        return 2;
    fi
    makepkg -Sfc
    if [[ $? != "0" ]]; then
        warning "Failed creating package sources for \"${1}\""
        return 3;
    fi
}

mkdir -p backup/new/{x86_64,i686,sources}

packages="spl-utils spl zfs-utils zfs"

for pkg in $packages; do
    cd "devsrc/${pkg}"
    msg "Building ${pkg}"
    chroot_build "${pkg}"
    cd ../../
done

msg "Moving sources to backup/new/sources"
find devsrc/ -type f -iname '*.src.tar*' -exec mv {} backup/new/sources/ \;

msg "Moving x86_64 packages to backup/new/x86_64"
find devsrc/ -type f -iname '*x86_64.pkg.tar*' -exec mv {} backup/new/x86_64/ \;

msg "Rotating backup archives"
mv backup/latest/sources/* backup/sources/
mv backup/new/sources/* backup/latest/sources/
mv backup/latest/x86_64/* backup/packages/x86_64/
mv backup/new/x86_64/* backup/latest/x86_64/
rm -rf backup/new

msg "Copying packages to the repository directories"
cp backup/latest/x86_64/* x86_64/

msg "Adding packages to the repository"
NPKGS=$(find backup/latest/x86_64/ -type f -iname '*.pkg.tar.xz' -printf "%f ")
cd x86_64/
repo-add -s -v -d archzfs.db.tar.xz $NPKGS
