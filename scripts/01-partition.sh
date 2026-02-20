#!/usr/bin/env bash
# 01-partition.sh — Disk partitioning, LUKS2, Btrfs subvolumes

log "Wiping existing partition table on ${DISK}..."
sgdisk --zap-all "${DISK}"

log "Creating GPT partitions..."
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI" "${DISK}"
sgdisk -n 2:0:0   -t 2:8309 -c 2:"LUKS" "${DISK}"

log "Informing kernel of partition changes..."
partprobe "${DISK}"
sleep 1

log "Formatting EFI partition..."
mkfs.fat -F 32 -n EFI "${PART_EFI}"

log "Setting up LUKS2 encryption on ${PART_ROOT}..."
echo ""
warn "You will be prompted to set the disk encryption passphrase."
cryptsetup luksFormat --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha512 \
    --pbkdf argon2id \
    "${PART_ROOT}"

log "Opening LUKS container..."
cryptsetup open "${PART_ROOT}" "${CRYPT_NAME}"

BTRFS_DEV="/dev/mapper/${CRYPT_NAME}"

log "Creating Btrfs filesystem..."
mkfs.btrfs -f -L archroot "${BTRFS_DEV}"

log "Creating Btrfs subvolumes..."
mount "${BTRFS_DEV}" /mnt

for subvol in "${!SUBVOLS[@]}"; do
    btrfs subvolume create "/mnt/${subvol}"
done

umount /mnt

log "Mounting subvolumes..."
# Mount root subvolume first
mount -o "subvol=@,${BTRFS_OPTS}" "${BTRFS_DEV}" /mnt

# Create mount points and mount remaining subvolumes
for subvol in "${!SUBVOLS[@]}"; do
    [[ "${subvol}" == "@" ]] && continue
    mountpoint="${SUBVOLS[$subvol]}"
    mkdir -p "${mountpoint}"
    mount -o "subvol=${subvol},${BTRFS_OPTS}" "${BTRFS_DEV}" "${mountpoint}"
done

# Mount EFI partition
mkdir -p "${EFI_MOUNT}"
mount "${PART_EFI}" "${EFI_MOUNT}"

log "Partition layout complete."
lsblk "${DISK}"
