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
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
license=("GPL")
depends=("${spl_utils_pkgname}" "dkms")
provides=("spl" "spl-headers")
groups=("${archzfs_package_group}")
conflicts=("spl" "spl-headers")
${spl_replaces}

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
