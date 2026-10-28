FROM archlinux:base-devel

# Build environment for pg-OS ISO builds on any host
RUN pacman-key --init && \
    pacman -Syu --noconfirm archiso rsync git

WORKDIR /pgos
CMD ["./build.sh"]
