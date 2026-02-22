#!/usr/bin/env bash
# 05-packages.sh — Install packages from list files

# Enable multilib repo if not already enabled
if ! grep -q '^\[multilib\]' "${TARGET}/etc/pacman.conf"; then
    log "Enabling multilib repository..."
    sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' "${TARGET}/etc/pacman.conf"
fi
run_target "pacman -Sy --noconfirm"

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
run_target "pacman -S --needed --noconfirm ${PACKAGES[*]}"

# Install paru if not present
if ! run_target "command -v paru" &>/dev/null; then
    log "Installing paru AUR helper..."
    if $LIVE_ISO; then
        arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail
cd /tmp
rm -rf paru-bin
sudo -u ${USERNAME} git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
sudo -u ${USERNAME} makepkg -si --noconfirm
cd /
rm -rf /tmp/paru-bin
CHROOT
    else
        cd /tmp
        rm -rf paru-bin
        sudo -u "${USERNAME}" git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        sudo -u "${USERNAME}" makepkg -si --noconfirm
        cd /
        rm -rf /tmp/paru-bin
    fi
else
    log "paru already installed."
fi

# Set user shell to zsh if not already
CURRENT_SHELL=$(run_target "getent passwd ${USERNAME}" | cut -d: -f7)
if [[ "${CURRENT_SHELL}" != "/usr/bin/zsh" ]]; then
    log "Setting ${USERNAME} shell to zsh..."
    run_target "chsh -s /usr/bin/zsh ${USERNAME}"
else
    log "Shell already set to zsh."
fi

log "Package installation complete."
