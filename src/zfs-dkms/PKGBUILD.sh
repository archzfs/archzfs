#!/bin/bash

# remove spl from git packages workaround
spl_dependency=""
if [[ -n "${spl_pkgname}" ]]; then
    spl_dependency="'${spl_pkgname}' "
fi

cat << EOF > ${zfs_dkms_pkgbuild_path}/PKGBUILD
${header}
pkgname="${zfs_pkgname}"
pkgdesc="Kernel modules for the Zettabyte File System."
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
makedepends=(${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}" 
        "upstream-ac09630-Fix-zpl_mount-deadlock.patch"
        "upstream-9f64c1e-Linux-4.18-compat-inode-timespec_timespec64.patch"
        "upstream-9161ace-Linux-compat-4.18-check_disk_size_change.patch")
sha256sums=("${zfs_src_hash}" 
            "1799f6f7b2a60a23b66106c9470414628398f6bfc10da3d0f41c548bba6130e8"
            "03ed45af40850c3a51a6fd14f36c1adc06501c688a67afb13db4fded6ec9db1d"
            "afbde4a2507dff989404665dbbdfe18eecf5aba716a6513902affa0e4cb033fe")
license=("CDDL")
depends=(${spl_dependency}"${zfs_utils_pkgname}" "lsb-release")
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

if [[ ! ${archzfs_package_group} =~ -git$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/upstream-ac09630-Fix-zpl_mount-deadlock.patch\n    patch -Np1 -i \${srcdir}/upstream-9f64c1e-Linux-4.18-compat-inode-timespec_timespec64.patch\n    patch -Np1 -i \${srcdir}/upstream-9161ace-Linux-compat-4.18-check_disk_size_change.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
