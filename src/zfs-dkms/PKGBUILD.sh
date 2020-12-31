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
              "autoconf-270-compatibility.patch")
sha256sums=("${zfs_src_hash}"
                        "dc82ee4e62f76b68d972423909c38ced28dea876c6ef4f19037a24a8dbb2fff5")
license=("CDDL")
depends=("${zfs_utils_pkgname}" "lsb-release" "dkms")
provides=("zfs" "zfs-headers" "spl" "spl-headers")
groups=("${archzfs_package_group}")
conflicts=("zfs" "zfs-headers" "spl" "spl-headers")
${zfs_replaces}

prepare() {
    cd "${zfs_workdir}"
    patch -Np1 -i \${srcdir}/autoconf-270-compatibility.patch
}

build() {
    cd "${zfs_workdir}"
    ./autogen.sh || true
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

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
