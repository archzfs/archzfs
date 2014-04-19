#!/bin/bash

#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs package documentation.
#

source ./lib.sh
source ./conf.sh

msg "Pushing the package sources to AUR..."

full_kernel_version

FILES=$(find . -iname "*${AZB_ZOL_VERSION}*${AZB_KERNEL_X64_VERSION_CLEAN}-${AZB_PKGREL}*.src.tar.gz")

burp -c modules $FILES -v

# Build the documentation and push it to the remote host
# msg "Building the documentation..."
# rst2html2 web_archzfs.rst > /tmp/archzfs_index.html
# msg2 "Pushing the documentation to the remote host..."
# scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
