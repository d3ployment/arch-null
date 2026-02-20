#!/usr/bin/env bash
# 07-yubikey.sh — Enroll Yubikey FIDO2 for LUKS2 unlock
#
# Run AFTER first boot, not during install.
# The Yubikey must be physically inserted.
#
# Usage: sudo ./scripts/07-yubikey.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[arch-null]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

log "Enrolling Yubikey FIDO2 token for LUKS2 unlock..."
echo ""
warn "Make sure your Yubikey is inserted."
warn "You will need to:"
warn "  1. Enter your existing LUKS passphrase"
warn "  2. Touch the Yubikey when it blinks"
echo ""
read -rp "Ready? [y/N]: " confirm
if [[ "${confirm}" != [yY] ]]; then
    err "Aborted."
    exit 1
fi

# Enroll FIDO2
systemd-cryptenroll --fido2-device=auto "${PART_ROOT}"

log "Yubikey enrolled successfully."
log "On next boot, touch your Yubikey to unlock the disk."
log "Your passphrase still works as a fallback."

# Update crypttab for FIDO2 support
if ! grep -q "fido2-device=auto" /etc/crypttab 2>/dev/null; then
    log "Updating /etc/crypttab for FIDO2..."
    LUKS_UUID="$(blkid -s UUID -o value "${PART_ROOT}")"
    echo "${CRYPT_NAME}  UUID=${LUKS_UUID}  -  fido2-device=auto" > /etc/crypttab
    log "Rebuilding initramfs..."
    mkinitcpio -P
fi

log "Yubikey FIDO2 setup complete."
