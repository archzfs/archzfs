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
              "autoconf-270-compatibility.patch")
sha256sums=("${zfs_src_hash}"
                        "dc82ee4e62f76b68d972423909c38ced28dea876c6ef4f19037a24a8dbb2fff5")
license=("CDDL")
depends=("kmod" "${zfs_utils_pkgname}" ${linux_depends})

build() {
    cd "${zfs_workdir}"
    ./autogen.sh || true
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
    make DESTDIR="\${pkgdir}" INSTALL_MOD_PATH=/usr install

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
    sed -E -i "/^build()/i prepare() {\n\
    cd \"${zfs_workdir}\"\n\
    patch -Np1 -i \${srcdir}/autoconf-270-compatibility.patch\n}" ${zfs_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
