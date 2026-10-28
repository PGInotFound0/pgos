#!/usr/bin/env bash
#
# pgOS archiso profile definition
#

iso_name="pgos"
iso_label="PGOS_$(date --utc +%Y%m%d)"
iso_publisher="pginotfound <https://github.com/pginotfound>"
iso_application="pgOS Linux Live/Installation DVD"
iso_version="$(date --utc +%Y.%m.%d)"
install_dir="pgos"
buildmodes=('iso')
bootmodes=('bios.syslinux.eltorito' 'uefi-x64.systemd-boot.eltorito' 'uefi-x64.systemd-boot.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '14')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/pg-install"]="0:0:755"
)
