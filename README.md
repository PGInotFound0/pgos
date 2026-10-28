# pgOS

**pgOS** — a personal Arch Linux distribution by pginotfound.

> 404: everything else, not found. pgOS, however, is right here.

pgOS is an *Arch-based* distro in the same family as EndeavourOS and Omarchy:
it doesn't fork the Arch package repos — it ships an opinionated layer on top:

- a **live ISO** built with `archiso`,
- a **hand-rolled installer** (`pg-install`), no archinstall dependency,
- a **Hyprland desktop** with a coherent rice out of the box,
- your own **pacman repo** scaffold for packages that are truly yours,
- **pgOS branding** from `os-release` to the boot menu to the wallpaper.

## Project layout

```
pgos/
├── build.sh              # one command → one ISO (see Quickstart)
├── profiledef.sh         # archiso profile options (ISO name, bootmodes…)
├── pacman.conf           # repo config used when building the ISO
├── packages.x86_64       # the definitive package manifest of pgOS
├── iso/
│   ├── airootfs/
│   │   ├── etc/          # branding + live-system config (single source of truth)
│   │   │   ├── os-release, issue, motd, pacman.conf
│   │   │   └── skel/     # user dotfiles — this IS the pgOS rice
│   │   ├── root/pg-install   # THE installer (run on the live ISO)
│   │   └── usr/share/backgrounds/pgos/   # the wallpaper
│   └── (efiboot/ syslinux/ are copied in at build time from archiso's releng)
├── repo/
│   ├── make-repo.sh      # build your own pacman repo: repo-add for your pkgs
│   └── pgos-branding/    # example PKGBUILD to get you started
└── docker/Dockerfile     # build the ISO inside a container (non-Arch hosts)
```

## Quickstart

```bash
# on any recent Arch system (Omarchy counts):
sudo pacman -S --needed archiso rsync
sudo ./build.sh          # → build/out/pgos-*.iso  (maybe 10–20 min)
```

Test it in a VM:

```bash
qemu-system-x86_64 -enable-kvm -cpu host -m 4G \
  -cdrom build/out/pgos-*.iso
```

Boot the ISO → autologins as root on tty1 → run:

```bash
pg-install              # fully interactive
pg-install -d /dev/vda -u pg -n mybox          # pre-answered
pg-install --ssh -d /dev/vda                   # also enable sshd
```

After install, drive the system with the `pg` control panel:

```bash
pg update        # full system upgrade
pg clean         # sweep the pacman cache
pg installed     # explicitly installed packages
pg info          # fastfetch summary
```

The installer: wipes the disk → GPT (1 GiB ESP + ext4 root) → `pacstrap`
the pgOS package manifest → systemd-boot → users → dotfiles → branding.
UEFI systems only in v1. Plain ext4 v1 (no LUKS yet — roadmap).

## Where to customize what

| Want to change…                        | Edit                                        |
| -------------------------------------- | ------------------------------------------- |
| Installed packages                     | `packages.x86_64` **and** `iso/airootfs/root/pg-install` |
| The rice (Hyprland, waybar, fuzzel…)   | `iso/airootfs/etc/skel/.config/…`           |
| Branding (motd, os-release, issue)     | `iso/airootfs/etc/{motd,os-release,issue}`  |
| Boot menu text / kernel cmdline        | `iso/{efiboot,syslinux}` (copied at build)  |
| Your own packages                      | `repo/` → `make-repo.sh` → publish → enable `[pgos]` in `pacman.conf` |

## Building on a non-Arch machine

```bash
sudo docker build -t pgos-builder docker/
sudo docker run --privileged --rm -it -v "$(pwd)":/pgos pgos-builder
```

## Roadmap

- [ ] LUKS-encrypted root in pg-install (v2)
- [ ] Sign the `[pgos]` repo (gpg keyring + SigLevel TrustedOnly)
- [ ] A pgOS keyring package (rebrand pacman/mirrorlist fully)
- [ ] GitHub Actions: build + release the ISO on push
- [ ] AUR-ish pgos-* package family (themed ports of common tools)

## FAQ

**Is this "a real distro"?**
It's a real ISO, a real installer, real branding — the same architecture
class EndeavourOS and Omarchy use. Forking the whole Arch package tree is
only needed when you fork *glibc*; nobody does that before breakfast.

**Why not archinstall?**
You already have your own installer. It's ~200 lines of bash you fully
control. That's the fun part.
