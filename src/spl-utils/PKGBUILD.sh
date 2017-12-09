#!/bin/bash

cat << EOF > ${spl_utils_pkgbuild_path}/PKGBUILD
${header}
pkgname="${spl_utils_pkgname}"
pkgver=${spl_pkgver}
pkgrel=${spl_pkgrel}
pkgdesc="Solaris Porting Layer kernel module support files."
arch=("x86_64")
url="http://zfsonlinux.org/"
source=("${spl_src_target}")
sha256sums=("${spl_src_hash}")
groups=("${archzfs_package_group}")
license=("GPL")
provides=("spl-utils")
makedepends=(${spl_makedepends})
conflicts=(${spl_utils_conflicts})
${spl_utils_replaces}

build() {
    cd "${spl_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/bin --with-config=user
    make
}

package() {
    cd "${spl_workdir}"
    make DESTDIR="\${pkgdir}" install
}
EOF

if [[ ${archzfs_package_group} =~ -git$ ]]; then
	sed -i "/^build()/i pkgver() {\n    cd \"${spl_workdir}\"\n    printf \"%s.r%s.%s\" \"\$(git log -n 1 --pretty=format:'%cd' --date=short | sed 's/-/./g')\" \"\$(git rev-list --count HEAD)\" \"\$(git rev-parse --short HEAD)\" \n}" ${spl_utils_pkgbuild_path}/PKGBUILD
fi

pkgbuild_cleanup "${spl_utils_pkgbuild_path}/PKGBUILD"
