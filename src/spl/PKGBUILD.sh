#!/bin/bash

cat << EOF > ${AZB_SPL_PKGBUILD_PATH}/PKGBUILD
${AZB_HEADER}
pkgname="${AZB_SPL_PKGNAME}"
pkgver=${AZB_PKGVER}
pkgrel=${AZB_PKGREL}
pkgdesc="Solaris Porting Layer kernel modules."
depends=("${AZB_SPL_UTILS_PKGNAME}" "linux-headers" "kmod")
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("http://archive.zfsonlinux.org/downloads/zfsonlinux/spl/spl-${AZB_ZOL_VERSION}.tar.gz")
sha256sums=('${AZB_SPL_SRC_HASH}')
groups=("${AZB_ARCHZFS_PACKAGE_GROUP}")
license=("GPL")
install=spl.install
provides=("${AZB_SPL_PKGNAME}")

build() {
    cd "\${srcdir}/spl-${AZB_ZOL_VERSION}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/${AZB_KERNEL_MOD_PATH}/build \\
                --with-config=kernel
    make
}

package() {
    cd "\${srcdir}/spl-${AZB_ZOL_VERSION}"
    make DESTDIR="\${pkgdir}" install
    mv "\${pkgdir}/lib" "\${pkgdir}/usr/"

    # TODO: Not sure what this does, or if it is needed anymore. It breaks compatibility with non-stock kernels...
    # sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/${AZB_KERNEL_MOD_PATH}/Module.symvers
}
EOF
