#!/bin/bash

cat << EOF > ${AZB_ZFS_UTILS_PKGBUILD_PATH}/PKGBUILD
${AZB_HEADER}
pkgname="${AZB_ZFS_UTILS_PKGNAME}"
pkgver=${AZB_PKGVER}
pkgrel=${AZB_PKGREL}
pkgdesc="Kernel module support files for the Zettabyte File System."
depends=("${AZB_SPL_PKGNAME}")
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("http://archive.zfsonlinux.org/downloads/zfsonlinux/zfs/zfs-${AZB_ZOL_VERSION}.tar.gz"
        "zfs-utils.bash-completion-r1"
        "zfs-utils.initcpio.install"
        "zfs-utils.initcpio.hook")
sha256sums=('${AZB_ZFS_SRC_HASH}'
            '${AZB_ZFS_BASH_COMPLETION_HASH}'
            '${AZB_ZFS_INITCPIO_INSTALL_HASH}'
            '${AZB_ZFS_INITCPIO_HOOK_HASH}')
license=("CDDL")
groups=("${AZB_ARCHZFS_PACKAGE_GROUP}")
provides=("${AZB_ZFS_UTILS_PKGNAME}")

build() {
    cd "\${srcdir}/zfs-${AZB_ZOL_VERSION}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --with-mounthelperdir=/usr/bin \\
                --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \\
                --with-udevdir=/lib/udev --libexecdir=/usr/lib/zfs-${AZB_ZOL_VERSION} \\
                --with-config=user
    make
}

package() {
    cd "\${srcdir}/zfs-${AZB_ZOL_VERSION}"
    make DESTDIR="\${pkgdir}" install

    # Remove uneeded files
    rm -r "\${pkgdir}"/etc/init.d
    rm -r "\${pkgdir}"/usr/lib/dracut

    # move module tree /lib -> /usr/lib
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # Install the support files
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.hook "\${pkgdir}"/usr/lib/initcpio/hooks/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.install "\${pkgdir}"/usr/lib/initcpio/install/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.bash-completion-r1 "\${pkgdir}"/usr/share/bash-completion/completions/zfs
}
EOF
