#!/bin/bash
set -e

if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    gpg --import /dev/stdin <<<"${GPG_KEY_DATA}"
fi

# Only set -x here so we can't accidently print the GPG key up there
set -x

sudo chown -R buildbot:buildbot /src
cd /src

sed -i "/^THREADS=/s/9/$(nproc)/" ~/.config/clean-chroot-manager.conf
sudo ccm64 d || true

sudo bash build.sh -d -u all update

build() {
    sudo bash build.sh -d "$1" make
}

build utils

build std
build lts
build hardened
build zen
build dkms

# Not implemented, yet, as documented in archzfs-ci
# sudo bash test.sh ...

rm -rf /src/repo
mkdir -p /src/repo
cp -v /scratch/.buildroot/root/repo/*.pkg.tar* /src/repo/

cd /src/repo
# Ensure we do not have any stray signatures around
rm -fv *.sig

if [ ! -z "${GPG_KEY_ID-}" ]; then
    # We use find here as that allows us to exclude .sig files, which do not need to be passed to repo-add or signed again
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print -exec gpg --batch --yes --detach-sign --use-agent -u "${GPG_KEY_ID}" {} \;
    find . -type f -iname '*.pkg.tar*' -not -iname '*.sig' -print0 | xargs -0 repo-add -k "${GPG_KEY_ID}" -s -v archzfs.db.tar.xz
else
    repo-add archzfs.db.tar.xz *.pkg.tar*
fi
cd /src
