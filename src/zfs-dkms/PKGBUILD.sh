#!/bin/bash

cat << EOF > ${zfs_dkms_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_pkgname}"
${zfs_set_commit}
pkgdesc="Kernel modules for the Zettabyte File System."
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
makedepends=(${zfs_makedepends})
arch=("x86_64")
url="https://zfsonlinux.org/"
source=("${zfs_src_target}"
        "linux-5.3-compat-rw_semaphore-owner.patch"
        "linux-5.3-compat-retire-rw_tryupgrade.patch"
        "linux-5.3-compat-Makefile-subdir-m-no-longer-supported.patch")
sha256sums=("${zfs_src_hash}"
            "c65c950abda42fb91fb99c6c916a50720a522c53e01a872f9310a4719bae9e2a"
            "19f798a29c00874874751880f1146c5849b8ebdb6233d8ae923f9fdd4661de19"
            "6c4627875dd1724f64a196ea584812c99635897dc31cb23641f308770289059a")
license=("CDDL")
depends=("${zfs_utils_pkgname}" "lsb-release" "dkms")
provides=("zfs" "zfs-headers" "spl" "spl-headers")
groups=("${archzfs_package_group}")
conflicts=("zfs" "zfs-headers" "spl" "spl-headers")
${zfs_replaces}

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
}

package() {
    dkmsdir="\${pkgdir}/usr/src/zfs-${zfs_mod_ver}"
    install -d "\${dkmsdir}"
    cp -a ${zfs_workdir}/. \${dkmsdir}

    cd "\${dkmsdir}"
    find . -name ".git*" -print0 | xargs -0 rm -fr --
    scripts/dkms.mkconf -v ${zfs_mod_ver} -f dkms.conf -n zfs
    chmod g-w,o-w -R .
}


EOF

if [[ ! ${archzfs_package_group} =~ -git$ ]] && [[ ! ${archzfs_package_group} =~ -rc$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-rw_semaphore-owner.patch\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-retire-rw_tryupgrade.patch\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-Makefile-subdir-m-no-longer-supported.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
