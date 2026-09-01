#!/bin/bash

cat << EOF > ${zfs_utils_pkgbuild_path}/PKGBUILD
${header}
pkgbase="${zfs_utils_pkgname}"
pkgname=("${zfs_utils_pkgname}" "${zfs_tests_pkgname}")
${zfs_set_commit}
pkgver=${zfs_pkgver}
pkgrel=${zfs_pkgrel}
makedepends=("python" "python-setuptools" "python-cffi" "libaio" ${zfs_makedepends})
arch=("x86_64")
url="http://openzfs.org/"
source=("${zfs_src_target}"
        "zfs-utils.initcpio.install"
        "zfs-utils.initcpio.hook"
        "zfs-utils.initcpio.zfsencryptssh.install")
sha256sums=("${zfs_src_hash}"
            "${zfs_initcpio_install_hash}"
            "${zfs_initcpio_hook_hash}"
            "${zfs_initcpio_zfsencryptssh_install}")
license=("CDDL")

build() {
    cd "${zfs_workdir}"
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --with-mounthelperdir=/usr/bin \\
                --libdir=/usr/lib --datadir=/usr/share --includedir=/usr/include \\
                --with-udevdir=/usr/lib/udev --libexecdir=/usr/lib \\
                --with-config=user --enable-systemd --enable-pyzfs \\
                --with-zfsexecdir=/usr/lib/zfs --localstatedir=/var --without-libunwind
    make
}

package_${zfs_utils_pkgname}() {
    pkgdesc="Kernel module support files for the Zettabyte File System."
    depends=(
        "bash"
        "coreutils"
        "diffutils"
        "findutils"
        "gawk"
        "glibc"
        "grep"
        "inetutils"
        "kmod"
        "libgcc"
        "libtirpc"
        "openssl"
        "pam"
        "sed"
        "systemd"
        "systemd-libs"
        "util-linux"
        "util-linux-libs"
        "zlib"
    )
    optdepends=(
        "curl: HTTP(S) key locations and ZED web notifications"
        "dracut: dracut initramfs integration"
        "lsscsi: vdev_id SCSI device identification"
        "mkinitcpio: mkinitcpio initramfs integration"
        "multipath-tools: vdev_id multipath device identification"
        "nfs-utils: NFS sharing"
        "psmisc: zfsencryptssh initcpio hook"
        "python: pyzfs and Python utilities"
        "python-cffi: pyzfs"
        "s-nail: ZED email notifications"
        "samba: SMB sharing"
        "sg3_utils: vdev_id SCSI enclosure identification"
        "smartmontools: SMART health information in zpool status"
        "sudo: privilege escalation for SMART zpool status columns"
        "sysstat: I/O statistics in zpool status"
    )
    groups=("${archzfs_package_group}")
    provides=("zfs-utils" "spl-utils")
    install=zfs-utils.install
    ${zfs_utils_conflicts}
    ${zfs_utils_replaces}
    backup=('etc/zfs/zed.d/zed.rc' 'etc/default/zfs' 'etc/modules-load.d/zfs.conf')

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install

    # Remove uneeded files
    rm -r "\${pkgdir}"/etc/init.d
    rm -r "\${pkgdir}"/usr/share/initramfs-tools
    rm -r "\${pkgdir}"/usr/lib/modules-load.d

    # Autoload the zfs module at boot
    mkdir -p "\${pkgdir}/etc/modules-load.d"
    printf "%s\n" "zfs" > "\${pkgdir}/etc/modules-load.d/zfs.conf"

    # Install the support files
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.hook "\${pkgdir}"/usr/lib/initcpio/hooks/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.install "\${pkgdir}"/usr/lib/initcpio/install/zfs
    install -D -m644 "\${srcdir}"/zfs-utils.initcpio.zfsencryptssh.install "\${pkgdir}"/usr/lib/initcpio/install/zfsencryptssh
    install -D -m644 contrib/bash_completion.d/zfs "\${pkgdir}"/usr/share/bash-completion/completions/zfs

    # Remove the test suite packaged by the sibling child
    rm -r "\${pkgdir}"/usr/share/zfs/zfs-tests
    rm -r "\${pkgdir}"/usr/share/zfs/test-runner
    rm -r "\${pkgdir}"/usr/share/zfs/runfiles
    rm "\${pkgdir}"/usr/share/zfs/*.sh
}

package_${zfs_tests_pkgname}() {
    pkgdesc="Test suite for the Zettabyte File System."
    depends=(
        "acl"
        "attr"
        "bash"
        "bc"
        "binutils"
        "bzip2"
        "coreutils"
        "cpio"
        "device-mapper"
        "diffutils"
        "e2fsprogs"
        "findutils"
        "fio"
        "gawk"
        "glibc"
        "grep"
        "gzip"
        "kmod"
        "ksh"
        "libaio"
        "lsscsi"
        "mdadm"
        "openssl"
        "parted"
        "procps-ng"
        "python"
        "python-cffi"
        "sed"
        "shadow"
        "sudo"
        "sysstat"
        "systemd"
        "tar"
        "util-linux"
        "which"
        "xxhash"
        "zfs"
        "${zfs_utils_pkgname}=\${pkgver}-\${pkgrel}"
    )
    optdepends=(
        "cryptsetup: LUKS tests"
        "jq: JSON-output tests"
        "nfs-utils: NFS sharing tests"
        "openssh: remote NFS performance tests"
        "perf: performance profiling"
        "rsync: slog replay and directory comparison tests"
        "samba: SMB sharing tests"
        "xfsprogs: XFS loopback interoperability test"
    )
    ${zfs_tests_relations}

    cd "${zfs_workdir}"
    make DESTDIR="\${pkgdir}" install

    find "\${pkgdir}" -mindepth 1 -maxdepth 1 ! -name usr -exec rm -rf {} +
    find "\${pkgdir}/usr" -mindepth 1 -maxdepth 1 ! -name share -exec rm -rf {} +
    find "\${pkgdir}/usr/share" -mindepth 1 -maxdepth 1 ! -name zfs -exec rm -rf {} +
    find "\${pkgdir}/usr/share/zfs" -mindepth 1 -maxdepth 1 ! -name zfs-tests ! -name test-runner ! -name runfiles ! -name "*.sh" -exec rm -rf {} +
}
EOF

pkgbuild_cleanup "${zfs_utils_pkgbuild_path}/PKGBUILD"
