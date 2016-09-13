#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_pkgname}"
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
pkgdesc="Kernel modules for the Zettabyte File System."
depends=("kmod" "${spl_pkgname}" "${zfs_utils_pkgname}" ${linux_depends})
makedepends=(${linux_headers_depends} ${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
groups=("${archzfs_package_group}")
license=("CDDL")
install=zfs.install
provides=("zfs")
conflicts=(${zfs_conflicts})
${zfs_replaces}

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-${zol_version} --with-config=kernel \\
                --with-linux=/usr/lib/modules/${kernel_mod_path}/build \\
                --with-linux-obj=/usr/lib/modules/${kernel_mod_path}/build
    make
}

package() {
    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib
    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/${kernel_mod_path}/Module.symvers
}
EOF

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
