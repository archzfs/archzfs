#!/bin/bash

# spl is included in git packages (workaround till zfs 0.8)
spl_dependency=""
git_provides=""
git_conflicts=""
if [[ ${archzfs_package_group} =~ -git$ ]] || [[ ${archzfs_package_group} =~ -rc$ ]]; then
    git_provides+=' "spl" "spl-headers"'
    git_conflicts+=' "spl" "spl-headers"'
else
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
source=("${zfs_src_target}"
        "upstream-4f981f6-additional-fixes-for-current_kernel_time-in-4.20.patch")
sha256sums=("${zfs_src_hash}"
            "6f27c3dae57c424e06aec31df6c1e1a821e547aa4e933f2f9b894b5e6762b52d")
license=("CDDL")
depends=(${spl_dependency}"${zfs_utils_pkgname}" "lsb-release" "dkms")
provides=("zfs" "zfs-headers"${git_provides})
groups=("${archzfs_package_group}")
conflicts=("zfs" "zfs-headers"${git_conflicts})
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
    sed -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/upstream-4f981f6-additional-fixes-for-current_kernel_time-in-4.20.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
