[[ -f ~/.bashrc ]] && . ~/.bashrc

# pgOS rice: the tty1 login session IS the Wayland session (no display
# manager by design — Omarchy-style). WLR_* covers VirtualBox/QEMU guests
# where 3D acceleration is off.
if [ "$(tty)" = "/dev/tty1" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && command -v Hyprland >/dev/null 2>&1; then
    export WLR_NO_HARDWARE_CURSORS=1
    exec Hyprland
fi
