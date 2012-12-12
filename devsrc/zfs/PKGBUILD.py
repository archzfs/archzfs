# PKGBUILD.py for Arch ZFS
# Maintainer: Jesus Alvarez <jeezusjr@gmail.com>
# Created: Fri Oct 26 12:56:02 PDT 2012
# Modified: Tue Dec 04 23:31:02 PST 2012
#
# This is the PKGBUILD input file for the arch-zfs packaging project.
# For more information on how to use this file, please read the "hacking.rst"
# developer documentation.
#
# This file is meant to be used with build.py
#
# Varibles provide by build.py:
#
# $PKGNAMES:
# $SOURCE_FILES:
# $BUILD_CONF:
# $SOURCE_NAME:

import subprocess

LOG_MESSAGE = 'Starting the Arch ZFS Build System...'
HELP_MESSAGE = 'Arch ZFS Package Building System'

# AUR should be the separate packages of SPLIT
AUR = ('spl-utils', 'spl', 'zfs-utils', 'zfs')
SPLIT = ('spl-split', 'zfs-split')

# GROUPS are all the possible package configurations that could be built.
GROUPS = {'aur': {'packages': AUR,
                  'sources': True,
                  'build': False,
                  'repackage': False,
                  'repo': False, },
          'split': {'packages': SPLIT,
                    'sources': True,
                    'build': True,
                    'repackage': False,
                    'repo': False, },
         }

# SOURCE_VER is the version of the software we are building. This string will
# be used when referring to the build directory in the PKGBUILDs. This number
# is usually the upstream version number contained within the name of the
# downloaded sources. PACKAGE_VER is used in the PKGBUILD as the package
# version number.
SOURCE_VER = '0.6.0-rc12'
PACKAGE_VER = SOURCE_VER.replace('-', '_')

# PACKAGE_REL will be used as pkgrel in the PKGBUILD.
PACKAGE_REL = 6

# The file names to the upstream sources. build.py will match the length of the
# following keys to package names. So if the package is 'spl-utils' then it
# will match 'spl' in the key below and that will be the source used in the
# PKGBUILD. The files are downloaded and saved to the sources directory in the
# same directory as PKGBUILD.py.
SOURCE_URLS = {
    'spl': 'http://github.com/downloads/zfsonlinux/spl/spl-' + SOURCE_VER + '.tar.gz',
    'zfs': 'http://github.com/downloads/zfsonlinux/zfs/zfs-' + SOURCE_VER + '.tar.gz'
}

# Specify extra dependencies here
_linux_ver = '3.6.9'
SPL_DEPENDS = "'linux={}'".format(_linux_ver)
SPL_MAKEDEPENDS = "'linux-headers={}'".format(_linux_ver)
ZFS_DEPENDS = SPL_DEPENDS
ZFS_MAKEDEPENDS = SPL_MAKEDEPENDS

# The last few constants are the sections of a PKGBUILD. By default, these
# constants, when combined together, take the shape of a split package.  Each
# package defined in GROUPS above must have an accompanying constant. Use
# underscores ('_') instead of hyphens ('-') when defining the package
# constants. Finally, these constants must also be defined as raw strings
# beginning with 'r'.

BODY = r"""
# Maintainer: Jesus Alvarez <jeezusjr at gmail dot com>
# Contributor: Kyle Fuller <inbox at kylefuller dot co dot uk>

pkgname=($PKGNAMES)
pkgver=$PACKAGE_VER
pkgrel=$PACKAGE_REL
arch=('x86_64')
url='http://zfsonlinux.org/'
source=($SOURCE_FILES)
groups=('archzfs')
md5sums=('97222567144e2987bb18cd1f83fd6173' spl-0.6.0-rc12.tar.gz
         'a54f0041a9e15b050f25c463f1db7449' spl-utils.hostid
         '99697389f4107ec073edfdf0efd14249' spl.install
         '85435c100d9c1dadad7b961c3cb965f6' zfs-0.6.0-rc11.tar.gz
         '6524f2c20fe9ad33a97879981e5c9a45' zfs-0.6.0-rc12.tar.gz
         '3e1c4a29c4f7d590e6a3041f2c61d6ff' zfs-utils.bash-completion
         '105fe46115c6fc6a335399c74bd58289' zfs-utils.initcpio.hook
         'b5c75ddf052d6c167459674013811885' zfs-utils.initcpio.install
         '161e6a5f5f314c9308b4a4565c01fe45' zfs-utils.service
         '7ac100ebe01cc26da63a06effb2c0405' zfs.install
)
spl-all:: license=('GPL')
zfs-all:: license=('CDDL')
spl:: install=spl.install
zfs:: install=zfs.install"""

BUILD = r"""
build() {
  git:: cd "$$srcdir"
  git:: msg "Connecting to GIT server...."

  git:: if [[ -d "$GITNAME" ]]; then
  git::   cd "$GITNAME" && git pull origin
  git::   msg "The local files are updated."
  git:: else
  git::   git clone "$GITROOT" "$GITNAME"
  git:: fi

  git:: msg "GIT checkout done or server timeout"
  git:: msg "Starting build..."

  git:: rm -rf "$$srcdir/$GITNAME-build"
  git:: git clone "$$srcdir/$GITNAME" "$$srcdir/$GITNAME-build"
  git:: cd "$$srcdir/$GITNAME-build"

  cd $${srcdir}/$SOURCE_NAME
  ./autogen.sh
  spl-all:: ./configure --prefix=/usr --libdir=/usr/lib --sbindir=/usr/sbin \
  zfs-all:: ./configure --prefix=/usr \
  zfs-all::             --sysconfdir=/etc \
  zfs-all::             --sbindir=/usr/sbin \
  zfs-all::             --libdir=/usr/lib \
  zfs-all::             --datadir=/usr/share \
  zfs-all::             --includedir=/usr/include \
  zfs-all::             --with-udevdir=/lib/udev \
  zfs-all::             --libexecdir=/usr/lib/$SOURCE_NAME \
              --with-config=$BUILD_CONF
  make
}"""

SPL_UTILS = r"""
package_spl-utils() {
  pkgdesc='Solaris Porting Layer kernel module support files.'

  cd $${srcdir}/$SOURCE_NAME
  make DESTDIR=$${pkgdir} install

  split:: # Remove uneeded files
  split:: rm -r $${pkgdir}/{lib,usr/src}

  install -D -m644 $${srcdir}/spl-utils.hostid $${pkgdir}/etc/hostid
}"""

SPL = r"""
package_spl() {
  pkgdesc='Solaris Porting Layer kernel modules.'
  depends=('spl-utils=$PACKAGE_VER' $SPL_DEPENDS)
  makedepends=($SPL_MAKEDEPENDS)

  cd $${srcdir}/$SOURCE_NAME
  make DESTDIR=$${pkgdir} install

  # move module tree /lib -> /usr/lib
  cp -r $${pkgdir}/{lib,usr}
  rm -r $${pkgdir}/lib

  split:: # Remove uneeded files
  split:: rm -r $${pkgdir}/usr/sbin
}"""

ZFS_UTILS = r"""
package_zfs-utils() {
  pkgdesc="Kernel module support files for the Zettabyte File System."
  depends=('spl=$PACKAGE_VER' $ZFS_DEPENDS)
  makedepends=($ZFS_MAKEDEPENDS)

  cd $${srcdir}/$SOURCE_NAME
  make DESTDIR=$${pkgdir} install

  # move module tree /lib -> /usr/lib
  cp -r $${pkgdir}/{lib,usr}
  rm -r $${pkgdir}/lib

  split:: # Remove the stuff that was included with the zfs package
  split:: rm -r $${pkgdir}/usr/{lib/modules,src}

  install -D -m644 $${srcdir}/zfs-utils.initcpio.hook $${pkgdir}/usr/lib/initcpio/hooks/zfs
  install -D -m644 $${srcdir}/zfs-utils.initcpio.install $${pkgdir}/usr/lib/initcpio/install/zfs
  install -D -m644 $${srcdir}/zfs-utils.service $${pkgdir}/usr/lib/systemd/system/zfs.service
  install -D -m644 $${srcdir}/zfs-utils.bash-completion $${pkgdir}/usr/share/bash-completion/completions/zfs
}"""

ZFS = r"""
package_zfs() {
  pkgdesc="Kernel modules for the Zettabyte File System."
  depends=('spl=$PACKAGE_VER' 'zfs-utils=$PACKAGE_VER' $ZFS_DEPENDS)
  makedepends=($ZFS_MAKEDEPENDS)

  cd $${srcdir}/$SOURCE_NAME
  make DESTDIR=$${pkgdir} install

  split:: # Remove stuff that will be included with zfs-utils
  split:: rm -r $${pkgdir}/{lib/udev,etc,sbin}
  split:: rm -r $${pkgdir}/usr/{bin,include,lib,sbin,share}

  # move module tree /lib -> /usr/lib
  cp -r $${pkgdir}/{lib,usr}
  rm -r $${pkgdir}/lib
}"""

# Constants and callbacks for repository handling
REPO_NAME = 'archzfs'
REPO_PATH = 'archzfs/x86_64'
REPO_GROUP = 'split'


def repo_post_cb():
    """Called after the repository has been updated."""
    pass
    # subprocess.call(['./copy_sources.sh'])

# flake8: noqa
