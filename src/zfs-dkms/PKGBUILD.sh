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
        "linux-5.8-compat-__vmalloc.patch"
)
sha256sums=("${zfs_src_hash}"
            "264728b1e4f7f7509fde76b6049c93033aa813ae6324f37609ff95db8c9e8959"
)
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
    sed -E -i "/^build()/i prepare() {\n\
    cd \"${zfs_workdir}\"\n\
    patch -Np1 -i \${srcdir}/linux-5.8-compat-__vmalloc.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
