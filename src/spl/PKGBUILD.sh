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
source=("${spl_src_target}"
        "linux-5.1-compat-drop-ULLONG_MAX-and-LLONG_MAX-definitions.patch"
        "linux-5.1-compat-get-ds-removed.patch")
sha256sums=("${spl_src_hash}"
            "f110bd86a81602e531dda943cf0d066f09f3d58c297159ea285957ce28f0f0c1"
            "d4a6c27aea521cf5635c1b9f679633c068b024606f634d5e6bf1a7b97db486c4")
license=("GPL")
depends=("kmod" ${linux_depends})

prepare() {
    cd "${spl_workdir}"
    patch -Np1 -i \${srcdir}/linux-5.1-compat-drop-ULLONG_MAX-and-LLONG_MAX-definitions.patch
    patch -Np1 -i \${srcdir}/linux-5.1-compat-get-ds-removed.patch
}

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
    conflicts=("spl-dkms" "spl-dkms-git" "spl-dkms-rc" "spl-headers")

    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/spl-*/\${_extramodules}/Module.symvers
}

EOF

pkgbuild_cleanup "${spl_pkgbuild_path}/PKGBUILD"
