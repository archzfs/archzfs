#!/bin/bash

cat << EOF > ${spl_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${spl_pkgname}"
pkgname=("${spl_pkgname}" "${spl_pkgname}-headers")
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}
makedepends=(${linux_headers_depends} ${spl_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}"
        "upstream-eb1f893-Linux-4.18-compat-inode-timespec_timespec64.patch")
sha256sums=("${spl_src_hash}"
            "72d1b4103c0b52e0fc2b7135485e346c898289ab42f7bc1ae2748d072a360f66")
license=("GPL")
depends=("${spl_utils_pkgname}" "kmod" ${linux_depends})

prepare() {
    cd "${spl_workdir}"
    patch -Np1 -i \${srcdir}/upstream-eb1f893-Linux-4.18-compat-inode-timespec_timespec64.patch
}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/${kernel_mod_path}/build \\
                --with-linux-obj=/usr/lib/modules/${kernel_mod_path}/build \\
                --with-config=kernel
    make
}

package_${spl_pkgname}() {
    pkgdesc="Solaris Porting Layer kernel modules."
    provides=("spl")
    groups=("${archzfs_package_group}")
    conflicts=(${spl_conflicts})
    ${spl_replaces}

    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    mv "\${pkgdir}/lib" "\${pkgdir}/usr/"

    # Remove src dir
    rm -r "\${pkgdir}"/usr/src
}

package_${spl_pkgname}-headers() {
    pkgdesc="Solaris Porting Layer kernel headers."
    conflicts=(${spl_headers_conflicts})

    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/${kernel_mod_path}/Module.symvers
}

EOF

pkgbuild_cleanup "${spl_pkgbuild_path}/PKGBUILD"
