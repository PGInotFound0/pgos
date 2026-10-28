FROM archlinux:base-devel

# Build environment for pg-OS ISO builds on any host
RUN pacman-key --init && \
    pacman -Syu --noconfirm archiso rsync git

WORKDIR /pgos
# Build the custom repo first (may fail harmlessly -> ISO without [pgos]),
# then build the ISO.
CMD ["/bin/bash", "-c", "./repo/make-repo.sh || echo '[pgos] repo build failed — continuing without custom packages'; exec ./build.sh"]
