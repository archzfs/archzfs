#!/bin/bash

cat << EOF > ${zfs_headers_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_headers_pkgname}"
pkgver=${headers_pkgver}
pkgrel=${headers_pkgrel}
pkgdesc="Kernel modules for the Zettabyte File System."
depends=(${zfs_headers_depends} ${linux_depends} ${linux_depends_max})
makedepends=(${zfs_headers_depends} ${linux_headers_depends} ${headers_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
license=("CDDL")

build() {
    _kernver="\$(cat /usr/lib/modules/${extramodules}/version)"
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-${zol_version} --with-config=kernel \\
                --with-linux=/usr/lib/modules/\${_kernver}/build \\
                --with-linux-obj=/usr/lib/modules/\${_kernver}/build
    make
}

package() {
    _kernver="\$(cat /usr/lib/modules/${extramodules}/version)"
    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -rf "\${pkgdir}/lib"
    rm -rf "\${pkgdir}/usr/src/zfs-${zol_version}/\${_kernver}"
}
EOF

pkgbuild_cleanup "${zfs_headers_pkgbuild_path}/PKGBUILD"
