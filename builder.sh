set -e

msg() {
	local mesg=$1; shift
	printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

package_install_list() {
    # $1: A list of packages to install
    # $2: The arch of the package
    for PKG in $1; do
        FPKG=$(find "$REPO_BASEPATH" -type f -regex ".*$2/$PKG.*\($2\|any\).pkg.tar.xz")
        PLIST+="-I $FPKG "
    done
    $PLIST
}

CHROOT_CLEAN="$CHROOT_CLEAN"
CHROOT_UPDATE="$CHROOT_UPDATE"
for PKG in $PKG_LIST; do
    cd "$PWD/$PKG"
    msg "Building $PKG";
    pkgname=$(grep "pkgname=" PKGBUILD | sed -e "s/pkgname=([\'\"]\(.*\)[\'\"])/\1/")
    # TODO: CHECK THE ARCHITECTURE USING PACMAN INSTEAD OF USING SED.
    for ARCH in "i686" "x86_64"; do
        if [ -n "$CHROOT_UPDATE" ]; then
            setarch $ARCH arch-nspawn $CHROOT_PATH/$ARCH/$CHROOT_TARGET/root pacman -Syu --noconfirm
        fi
        I_PKGS=$(package_install_list "$1" $ARCH)
        ARGS="$CHROOT_CLEAN $I_PKGS -r $CHROOT_PATH/$ARCH/$CHROOT_TARGET -l
        $CHROOT_COPYNAME"
        setarch $ARCH makechrootpkg $ARGS -- -i
    done
    # We only need to clean once, otherwise on the update all of the package
    # updates would be installed.
    CHROOT_CLEAN=
    CHROOT_UPDATE=
    cd - > /dev/null
done
