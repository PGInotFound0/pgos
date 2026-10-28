#!/usr/bin/env bash
#
# make-repo.sh — build the pgOS pacman repository
#
# Every directory under repo/ with a PKGBUILD (any name other than x86_64)
# gets built with makepkg; results land in repo/x86_64/, regenerating
# pgos.db so anything with an /etc/pacman.conf pointing here can
# `pacman -Sy pgos-<whatever>`.
#
#   ./make-repo.sh
#   PGOS_GPG_KEY=ABCDEF... ./make-repo.sh    (signs everything — recommended)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$ROOT/x86_64"

if [[ $EUID -eq 0 ]]; then
    # makepkg refuses to run as root — hand off to an unprivileged
    # builder user and recurse (PGOS_GPG_KEY survives as env).
    # First: makepkg's -s can't sudo any deps up, so resolve the
    # depends+makedepends of every PKGBUILD here as root.
    id builder &>/dev/null || useradd -m builder
    mkdir -p "$REPO"
    chown -R builder:builder "$ROOT"
    for pkg_dir in "$ROOT"/*/; do
        [[ -f $pkg_dir/PKGBUILD ]] || continue
        deps="$(
            (cd "$pkg_dir" && bash -c '
                source ./PKGBUILD 2>/dev/null
                printf "%s\n" "${depends[@]-}" "${makedepends[@]-}"
            ')
        )"
        if [[ -n $deps ]]; then
            pacman -Sy --needed --noconfirm $(uniq <(echo "$deps")) >/dev/null
        fi
    done
    exec runuser -u builder -- "$(realpath "$0")"
fi

mkdir -p "$REPO"

for pkg_dir in "$ROOT"/*/; do
    [[ -f $pkg_dir/PKGBUILD ]] || continue
    name="$(basename "$pkg_dir")"
    echo "==> building $name"
    (
        cd "$pkg_dir"
        if command -v updpkgsums >/dev/null 2>&1; then
            updpkgsums >/dev/null 2>&1 || true
        fi
        makepkg -sf --noconfirm
    )
    cp -v "$pkg_dir"/*.pkg.tar.zst "$REPO"/
done

cd "$REPO"
if [[ -n ${PGOS_GPG_KEY:-} ]]; then
    echo "==> signing packages with key $PGOS_GPG_KEY"
    for f in ./*.pkg.tar.zst; do
        gpg --batch --yes --local-user "$PGOS_GPG_KEY" --detach-sign "$f"
    done
    repo-add -s -k "$PGOS_GPG_KEY" pgos.db.tar.zst ./*.pkg.tar.zst
else
    echo "==> unsigned repo (set PGOS_GPG_KEY to sign)"
    repo-add pgos.db.tar.zst ./*.pkg.tar.zst
fi

echo
echo "✔ Repo ready: $REPO"
echo
echo "Serve it from anywhere:"
echo "    cd $REPO && python -m http.server 8000"
echo
echo "And your users add to /etc/pacman.conf:"
echo "    [pgos]"
echo "    SigLevel = ${PGOS_GPG_KEY:+DatabaseRequired} PackageOptional"
echo "    Server = http://YOUR-SERVER:8000"
