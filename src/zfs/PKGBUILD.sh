#!/bin/bash

# remove spl from git packages workaround
spl_dependency=""
if [[ -n "${spl_pkgname}" ]]; then
    spl_dependency="'${spl_pkgname}' "
fi

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
depends=("kmod" ${spl_dependency}"${zfs_utils_pkgname}" ${linux_depends})

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-\${zfsver} --with-config=kernel \\
                --with-linux=/usr/lib/modules/\${_extramodules}/build \\
                --with-linux-obj=/usr/lib/modules/\${_extramodules}/build
    make
}

package_${zfs_pkgname}() {
    pkgdesc="Kernel modules for the Zettabyte File System."
    install=zfs.install
    provides=("zfs")
    groups=("${archzfs_package_group}")
    conflicts=(${zfs_conflicts})
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
    conflicts=(${zfs_headers_conflicts})

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/\${_extramodules}/Module.symvers
}

EOF

if [[ ! ${archzfs_package_group} =~ -git$ ]]; then
    sed -i "/^build()/i prepare() {\n    cd \"${zfs_workdir}\"\n    patch -Np1 -i \${srcdir}/upstream-ac09630-Fix-zpl_mount-deadlock.patch\n    patch -Np1 -i \${srcdir}/upstream-9f64c1e-Linux-4.18-compat-inode-timespec_timespec64.patch\n    patch -Np1 -i \${srcdir}/upstream-9161ace-Linux-compat-4.18-check_disk_size_change.patch\n}" ${zfs_pkgbuild_path}/PKGBUILD
fi
 
pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
