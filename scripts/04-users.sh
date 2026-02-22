#!/usr/bin/env bash
# 04-users.sh — User creation and sudo

log "Configuring user ${USERNAME}..."

# Create user if it doesn't exist
if ! run_target "id ${USERNAME}" &>/dev/null; then
    log "Creating user ${USERNAME}..."
    run_target "useradd -m -G wheel,render -s /bin/bash ${USERNAME}"

    echo ""
    warn "Set password for ${USERNAME}:"
    if $LIVE_ISO; then
        arch-chroot /mnt passwd "${USERNAME}"
    else
        passwd "${USERNAME}"
    fi

    echo ""
    warn "Set root password:"
    if $LIVE_ISO; then
        arch-chroot /mnt passwd
    else
        passwd
    fi
else
    log "User ${USERNAME} already exists, ensuring groups..."
    run_target "usermod -aG wheel,render ${USERNAME}"
fi

# Sudo: allow wheel group
log "Configuring sudo..."
mkdir -p "${TARGET}/etc/sudoers.d"
echo "%wheel ALL=(ALL:ALL) ALL" > "${TARGET}/etc/sudoers.d/wheel"
chmod 440 "${TARGET}/etc/sudoers.d/wheel"

log "User setup complete."
