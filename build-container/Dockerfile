FROM archlinux:base-devel

# The following is from https://github.com/archzfs/archzfs-ci/blob/master/worker/Dockerfile
RUN pacman -Syu --noconfirm --needed python-pipx python-twisted python-future git wget systemd-sysvcompat openresolv vi

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
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/clean-chroot-manager.tar.gz && \
    tar -xvf clean-chroot-manager.tar.gz && \
    cd clean-chroot-manager              && \
    makepkg -si --noconfirm              && \
    cd /tmp                              && \
    rm -rfv /tmp/ccm-install

USER root
COPY ccm.conf /home/buildbot/.config/clean-chroot-manager.conf
RUN ccm64 p && \
    chown -R buildbot:buildbot /home/buildbot && \
    mkdir -p /scratch/.buildroot

COPY entrypoint.sh /entrypoint.sh
COPY systemd-nspawn-wrapper /usr/local/bin/systemd-nspawn
RUN systemd-machine-id-setup

USER buildbot
VOLUME /src
ENTRYPOINT [ "/entrypoint.sh" ]
