#!/bin/bash

cat << EOF > ${AZB_ZFS_PKGBUILD_PATH}/PKGBUILD
${AZB_HEADER}
pkgname="${AZB_ZFS_PKGNAME}"
pkgver=${AZB_PKGVER}
pkgrel=${AZB_PKGREL}
pkgdesc="Kernel modules for the Zettabyte File System."
depends=("${AZB_SPL_PKGNAME}" "${AZB_ZFS_UTILS_PKGNAME}" "linux-headers" "kmod")
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("http://archive.zfsonlinux.org/downloads/zfsonlinux/zfs/zfs-${AZB_ZOL_VERSION}.tar.gz")
sha256sums=('${AZB_ZFS_SRC_HASH}')
groups=("${AZB_ARCHZFS_PACKAGE_GROUP}")
license=("CDDL")
install=zfs.install
provides=("${AZB_ZFS_PKGNAME}")

build() {
    cd "\${srcdir}/zfs-${AZB_ZOL_VERSION}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-${AZB_ZOL_VERSION} --with-config=kernel \\
                --with-linux=/usr/lib/modules/${AZB_KERNEL_MOD_PATH}/build
    make
}

package() {
    cd "\${srcdir}/zfs-${AZB_ZOL_VERSION}"
    make DESTDIR="\${pkgdir}" install

    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # TODO: Not sure what this does, or if it is needed anymore. It breaks compatibility with non-stock kernels...
    # sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/${AZB_KERNEL_MOD_PATH}/Module.symvers
}
EOF
