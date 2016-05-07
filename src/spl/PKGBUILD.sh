#!/bin/bash

cat << EOF > ${spl_pkgbuild_path}/PKGBUILD
${header}
pkgname="${spl_pkgname}"
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}
pkgdesc="Solaris Porting Layer kernel modules."
depends=("${spl_utils_pkgname}" "kmod"
         ${linux_depends}
         ${linux_headers_depends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
groups=("${archzfs_package_group}")
license=("GPL")
install=spl.install
provides=("${spl_pkgname}")
${spl_makedepends}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/${kernel_mod_path}/build \\
                --with-config=kernel
    make
}

package() {
    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    mv "\${pkgdir}/lib" "\${pkgdir}/usr/"
    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/${kernel_mod_path}/Module.symvers
}
EOF

pkgbuild_cleanup "${spl_pkgbuild_path}/PKGBUILD"
