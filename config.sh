#!/usr/bin/env bash
# arch-null configuration
# Edit these variables before running install.sh

# Target disk (e.g., /dev/nvme0n1, /dev/sda)
# WARNING: This disk will be COMPLETELY ERASED
DISK="/dev/vda"

# Partition layout (auto-derived from DISK)
# For NVMe: /dev/nvme0n1p1, /dev/nvme0n1p2
# For SATA: /dev/sda1, /dev/sda2
if [[ "$DISK" == *"nvme"* ]]; then
    PART_EFI="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_EFI="${DISK}1"
    PART_ROOT="${DISK}2"
fi

# LUKS
CRYPT_NAME="cryptroot"

# System
HOSTNAME="arch-null"
USERNAME="d3ployment"
TIMEZONE="Europe/Paris"
LOCALE="en_US.UTF-8"
KEYMAP="us"

# Btrfs subvolume layout
declare -A SUBVOLS=(
    ["@"]="/mnt"
    ["@home"]="/mnt/home"
    ["@snapshots"]="/mnt/.snapshots"
    ["@var_log"]="/mnt/var/log"
    ["@var_cache"]="/mnt/var/cache"
)

# Btrfs mount options
BTRFS_OPTS="noatime,compress=zstd,space_cache=v2"

# Kernel
KERNEL="linux-zen"

# EFI mount point
EFI_MOUNT="/mnt/boot"

# Package list directory (relative to script location)
PKG_DIR="packages"

# Network - static IP via systemd-networkd
NET_IFACE="ens3"
NET_ADDRESS="10.1.10.2/24"
NET_GATEWAY="10.1.10.1"
NET_DNS="time.cloudflare.com"
