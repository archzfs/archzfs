#!/bin/bash
set -e

if [ ! -z "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'GPG_KEY_ID is not set, but GPG_KEY_DATA is set. Please set GPG_KEY_ID to the key ID of the key.'
        exit 1
    fi
    gpg --import /dev/stdin <<<"${GPG_KEY_DATA}"
fi

gpg --recv-keys 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9 # ArchZFS release key should always be valid

# Only set -x here so we can't accidently print the GPG key up there
set -x

FAILOVER_REPO_DIR=""
FAILOVER_BASE_URL=""
if [ ! -z "${FAILOVER_RELEASE_NAME}" ]; then
    FAILOVER_REPO_DIR="$(mktemp -d)"
    cd "${FAILOVER_REPO_DIR}"
    FAILOVER_BASE_URL="https://github.com/archzfs/archzfs/releases/download/${FAILOVER_RELEASE_NAME}"
    db_file="archzfs.db.tar.xz"
    if ! curl -f -o "${db_file}" -L "${FAILOVER_BASE_URL}/${db_file}"; then
        echo 'Failover database download failed, failover impossible!'
        FAILOVER_BASE_URL=""
        FAILOVER_REPO_DIR=""
    elif ! curl -f -o "${db_file}.sig" -L "${FAILOVER_BASE_URL}/${db_file}.sig"; then
        echo 'Failover signature download failed, failover impossible!'
        FAILOVER_BASE_URL=""
        FAILOVER_REPO_DIR=""
    elif ! gpg --verify "${db_file}.sig" "${db_file}"; then
        echo 'Failover signature verification failed, failover impossible!'
        FAILOVER_BASE_URL=""
        FAILOVER_REPO_DIR=""
    elif ! tar xvJf "${db_file}"; then
        echo 'Failover unreadable, failover impossible!'
        FAILOVER_BASE_URL=""
        FAILOVER_REPO_DIR=""
    fi
fi

if [ ! -z "${MIRROR_URL}" ]; then
    echo "==> Forcing system mirror to: ${MIRROR_URL}"
    echo "Server = ${MIRROR_URL}/archlinux/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist
else
    echo "!! WARNING: MIRROR_URL was not set. Using default mirrors."
fi

sudo chown -R buildbot:buildbot /src
cd /src

sed -i "/^THREADS=/s/9/$(nproc)/" ~/.config/clean-chroot-manager.conf
sudo ccm d || true

sudo bash build.sh -s -d -u all update

build() {
    sudo bash build.sh -s -d "$1" make
}

failover() {
    if [ -z "${FAILOVER_REPO_DIR}" ]; then
        echo "No failover repo available, failing because of: $1"
        exit 1
    fi

    failed_pkg="$1"

    set +x # This gets way to verbose
    for desc in "${FAILOVER_REPO_DIR}"/*/desc; do

        # Iterate lines
        pkgbase=""
        pkgfile=""
        while read -r line; do
            case "$line" in
                %FILENAME%)
                    read -r pkgfile
                    ;;
                %BASE%)
                    read -r pkgbase
                    ;;
            esac
        done < "$desc"

        # If BASE is us, that means  we should have built this package
        # so copy it from releases
        if [[ "${pkgbase}" == "${failed_pkg}" ]]; then
            set -x
            tmp_file="$(mktemp)"
            curl -f -o "${tmp_file}" -L "${FAILOVER_BASE_URL}/${pkgfile}"
            curl -f -o "${tmp_file}.sig" -L "${FAILOVER_BASE_URL}/${pkgfile}.sig"
            gpg --verify "${tmp_file}.sig" "${tmp_file}"
            sudo mv "${tmp_file}" "/scratch/.buildroot/root/repo/${pkgfile}"
            set +x
        fi
    done
    set -x
}

# These packages must always build
build utils
build dkms

# These are kernel dependant, so they might fail
build lts || failover zfs-linux-lts
build std || failover zfs-linux
build hardened || failover zfs-linux-hardened
build zen || failover zfs-linux-zen

# Not implemented, yet, as documented in archzfs-ci
# sudo bash test.sh ...

rm -rf /src/repo
mkdir -p /src/repo
sudo chmod -v 644 /scratch/.buildroot/root/repo/*.pkg.tar*
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
