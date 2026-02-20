#!/usr/bin/env bash
# 02-base.sh — Install base system

log "Installing base system with ${KERNEL}..."
pacstrap -K /mnt \
    base \
    "${KERNEL}" \
    "${KERNEL}-headers" \
    linux-firmware \
    amd-ucode \
    btrfs-progs \
    cryptsetup \
    dosfstools \
    e2fsprogs \
    systemd \
    sudo \
    vim \
    git \
    base-devel

log "Base system installed."
