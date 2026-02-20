#!/usr/bin/env bash
# 04-users.sh — User creation and sudo

log "Creating user ${USERNAME}..."

arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# Create user with home directory
useradd -m -G wheel,render -s /usr/bin/zsh "${USERNAME}"

# Sudo: allow wheel group
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

CHROOT

echo ""
warn "Set password for ${USERNAME}:"
arch-chroot /mnt passwd "${USERNAME}"

echo ""
warn "Set root password:"
arch-chroot /mnt passwd

log "User setup complete."
