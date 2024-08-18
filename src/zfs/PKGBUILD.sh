#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_pkgname}"
pkgname=("${zfs_pkgname}" "${zfs_pkgname}-headers")

${zfs_set_commit}
_zfsver="${zfs_pkgver}"
_kernelver="${kernel_version}"
_kernelver_full="${kernel_version_full}"
_extramodules="${kernel_mod_path}"

pkgver="\${_zfsver}_\$(echo \${_kernelver} | sed s/-/./g)"
pkgrel=${zfs_pkgrel}
makedepends=(${linux_headers_depends} ${zfs_makedepends})
arch=("x86_64")
url="https://openzfs.org/"
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
license=("CDDL")
depends=("kmod" "${zfs_utils_pkgname}" ${linux_depends})

prepare() {
    cd "${zfs_workdir}"
    sed -ri 's|(KERNELRELEASE=@LINUX_VERSION@)|\1 DEPMOD=/doesnt/exist|' module/Makefile.in
}

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/usr/lib/udev \\
                --libexecdir=/usr/lib --with-config=kernel \\
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
    mkdir -p "\${pkgdir}"/usr/share/zfs
    make DESTDIR="\${pkgdir}" INSTALL_MOD_PATH=\${pkgdir}/usr INSTALL_MOD_STRIP=1 install
    rm -r "\${pkgdir}"/usr/share/zfs

    # Remove src dir
    rm -r "\${pkgdir}"/usr/src
}

package_${zfs_pkgname}-headers() {
    pkgdesc="Kernel headers for the Zettabyte File System."
    provides=("zfs-headers" "spl-headers")
    conflicts=("zfs-headers" "zfs-dkms" "zfs-dkms-git" "zfs-dkms-rc" "spl-dkms" "spl-dkms-git" "spl-headers")

    cd "${zfs_workdir}"
    mkdir -p "\${pkgdir}"/usr/share/zfs
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}"/usr/share/zfs
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/\${_extramodules}/Module.symvers
}

EOF

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
