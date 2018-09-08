#!/bin/bash

# remove spl from git packages workaround
spl_dependency=""
if [[ -n "${spl_pkgname}" ]]; then
    spl_dependency="'${spl_pkgname}' "
fi

cat << EOF > ${zfs_dkms_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_pkgname}"
${zfs_set_commit}
pkgdesc="Kernel modules for the Zettabyte File System."
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
makedepends=(${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
license=("CDDL")
depends=(${spl_dependency}"${zfs_utils_pkgname}" "lsb-release" "dkms")
provides=("zfs")
groups=("${archzfs_package_group}")
conflicts=(${zfs_conflicts} ${zfs_conflicts_all} ${zfs_headers_conflicts_all})
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

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
