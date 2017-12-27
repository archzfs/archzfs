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
        "0001-Linux-4.15-compat-timer-updates.patch")
sha256sums=("${spl_src_hash}"
            "3c882c05ef76200e60713541ecfcac8b17fd043e85c35ebb453e9a47bfb13278")
license=("GPL")
depends=("${spl_utils_pkgname}" "kmod" ${linux_depends})

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
    install=spl.install
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

if [[ ! ${archzfs_package_group} =~ -git$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${spl_workdir}\"\n    patch -Np1 -i \${srcdir}/0001-Linux-4.15-compat-timer-updates.patch\n}" ${spl_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${spl_pkgbuild_path}/PKGBUILD"
