FROM archlinux:base-devel

# Set up the mirror from mirror-url
ARG MIRROR_URL
ENV MIRROR_URL=$MIRROR_URL

USER root
RUN echo "Server = ${MIRROR_URL}/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# The following is adapted from https://github.com/archzfs/archzfs-ci/blob/master/worker/Dockerfile
RUN pacman -Syu --noconfirm --needed python-pipx python-twisted git wget systemd-sysvcompat openresolv vi
# Confirm the mirror is set, done after sync
RUN pacman -Sp linux linux-lts linux-hardened linux-zen linux-headers linux-lts-headers linux-hardened-headers linux-zen-headers

# add buildbot user and give passwordless sudo access (needed for archzfs build scripts)
RUN groupadd -r buildbot && \
    useradd -m -g buildbot buildbot && \
    mkdir /worker && \
    chown buildbot:buildbot /worker && \
    echo "buildbot ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# aur prep
RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# clean-chroot-manager
USER aur
RUN mkdir -p /tmp/ccm-install            && \
    cd /tmp/ccm-install                  && \
    # FIXME: Temporary workaround for https://github.com/archzfs/archzfs/issues/607
    # wget https://aur.archlinux.org/cgit/aur.git/snapshot/clean-chroot-manager.tar.gz && \
    wget https://mirrors.uni-plovdiv.net/aur/clean-chroot-manager.tar.gz && \
    tar -xvf clean-chroot-manager.tar.gz && \
    cd clean-chroot-manager              && \
    makepkg -si --noconfirm              && \
    cd /tmp                              && \
    rm -rfv /tmp/ccm-install

USER root
# https://github.com/archzfs/archzfs/issues/595
ENV SUDO_USER=buildbot
COPY ccm.conf /home/buildbot/.config/clean-chroot-manager.conf
RUN ccm p && \
    chown -R buildbot:buildbot /home/buildbot && \
    mkdir -p /scratch/.buildroot

COPY entrypoint.sh /entrypoint.sh
COPY systemd-nspawn-wrapper /usr/local/bin/systemd-nspawn
RUN systemd-machine-id-setup

USER buildbot
VOLUME /src
ENTRYPOINT [ "/entrypoint.sh" ]
