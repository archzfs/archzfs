#!/bin/bash

cat << EOF > ${spl_utils_pkgbuild_path}/PKGBUILD
${header}
pkgname="${spl_utils_pkgname}"
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}
pkgdesc="Solaris Porting Layer kernel module support files."
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}"
        "spl-utils.hostid")
sha256sums=("${spl_src_hash}"
            "${spl_hostid_hash}")
groups=("${archzfs_package_group}")
license=("GPL")
provides=("${spl_utils_pkgname}")
${spl_makedepends}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin --with-config=user
    make
}

package() {
    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    install -D -m644 "\${srcdir}"/spl-utils.hostid "\${pkgdir}"/etc/hostid
}
EOF
