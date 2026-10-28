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
├── iso/
│   ├── profiledef.sh     # archiso profile options (ISO name, bootmodes…)
│   ├── pacman.conf       # repo config used when building the ISO
│   ├── packages.x86_64   # the definitive package manifest of pgOS
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
pg-install --luks -d /dev/vda -u pg            # LUKS2-encrypted root
pg-install --repo http://host:8000 -d /dev/vda # auto-wire your [pgos] repo
```

After install, drive the system with the `pg` control panel:

```bash
pg update        # full system upgrade
pg clean         # sweep the pacman cache
pg installed     # explicitly installed packages
pg info          # fastfetch summary
```

The installer: wipes the disk → GPT (1 GiB ESP + ext4 or LUKS2-encrypted
root) → `pacstrap` the pgOS package manifest → systemd-boot → users →
dotfiles → branding. UEFI systems only.

## Where to customize what

| Want to change…                        | Edit                                        |
| -------------------------------------- | ------------------------------------------- |
| Installed packages                     | `iso/packages.x86_64` **and** `iso/airootfs/root/pg-install` |
| The rice (Hyprland, waybar, fuzzel…)   | `iso/airootfs/etc/skel/.config/…`           |
| `pg` control panel commands            | `iso/airootfs/usr/local/bin/pg`             |
| Branding (motd, os-release, issue)     | `iso/airootfs/etc/{motd,os-release,issue}`  |
| Boot menu text / kernel cmdline        | `iso/{efiboot,syslinux}` (copied at build)  |
| Your own packages                      | `repo/` → `make-repo.sh` → publish → enable `[pgos]` in `pacman.conf` |

## Building on a non-Arch machine

```bash
sudo docker build -t pgos-builder docker/
sudo docker run --privileged --rm -it -v "$(pwd)":/pgos pgos-builder
```

## Roadmap

- [x] LUKS-encrypted root in pg-install
- [ ] swap + hibernate (swapfile vs partition still worth deciding)
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

## Status

✅ **v0.1.1** — boot-tested release, 2026-10-29. Serial-verified end-to-end:
archiso hooks mount the live root, switch_root succeeds, userspace starts.

```
ad98ec44f6c7d9a67cf598d98498631078aba51690692e835b988cda164533f4  pgos-2026.10.28-x86_64.iso
```

Notable: the ISO carries the custom `[pgos]` repository — including
`pgos-wlogout 1.2.2-1`, shipped the day Arch dropped it from the official
repos, and applied offline during install via `/opt/pgos/packages/`.
v0.1.1: fixed live-root unlock, added archiso initramfs hooks (the missing
`archiso` hook caused initrd emergency in v0.1.0) + serial console for CI.
