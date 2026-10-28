#!/usr/bin/env bash
#
# build.sh - build the pgOS ISO
#
#   sudo ./build.sh            build with mkarchiso (needs archiso + root)
#   ./build.sh --docker        build inside a privileged container instead
#
set -euo pipefail

PGOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$PGOS_ROOT/build"
PROFILE="$BUILD/profile"
WORK="$BUILD/work"
OUT="$BUILD/out"

blu='\e[1;34m' red='\e[0;31m' nc='\e[0m'
msg()  { printf "\n${blu}==> ${nc}%s\n" "$*"; }
die()  { printf "${red}  xx ${nc}%s\n" "$*" >&2; exit 1; }

if [[ ${1:-} == "--docker" ]]; then
  command -v docker >/dev/null || die "docker not found"
  msg "Building in a privileged container"
  docker build -t pgos-builder "$PGOS_ROOT/docker"
  exec docker run --privileged --rm -it -v "$PGOS_ROOT":/pgos pgos-builder
fi

[[ $EUID -eq 0 ]] || die "mkarchiso needs root. Run:  sudo ./build.sh   (or --docker)"
command -v mkarchiso >/dev/null || die "mkarchiso not found. Install:  pacman -S archiso  (or run with --docker)"
command -v rsync >/dev/null || die "rsync not found"

RELENG="/usr/share/archiso/configs/releng"
[[ -d $RELENG ]] || die "archiso releng profile not found at $RELENG"

msg "Preparing profile (releng boot machinery + pgOS overlay)"
rm -rf "$PROFILE"
mkdir -p "$PROFILE"
cp -r "$RELENG"/efiboot "$RELENG"/syslinux "$PROFILE"/
rsync -a --chown=0:0 "$PGOS_ROOT/iso/" "$PROFILE"/

# Rebrand the boot menu. Templates (%INSTALL_DIR% etc.) are left alone;
# only human-visible text is replaced.
find "$PROFILE/efiboot" "$PROFILE/syslinux" -type f \( -name '*.conf' -o -name '*.cfg' \) -print0 |
  xargs -0 -r sed -i -e 's/Arch Linux install medium/pgOS install medium/g' \
                     -e 's/Arch Linux user manual/pgOS user manual/g' \
                     -e 's/Arch Linux (x86_64, UEFI)/pgOS x86_64 (UEFI)/g' \
                     -e 's/Arch Linux (x86_64, BIOS)/pgOS x86_64 (BIOS)/g' \
                     -e 's/^title   Arch Linux/title   pgOS/g' \
                     -e 's/^MENU TITLE Arch Linux/MENU TITLE pgOS/g'

# Enable the [pgos] custom repo if it has been built (make-repo.sh)
REPO="$PGOS_ROOT/repo/x86_64"
if [[ -e "$REPO/pgos.db" || -e "$REPO/pgos.db.tar.zst" ]]; then
  msg "Enabling [pgos] custom repo -> $REPO"
  sed -i \
    -e 's|^#\[pgos\]$|[pgos]|' \
    -e 's|^#SigLevel = Optional TrustAll$|SigLevel = Optional TrustAll|' \
    -e "s|^#Server = file:///absolute/path/to/pgos/repo/x86_64$|Server = file://$REPO|" \
    "$PROFILE/pacman.conf"
  printf 'pgos-wlogout\n' >> "$PROFILE/packages.x86_64"
  # Ship the custom package ON the ISO so pg-install can apply it
  # offline (pacman -U) even when no repo server is configured.
  mkdir -p "$PROFILE/airootfs/opt/pgos/packages"
  cp "$REPO"/pgos-wlogout-*.pkg.tar.zst "$PROFILE/airootfs/opt/pgos/packages/"
fi

msg "Building ISO (downloads a few GB the first time — make coffee)"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

ISO="$(ls -t "$OUT"/*.iso | head -n1)"
sha256sum "$ISO" | tee "$ISO.sha256sum"
msg "ISO ready: $ISO"
msg "Burn it:   cat $ISO > /dev/sdX && sync"
msg "Test it:   qemu-system-x86_64 -enable-kvm -cpu host -m 4G -cdrom \"$ISO\""
