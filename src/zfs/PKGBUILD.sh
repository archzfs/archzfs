#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_pkgname}"
pkgname=("${zfs_pkgname}" "${zfs_pkgname}-headers")
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
makedepends=(${linux_headers_depends} ${zfs_makedepends})
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
license=("CDDL")
depends=("kmod" "${spl_pkgname}" "${zfs_utils_pkgname}" ${linux_depends})

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --libdir=/usr/lib \\
                --datadir=/usr/share --includedir=/usr/include --with-udevdir=/lib/udev \\
                --libexecdir=/usr/lib/zfs-${zol_version} --with-config=kernel \\
                --with-linux=/usr/lib/modules/${kernel_mod_path}/build \\
                --with-linux-obj=/usr/lib/modules/${kernel_mod_path}/build
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
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/${kernel_mod_path}/Module.symvers
}

EOF

if [[ ${archzfs_package_group} =~ -git$ ]]; then
	sed -i "/^build()/i pkgver() {\n    cd \"${zfs_workdir}\"\n    printf \"%s.r%s.%s\" \"\$(git log -n 1 --pretty=format:'%cd' --date=short | sed 's/-/./g')\" \"\$(git rev-list --count HEAD)\" \"\$(git rev-parse --short HEAD)\".${kernel_version_full_pkgver} \n}" ${zfs_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
