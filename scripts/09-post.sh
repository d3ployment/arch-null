#!/usr/bin/env bash
# 09-post.sh — Final system tweaks

log "Applying final configuration..."

# Pacman config: parallel downloads, color, candy
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /mnt/etc/pacman.conf
sed -i 's/^#Color/Color/' /mnt/etc/pacman.conf
sed -i '/^Color/a ILoveCandy' /mnt/etc/pacman.conf

# Snapper config — write directly instead of using snapper CLI (needs D-Bus)
mkdir -p /mnt/.snapshots
cp "${SCRIPT_DIR}/system/snapper/root-config" /mnt/etc/snapper/configs/root
# Register the config with snapper
sed -i 's/^SNAPPER_CONFIGS=""/SNAPPER_CONFIGS="root"/' /mnt/etc/conf.d/snapper

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
