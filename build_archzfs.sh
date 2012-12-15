#!/bin/sh

cd devsrc/spl-utils

makepkg -sfic --noconfirm

cd ../spl

makepkg -sfic --noconfirm

cd ../zfs-utils

makepkg -sfic --noconfirm

cd ../zfs

makepkg -sfic --noconfirm
