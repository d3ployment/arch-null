#!/usr/bin/env bash
set -euo pipefail

# arch-null installer
# Run from the Arch Linux live ISO
#   --dry-run   Print what each step would do without executing anything

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[arch-null]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }
step() { echo -e "\n${BLUE}${BOLD}==> $*${NC}"; }

# Source configuration
source "${SCRIPT_DIR}/config.sh"

# Display configuration summary
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║          a r c h - n u l l           ║"
echo "  ║          /arch/null                   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

if $DRY_RUN; then
    echo -e "${YELLOW}[DRY RUN]${NC} No changes will be made."
    echo ""
fi

echo -e "${BOLD}Configuration:${NC}"
echo "  Disk:       ${DISK}"
echo "  EFI:        ${PART_EFI}"
echo "  Root:       ${PART_ROOT} (LUKS2 + Btrfs)"
echo "  Hostname:   ${HOSTNAME}"
echo "  Username:   ${USERNAME}"
echo "  Timezone:   ${TIMEZONE}"
echo "  Kernel:     ${KERNEL}"
echo "  Network:    ${NET_ADDRESS} via ${NET_GATEWAY} on ${NET_IFACE}"
echo ""

if ! $DRY_RUN; then
    read -rp "$(echo -e "${YELLOW}This will ERASE ${DISK}. Continue? [y/N]:${NC} ")" confirm
    if [[ "${confirm}" != [yY] ]]; then
        err "Aborted."
        exit 1
    fi
fi

# Run install scripts in order (skip 07-yubikey, it's post-boot only)
for script in "${SCRIPT_DIR}"/scripts/[0-9][0-9]-*.sh; do
    script_name="$(basename "${script}")"
    [[ "${script_name}" == "07-yubikey.sh" ]] && continue
    step "${script_name}"
    if $DRY_RUN; then
        log "(dry run) Would source ${script_name}"
    else
        source "${script}"
    fi
done

if $DRY_RUN; then
    echo ""
    echo -e "${GREEN}${BOLD}Dry run complete.${NC} No changes were made."
    exit 0
fi

echo ""
echo -e "${GREEN}${BOLD}Installation complete.${NC}"
echo -e "Remove installation media and reboot."
echo -e "After first boot, run ${BLUE}07-yubikey.sh${NC} to enroll your Yubikey."
echo ""
read -rp "Reboot now? [y/N]: " reboot_confirm
if [[ "${reboot_confirm}" == [yY] ]]; then
    umount -R /mnt 2>/dev/null || true
    reboot
fi
