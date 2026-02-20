#!/usr/bin/env bash
# 00-preflight.sh — Pre-flight checks

log "Checking UEFI mode..."
if [[ ! -d /sys/firmware/efi/efivars ]]; then
    err "Not booted in UEFI mode. Aborting."
    exit 1
fi

log "Checking network connectivity..."
if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    warn "No network detected. Attempting to configure ${NET_IFACE}..."
    ip link set "${NET_IFACE}" up
    ip addr add "${NET_ADDRESS}" dev "${NET_IFACE}"
    ip route add default via "${NET_GATEWAY}"
    echo "nameserver ${NET_DNS%% *}" > /etc/resolv.conf

    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        err "Still no connectivity. Check config.sh network settings."
        exit 1
    fi
fi

log "Syncing system clock..."
timedatectl set-ntp true

log "Verifying target disk ${DISK}..."
if [[ ! -b "${DISK}" ]]; then
    err "Disk ${DISK} not found. Check config.sh."
    exit 1
fi

log "Pre-flight checks passed."
