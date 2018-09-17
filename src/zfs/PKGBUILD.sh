#!/bin/bash

# spl is included in git packages (workaround till zfs 0.8)
spl_dependency=""
git_provides=""
git_provides_headers=""
git_conflicts=""
git_conflicts_headers=""
if [[ ${archzfs_package_group} =~ -git$ ]]; then
    git_provides+=' "spl"'
    git_provides_headers+=' "spl-headers"'
    git_conflicts+=' "spl-dkms" "spl-dkms-git"'
    git_conflicts_headers+=' "spl-dkms" "spl-dkms-git" "spl-headers"'
else
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
source=("${zfs_src_target}")
sha256sums=("${zfs_src_hash}")
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
    provides=("zfs"${git_provides})
    groups=("${archzfs_package_group}")
    conflicts=("zfs-dkms" "zfs-dkms-git" ${zfs_conflicts}${git_conflicts})
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
    provides=("zfs-headers"${git_provides_headers})
    conflicts=("zfs-headers" "zfs-dkms" "zfs-dkms-git"${git_conflicts_headers})

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install
    rm -r "\${pkgdir}/lib"

    # Remove reference to \${srcdir}
    sed -i "s+\${srcdir}++" \${pkgdir}/usr/src/zfs-*/\${_extramodules}/Module.symvers
}

EOF

pkgbuild_cleanup "${zfs_pkgbuild_path}/PKGBUILD"
