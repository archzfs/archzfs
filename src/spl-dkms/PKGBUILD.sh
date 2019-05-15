#!/bin/bash

cat << EOF > ${spl_dkms_pkgbuild_path}/PKGBUILD
${header}
pkgname="${spl_pkgname}"
pkgdesc="Solaris Porting Layer kernel modules."
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}
makedepends=(${spl_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}"
        "linux-5.1-compat-drop-ULLONG_MAX-and-LLONG_MAX-definitions.patch"
        "linux-5.1-compat-get-ds-removed.patch")
sha256sums=("${spl_src_hash}"
            "f110bd86a81602e531dda943cf0d066f09f3d58c297159ea285957ce28f0f0c1"
            "d4a6c27aea521cf5635c1b9f679633c068b024606f634d5e6bf1a7b97db486c4")
license=("GPL")
depends=("dkms")
provides=("spl" "spl-headers")
groups=("${archzfs_package_group}")
conflicts=("spl" "spl-headers")
${spl_replaces}

prepare() {
    cd "${spl_workdir}"
    patch -Np1 -i \${srcdir}/linux-5.1-compat-drop-ULLONG_MAX-and-LLONG_MAX-definitions.patch
    patch -Np1 -i \${srcdir}/linux-5.1-compat-get-ds-removed.patch
}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
}

package() {
    dkmsdir="\${pkgdir}/usr/src/spl-${spl_mod_ver}"
    install -d "\${dkmsdir}"
    cp -a ${spl_workdir}/. \${dkmsdir}

    cd "\${dkmsdir}"
    find . -name ".git*" -print0 | xargs -0 rm -fr --
    scripts/dkms.mkconf -v ${spl_mod_ver} -f dkms.conf -n spl
    chmod g-w,o-w -R .
}

EOF

pkgbuild_cleanup "${spl_dkms_pkgbuild_path}/PKGBUILD"
