#!/usr/bin/env bash
# 09-post.sh — Final system tweaks

log "Applying final configuration..."

# Pacman config: parallel downloads, color, candy
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /mnt/etc/pacman.conf
sed -i 's/^#Color/Color/' /mnt/etc/pacman.conf
sed -i '/^Color/a ILoveCandy' /mnt/etc/pacman.conf

# Snapper configuration for root
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# Create snapper config for root
snapper -c root create-config /

# Snapper: keep 5 hourly, 7 daily, 4 weekly snapshots
snapper -c root set-config \
    TIMELINE_MIN_AGE="1800" \
    TIMELINE_LIMIT_HOURLY="5" \
    TIMELINE_LIMIT_DAILY="7" \
    TIMELINE_LIMIT_WEEKLY="4" \
    TIMELINE_LIMIT_MONTHLY="0" \
    TIMELINE_LIMIT_YEARLY="0"

CHROOT

# AMDGPU environment variables
mkdir -p /mnt/etc/profile.d
cat > /mnt/etc/profile.d/amdgpu.sh <<'EOF'
# AMDGPU: enable Vulkan (RADV), VA-API
export AMD_VULKAN_ICD=RADV
export LIBVA_DRIVER_NAME=radeonsi
# Wayland-native for most toolkits
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export XDG_SESSION_TYPE=wayland
EOF

# Pacman hook: snapshot before/after upgrades
mkdir -p /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-snapper-pre.hook <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating pre-transaction snapper snapshot...
When = PreTransaction
Exec = /usr/bin/snapper -c root create -d "pacman pre" -t pre
EOF

cat > /mnt/etc/pacman.d/hooks/51-snapper-post.hook <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating post-transaction snapper snapshot...
When = PostTransaction
Exec = /usr/bin/snapper -c root create -d "pacman post" -t post
EOF

log "Final configuration applied."
