#!/bin/bash

zfs_depends=""
# pyzfs in zfs-git depends on python2 (https://github.com/zfsonlinux/zfs/pull/7230)
if [[ ${archzfs_package_group} =~ -git$ ]]; then
    zfs_depends+="\"python2\""
fi

cat << EOF > ${zfs_utils_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_utils_pkgname}"
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
pkgdesc="Kernel module support files for the Zettabyte File System."
depends=(${zfs_depends})
makedepends=(${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}"
        "zfs-utils.bash-completion-r1"
        "zfs-utils.initcpio.install"
        "zfs-utils.initcpio.hook")
sha256sums=("${zfs_src_hash}"
            "${zfs_bash_completion_hash}"
            "${zfs_initcpio_install_hash}"
            "${zfs_initcpio_hook_hash}")
license=("CDDL")
groups=("${archzfs_package_group}")
provides=("zfs-utils")
install=zfs-utils.install
conflicts=(${zfs_utils_conflicts})
${zfs_utils_replaces}
backup=('etc/zfs/zed.d/zed.rc' 'etc/default/zfs')

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --with-mounthelperdir=/usr/bin \\
                --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \\
                --with-udevdir=/lib/udev --libexecdir=/usr/lib/zfs-${zol_version} \\
                --with-config=user --enable-systemd
    make
}

package() {
    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install

    # Remove uneeded files
    rm -r "\${pkgdir}"/etc/init.d
    rm -r "\${pkgdir}"/usr/lib/dracut

    # move module tree /lib -> /usr/lib
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # Autoload the zfs module at boot
    mkdir -p "\${pkgdir}/etc/modules-load.d"
    printf "%s\n" "zfs" > "\${pkgdir}/etc/modules-load.d/zfs.conf"

    # fix permissions
    chmod 750 \${pkgdir}/etc/sudoers.d

    # Install the support files
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.hook "\${pkgdir}"/usr/lib/initcpio/hooks/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.install "\${pkgdir}"/usr/lib/initcpio/install/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.zfsencryptssh.install "\${pkgdir}"/usr/lib/initcpio/install/zfsencryptssh
    install -D -m644 "\${srcdir}"/zfs-utils.bash-completion-r1 "\${pkgdir}"/usr/share/bash-completion/completions/zfs
}
EOF

pkgbuild_cleanup "${zfs_utils_pkgbuild_path}/PKGBUILD"
