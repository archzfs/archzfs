#!/bin/bash

cat << EOF > ${zfs_utils_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_utils_pkgname}"
${zfs_set_commit}
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
pkgdesc="Kernel module support files for the Zettabyte File System."
makedepends=("python" "python-setuptools" "python-cffi" ${zfs_makedepends})
optdepends=("python: pyzfs and extra utilities", "python-cffi: pyzfs")
arch=("x86_64")
url="http://openzfs.org/"
source=("${zfs_src_target}"
        "zfs-utils.initcpio.install"
        "zfs-utils.initcpio.hook"
        "zfs-utils.initcpio.zfsencryptssh.install")
sha256sums=("${zfs_src_hash}"
            "${zfs_initcpio_install_hash}"
            "${zfs_initcpio_hook_hash}"
            "${zfs_initcpio_zfsencryptssh_install}")
license=("CDDL")
groups=("${archzfs_package_group}")
provides=("zfs-utils" "spl-utils")
install=zfs-utils.install
conflicts=("zfs-utils" "spl-utils")
${zfs_utils_replaces}
backup=('etc/zfs/zed.d/zed.rc' 'etc/default/zfs' 'etc/modules-load.d/zfs.conf' 'etc/sudoers.d/zfs')

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --with-mounthelperdir=/usr/bin \\
                --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \\
                --with-udevdir=/usr/lib/udev --libexecdir=/usr/lib \\
                --with-config=user --enable-systemd --enable-pyzfs \\
                --with-zfsexecdir=/usr/lib/zfs --localstatedir=/var
    make
}

package() {
    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install

    # Remove uneeded files
    rm -r "\${pkgdir}"/etc/init.d
    rm -r "\${pkgdir}"/usr/share/initramfs-tools
    rm -r "\${pkgdir}"/usr/lib/modules-load.d

    # Autoload the zfs module at boot
    mkdir -p "\${pkgdir}/etc/modules-load.d"
    printf "%s\n" "zfs" > "\${pkgdir}/etc/modules-load.d/zfs.conf"

    # fix permissions
    chmod 750 \${pkgdir}/etc/sudoers.d
    chmod 440 \${pkgdir}/etc/sudoers.d/zfs

    # Install the support files
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.hook "\${pkgdir}"/usr/lib/initcpio/hooks/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.install "\${pkgdir}"/usr/lib/initcpio/install/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.zfsencryptssh.install "\${pkgdir}"/usr/lib/initcpio/install/zfsencryptssh
    install -D -m644 contrib/bash_completion.d/zfs "\${pkgdir}"/usr/share/bash-completion/completions/zfs
}
EOF

pkgbuild_cleanup "${zfs_utils_pkgbuild_path}/PKGBUILD"
