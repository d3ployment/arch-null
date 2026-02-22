#!/usr/bin/env bash
# 06-services.sh — Enable systemd services

log "Enabling system services..."

SERVICES=(
    systemd-networkd
    systemd-resolved
    systemd-timesyncd
    bluetooth
    fstrim.timer
    snapper-timeline.timer
    snapper-cleanup.timer
)

for svc in "${SERVICES[@]}"; do
    run_target "systemctl enable ${svc}" 2>/dev/null || true
done

# Auto-login on tty1
log "Configuring auto-login on tty1..."
mkdir -p "${TARGET}/etc/systemd/system/getty@tty1.service.d"
cat > "${TARGET}/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin ${USERNAME} %I \$TERM
EOF

log "Services enabled."
