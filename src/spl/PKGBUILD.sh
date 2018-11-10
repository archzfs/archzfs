#!/bin/bash

cat << EOF > ${spl_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${spl_pkgname}"
pkgname=("${spl_pkgname}" "${spl_pkgname}-headers")

_splver="${spl_pkgver}"
_kernelver="${kernel_version}"
_extramodules="${kernel_mod_path}"

pkgver="\${_splver}_\$(echo \${_kernelver} | sed s/-/./g)"
pkgrel=${spl_pkgrel}
makedepends=(${linux_headers_depends} ${spl_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
license=("GPL")
depends=("kmod" ${linux_depends})

build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin \\
                --with-linux=/usr/lib/modules/\${_extramodules}/build \\
                --with-linux-obj=/usr/lib/modules/\${_extramodules}/build \\
                --with-config=kernel
    make
}

package_${spl_pkgname}() {
    pkgdesc="Solaris Porting Layer kernel modules."
    provides=("spl")
    groups=("${archzfs_package_group}")
    conflicts=("spl-dkms" "spl-dkms-git" ${spl_conflicts})
    ${spl_replaces}

    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    mv "\${pkgdir}/lib" "\${pkgdir}/usr/"

    # Remove src dir
    rm -r "\${pkgdir}"/usr/src
}

package_${spl_pkgname}-headers() {
    pkgdesc="Solaris Porting Layer kernel headers."
    provides=("spl-headers")
    conflicts=("spl-dkms" "spl-dkms-git" "spl-headers")

    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/\${_extramodules}/Module.symvers
}

EOF

pkgbuild_cleanup "${spl_pkgbuild_path}/PKGBUILD"
