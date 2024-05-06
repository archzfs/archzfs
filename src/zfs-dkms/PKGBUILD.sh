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
source=("${zfs_src_target}" "enforce-kernel-max-version.patch")
sha256sums=("${zfs_src_hash}" "8f0019f996d6d9cd3766b8d0faf5df45e9cb256fdf5e0d862a4cdb3b209f7e8e")
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

if [[ ! ${archzfs_package_group} =~ -rc$ ]] && [[ ! ${archzfs_package_group} =~ -git$ ]]; then
    sed -E -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/enforce-kernel-max-version.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
