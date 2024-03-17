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
url="https://openzfs.org/"
source=("${zfs_src_target}" "enforce-kernel-max-version.patch" "linux-6.8-compat.patch" "kernel-6.8-meta.patch")
sha256sums=("${zfs_src_hash}" "c5a9f546638c706844d5aff99f40366db1684679c3318d3a4093e0746748a711" "b875c877069a4c75c7b2b4b22d048e66f415b86f862ef6b3b83d3524694cc973" "1bc3b2e79e481b1bf41e78f9d142de8e97326288ecdc97f8db65496b7c4fd63b")
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
}


EOF

if [[ ! ${archzfs_package_group} =~ -rc$ ]]; then
    sed -E -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/enforce-kernel-max-version.patch\n    patch -Np1 -i \${srcdir}/linux-6.8-compat.patch\n    patch -Np1 -i \${srcdir}/kernel-6.8-meta.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
