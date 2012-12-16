#!/bin/sh

cd devsrc/spl-utils

makepkg -sfic --noconfirm
makepkg -Sfc

cd ../spl

makepkg -sfic --noconfirm
makepkg -Sfc

cd ../zfs-utils

makepkg -sfic --noconfirm
makepkg -Sfc

cd ../zfs

makepkg -sfic --noconfirm
makepkg -Sfc

cd ../../backup/latest

find . -iname '*.src.tar*' -exec mv {} ../sources/ \;
find . -iname '*.pkg.tar*' -exec mv {} ../packages/ \;

cd ../../devsrc

find . -iname '*.src.tar*' -exec mv {} ../backup/latest \;
find . -iname '*.pkg.tar*' -exec mv {} ../backup/latest \;

