#!/bin/bash

#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs package documentation.
#

source "lib.sh"
source "conf.sh"

msg "Pushing the package sources to AUR..."
FILES=$(find . -iname "*$ZOL_VER_$LINUX_VER-$PKGREL*.src.tar.gz")
burp -c modules $FILES -v

# Build the documentation and push it to the remote host
msg "Building the documentation..."
rst2html2 $SOURCE_PATH/archzfs/web_archzfs.rst > /tmp/archzfs_index.html
msg2 "Pushing the documentation to the remote host..."
scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
