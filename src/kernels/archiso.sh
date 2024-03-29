# For build.sh
mode_name="iso"
package_base="archiso-linux"
mode_desc="Select and use the packages for the archiso linux kernel"

# Kernel versions for LTS packages
pkgrel="1"

header="\
# Maintainer: Jan Houben <jan@nexttrex.de>
# Contributor: Jesus Alvarez <jeezusjr at gmail dot com>
#
# This PKGBUILD was generated by the archzfs build scripts located at
#
# http://github.com/archzfs/archzfs
#
# ! WARNING !
#
# The archzfs packages are kernel modules, so these PKGBUILDS will only work with the kernel package they target. In this
# case, the archzfs-archiso-linux packages will only work with the archiso ISO! To have a single PKGBUILD target many kernels
# would make for a cluttered PKGBUILD!
#
# If you have a custom kernel, you will need to change things in the PKGBUILDS. If you would like to have AUR or archzfs repo
# packages for your favorite kernel package built using the archzfs build tools, submit a request in the Issue tracker on the
# archzfs github page.
#"

update_archiso_linux_pkgbuilds() {
    msg "Checking archiso download page for the latest linux kernel version..."
    if ! get_webpage "https://www.archlinux.org/download/" "(?<=Included Kernel:</strong> )[\d\.]+"; then
        exit 1
    fi
    kernel_version="${webpage_output}.arch1-1"
    
    pkg_list=("zfs-archiso-linux")
    kernel_version_full=$(kernel_version_full ${kernel_version})
    kernel_version_pkgver=$(kernel_version_no_hyphen ${kernel_version})
    kernel_version_major=${kernel_version%-*}
    kernel_mod_path="${kernel_version_full/.arch/-arch}-ARCH"
    archzfs_package_group="archzfs-archiso-linux"
    zfs_utils_pkgname="zfs-utils=\${_zfsver}"
    zfs_pkgname="zfs-archiso-linux"
    zfs_pkgbuild_path="packages/${kernel_name}/${zfs_pkgname}"
    zfs_src_target="https://github.com/openzfs/zfs/releases/download/zfs-\${_zfsver}/zfs-\${_zfsver}.tar.gz"
    zfs_workdir="\${srcdir}/zfs-\${_zfsver}"
    linux_depends="\"linux=\${_kernelver}\""
    linux_headers_depends="\"linux-headers=\${_kernelver}\""
}
