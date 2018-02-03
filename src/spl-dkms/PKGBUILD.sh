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
        "60-spl-dkms-install.hook"
        "spl-dkms-alpm-hook"
        "0001-Linux-4.15-compat-timer-updates.patch")
sha256sums=("${spl_src_hash}"
            "15f71a9ceccf795cdac65743bee338e9987ec77e217721f32d55099be6ecf3d7"
            "836002f310b9e1d4b1a0e5c30d5b0ac5aa120d335b3ea223228a0b9f037ef8b8"
            "3c882c05ef76200e60713541ecfcac8b17fd043e85c35ebb453e9a47bfb13278")
license=("GPL")
depends=("${spl_utils_pkgname}" "dkms")
provides=("spl")
groups=("${archzfs_package_group}")
conflicts=(${spl_conflicts} ${spl_conflicts_all} ${spl_headrs_conflicts_all})
${spl_replaces}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
}

package() {
    # install alpm hook
    install -D -m 644 \${srcdir}/60-spl-dkms-install.hook \${pkgdir}/usr/share/libalpm/hooks/60-spl-dkms-install.hook
    install -D -m 755 \${srcdir}/spl-dkms-alpm-hook \${pkgdir}/usr/lib/dkms/spl-dkms-alpm-hook
    
    dkmsdir="\${pkgdir}/usr/src/spl-${spl_mod_ver}"
    install -d "\${dkmsdir}"
    cp -a ${spl_workdir}/. \${dkmsdir}

    cd "\${dkmsdir}"
    find . -name ".git*" -print0 | xargs -0 rm -fr --
    scripts/dkms.mkconf -v ${spl_mod_ver} -f dkms.conf -n spl
    chmod g-w,o-w -R .
}

EOF

if [[ ! ${archzfs_package_group} =~ -git$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${spl_workdir}\"\n    patch -Np1 -i \${srcdir}/0001-Linux-4.15-compat-timer-updates.patch\n}" ${spl_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${spl_dkms_pkgbuild_path}/PKGBUILD"
