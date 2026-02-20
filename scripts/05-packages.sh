#!/usr/bin/env bash
# 05-packages.sh — Install packages from list files

log "Reading package lists..."

PACKAGES=()
for list in "${SCRIPT_DIR}/${PKG_DIR}"/*.txt; do
    list_name="$(basename "${list}")"
    log "  Loading ${list_name}..."
    while IFS= read -r line; do
        # Strip comments and whitespace
        pkg="${line%%#*}"
        pkg="${pkg// /}"
        [[ -z "${pkg}" ]] && continue
        PACKAGES+=("${pkg}")
    done < "${list}"
done

log "Installing ${#PACKAGES[@]} packages..."
arch-chroot /mnt pacman -S --needed --noconfirm "${PACKAGES[@]}"

# Install paru (AUR helper)
log "Installing paru AUR helper..."
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

cd /tmp
sudo -u ${USERNAME} git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
sudo -u ${USERNAME} makepkg -si --noconfirm
cd /
rm -rf /tmp/paru-bin

CHROOT

log "Package installation complete."
