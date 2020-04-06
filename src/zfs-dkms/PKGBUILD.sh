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
        "linux-5.5-compat-blkg_tryget.patch"
        "linux-5.6-compat-struct-proc_ops.patch"
        "linux-5.6-compat-timestamp_truncate.patch"
        "linux-5.6-compat-ktime_get_raw_ts64.patch"
        "linux-5.6-compat-time_t.patch")
sha256sums=("${zfs_src_hash}"
            "daae58460243c45c2c7505b1d88dcb299ea7d92bcf3f41d2d30bc213000bb1da"
            "05ca889a89b1e57d55c1b7d4d3013398a3e5a69d0fad27278aad701f0bb6e802"
            "5ad4393b334a8f685212f47b44e98dc468c70214ee5dbbab24cc95c4f310ae39"
            "7c6ebee72d864160b376fc18017c81f499f177b7d9265f565de859139805a277"
            "06f7ade5adcbfe77cb234361f8b2aca6d6e78fcd136da6d3a70048b5e92c62bb")
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
    patch -Np1 -i \${srcdir}/linux-5.5-compat-blkg_tryget.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-struct-proc_ops.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-timestamp_truncate.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-time_t.patch\n\
    patch -Np1 -i \${srcdir}/linux-5.6-compat-ktime_get_raw_ts64.patch\n}" ${zfs_dkms_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_dkms_pkgbuild_path}/PKGBUILD"
