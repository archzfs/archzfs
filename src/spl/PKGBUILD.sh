#!/bin/bash

cat << EOF > ${AZB_PKGBUILD_PATH}
${AZB_HEADER}

pkgname="${AZB_SPL_PKGNAME}"
pkgver=${AZB_PKGVER}
pkgrel=${AZB_PKGREL}
pkgdesc="Solaris Porting Layer kernel modules."
depends=("${AZB_SPL_UTILS_PKGNAME}")
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("http://archive.zfsonlinux.org/downloads/zfsonlinux/spl/spl-${AZB_ZOL_VERSION}.tar.gz")
sha256sums=('${AZB_ZFS_SRC_HASH}}')
groups=("${AZB_ARCHZFS_PACKAGE_GROUP}")
license=("GPL")
install=spl.install
provides=("${AZF_SPL_PKGNAME}")

build() {
    cd "\${srcdir}/spl-${AZB_ZOL_VERSION}"
    ./autogen.sh

    ./configure --prefix=/usr \\
                --libdir=/usr/lib \\
                --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/${AZB_KERNEL_VERSION_FULL}/build \\
                --with-config=kernel

    make
}

package() {
    cd "\${srcdir}/spl-${AZB_ZOL_VERSION}"
    make DESTDIR="\${pkgdir}" install

    mv "\${pkgdir}/lib" "\${pkgdir}/usr/"
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/${AZB_KERNEL_VERSION_FULL}/Module.symvers
}
EOF
