#!/usr/bin/env bash
# 09-post.sh — Final system tweaks

log "Applying final configuration..."

PACMAN_CONF="${TARGET}/etc/pacman.conf"

# Pacman config: parallel downloads
if grep -q '^#ParallelDownloads' "${PACMAN_CONF}"; then
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' "${PACMAN_CONF}"
fi

# Pacman config: color
if grep -q '^#Color' "${PACMAN_CONF}"; then
    sed -i 's/^#Color/Color/' "${PACMAN_CONF}"
fi

# Pacman config: ILoveCandy (only add once)
if ! grep -q '^ILoveCandy' "${PACMAN_CONF}"; then
    sed -i '/^Color/a ILoveCandy' "${PACMAN_CONF}"
fi

# Snapper config — write directly (no D-Bus needed)
mkdir -p "${TARGET}/.snapshots"
mkdir -p "${TARGET}/etc/snapper/configs"
cp "${SCRIPT_DIR}/../system/snapper/root-config" "${TARGET}/etc/snapper/configs/root"
if grep -q '^SNAPPER_CONFIGS=""' "${TARGET}/etc/conf.d/snapper" 2>/dev/null; then
    sed -i 's/^SNAPPER_CONFIGS=""/SNAPPER_CONFIGS="root"/' "${TARGET}/etc/conf.d/snapper"
fi

# Network config
mkdir -p "${TARGET}/etc/systemd/network"
cat > "${TARGET}/etc/systemd/network/20-wired.network" <<EOF
[Match]
Name=${NET_IFACE}

[Network]
Address=${NET_ADDRESS}
Gateway=${NET_GATEWAY}
DNS=${NET_DNS}
EOF

# AMDGPU environment variables
mkdir -p "${TARGET}/etc/profile.d"
cat > "${TARGET}/etc/profile.d/amdgpu.sh" <<'EOF'
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

# Pacman hooks for snapper snapshots
mkdir -p "${TARGET}/etc/pacman.d/hooks"
cat > "${TARGET}/etc/pacman.d/hooks/50-snapper-pre.hook" <<'EOF'
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

cat > "${TARGET}/etc/pacman.d/hooks/51-snapper-post.hook" <<'EOF'
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
