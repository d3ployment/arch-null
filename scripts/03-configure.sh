#!/usr/bin/env bash
# 03-configure.sh — System configuration (chroot)

log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

log "Configuring system in chroot..."

# Copy system config files
cp "${SCRIPT_DIR}/system/mkinitcpio.conf" /mnt/etc/mkinitcpio.conf

# Configure systemd-networkd
mkdir -p /mnt/etc/systemd/network
cat > /mnt/etc/systemd/network/20-wired.network <<EOF
[Match]
Name=${NET_IFACE}

[Network]
Address=${NET_ADDRESS}
Gateway=${NET_GATEWAY}
DNS=${NET_DNS}
EOF

# Symlink stub-resolv.conf for systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# Timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Locale
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Keymap
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname

# Hosts
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Enable systemd network stack
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

# Rebuild initramfs with systemd hooks
mkinitcpio -P

# Install systemd-boot
bootctl install

CHROOT

# Write bootloader configuration
log "Configuring systemd-boot..."
cp "${SCRIPT_DIR}/system/loader/loader.conf" /mnt/boot/loader/loader.conf
mkdir -p /mnt/boot/loader/entries

# Get the UUID of the LUKS partition for the boot entry
LUKS_UUID="$(blkid -s UUID -o value "${PART_ROOT}")"

cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   arch-null
linux   /vmlinuz-${KERNEL}
initrd  /amd-ucode.img
initrd  /initramfs-${KERNEL}.img
options rd.luks.name=${LUKS_UUID}=${CRYPT_NAME} root=/dev/mapper/${CRYPT_NAME} rootflags=subvol=@ rw quiet splash
EOF

cat > /mnt/boot/loader/entries/arch-fallback.conf <<EOF
title   arch-null (fallback)
linux   /vmlinuz-${KERNEL}
initrd  /amd-ucode.img
initrd  /initramfs-${KERNEL}-fallback.img
options rd.luks.name=${LUKS_UUID}=${CRYPT_NAME} root=/dev/mapper/${CRYPT_NAME} rootflags=subvol=@ rw
EOF

log "System configuration complete."
