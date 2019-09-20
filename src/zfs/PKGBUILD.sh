#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_pkgname}"
pkgname=("${zfs_pkgname}" "${zfs_pkgname}-headers")

${zfs_set_commit}
_zfsver="${zfs_pkgver}"
_kernelver="${kernel_version}"
_extramodules="${kernel_mod_path}"

pkgver="\${_zfsver}_\$(echo \${_kernelver} | sed s/-/./g)"
pkgrel=${zfs_pkgrel}
makedepends=(${linux_headers_depends} ${zfs_makedepends})
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
depends=("kmod" "${zfs_utils_pkgname}" ${linux_depends})

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-\${_zfsver} --with-config=kernel \\
                --with-linux=/usr/lib/modules/\${_extramodules}/build \\
                --with-linux-obj=/usr/lib/modules/\${_extramodules}/build
    make
}

package_${zfs_pkgname}() {
    pkgdesc="Kernel modules for the Zettabyte File System."
    install=zfs.install
    provides=("zfs" "spl")
    groups=("${archzfs_package_group}")
    conflicts=("zfs-dkms" "zfs-dkms-git" "zfs-dkms-rc" "spl-dkms" "spl-dkms-git" ${zfs_conflicts})
    ${zfs_replaces}

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    cp -r "\${pkgdir}"/{lib,usr}
    rm -r "\${pkgdir}"/lib

    # Remove src dir
    rm -r "\${pkgdir}"/usr/src
}

package_${zfs_pkgname}-headers() {
    pkgdesc="Kernel headers for the Zettabyte File System."
    provides=("zfs-headers" "spl-headers")
    conflicts=("zfs-headers" "zfs-dkms" "zfs-dkms-git" "zfs-dkms-rc" "spl-dkms" "spl-dkms-git" "spl-headers")

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/\${_extramodules}/Module.symvers
}

EOF

if [[ ! ${archzfs_package_group} =~ -git$ ]] && [[ ! ${archzfs_package_group} =~ -rc$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-rw_semaphore-owner.patch\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-retire-rw_tryupgrade.patch\n    patch -Np1 -i \${srcdir}/linux-5.3-compat-Makefile-subdir-m-no-longer-supported.patch\n}" ${zfs_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
