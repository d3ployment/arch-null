#!/usr/bin/env bash
# 06-services.sh — Enable systemd services

log "Enabling system services..."

arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# Network (already enabled in 03-configure, but ensure)
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

# Bluetooth
systemctl enable bluetooth

# SSD TRIM
systemctl enable fstrim.timer

# Snapper automatic snapshots
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

# PipeWire runs as user service — auto-starts in a desktop session

CHROOT

log "Services enabled."
