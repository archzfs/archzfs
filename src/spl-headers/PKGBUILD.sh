#!/bin/bash

cat << EOF > ${spl_headers_pkgbuild_path}/PKGBUILD
${header}
pkgname="${spl_headers_pkgname}"
pkgver=${headers_pkgver}
pkgrel=${headers_pkgrel}
pkgdesc="Solaris Porting Layer kernel modules."
depends=(${linux_depends} ${linux_depends_max})
makedepends=(${linux_headers_depends} ${linux_headers_depends_max} ${headers_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
license=("GPL")

build() {
    _kernver="\$(cat /usr/lib/modules/${extramodules}/version)"
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/\${_kernver}/build \\
                --with-linux-obj=/usr/lib/modules/\${_kernver}/build \\
                --with-config=kernel
    make
}

package() {
    _kernver="\$(cat /usr/lib/modules/${extramodules}/version)"
    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -rf "\${pkgdir}/lib"
    rm -rf "\${pkgdir}/usr/src/spl-${zol_version}/\${_kernver}"
}
EOF

pkgbuild_cleanup "${spl_headers_pkgbuild_path}/PKGBUILD"
