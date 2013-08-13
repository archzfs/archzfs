#!/bin/bash

SOURCE_PATH="/mnt/data/pacman/repo/sources"

set -e

rsync -avhP --delete-before \
      --exclude=sources/ \
      /mnt/data/pacman/repo/demz* \
      jalvarez@jalvarez.webfactional.com:webapps/default/ $1


[ -n $1 ] && exit

rst2html2 $SOURCE_PATH/archzfs/web_archzfs.rst > /tmp/archzfs_index.html

rst2html2 $SOURCE_PATH/archnetflix/web_archnetflix.rst > /tmp/archnetflix_index.html

scp /tmp/archzfs_index.html \
    jalvarez@jalvarez.webfactional.com:webapps/default/archzfs/index.html

scp /tmp/archnetflix_index.html \
    jalvarez@jalvarez.webfactional.com:webapps/default/archnetflix/index.html
