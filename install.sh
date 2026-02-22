#!/usr/bin/env bash
set -euo pipefail

# arch-null installer
# Run from the Arch Linux live ISO or from an installed system
#
# From live ISO:  full install (partition, base, configure, packages, dotfiles)
# From installed: sync packages, dotfiles, services, system config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Detect environment
if [[ -d /run/archiso ]]; then
    LIVE_ISO=true
    TARGET="/mnt"
else
    LIVE_ISO=false
    TARGET=""
fi

# Run a command in the target system
run_target() {
    if $LIVE_ISO; then
        arch-chroot /mnt /bin/bash -c "$*"
    else
        /bin/bash -c "$*"
    fi
}

# Display configuration summary
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║          a r c h - n u l l           ║"
echo "  ║          /arch/null                   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

if $LIVE_ISO; then
    echo -e "${YELLOW}[LIVE ISO]${NC} Full install mode."
else
    echo -e "${YELLOW}[INSTALLED]${NC} Sync mode — updating config, packages, dotfiles."
fi
echo ""

echo -e "${BOLD}Configuration:${NC}"
echo "  Hostname:   ${HOSTNAME}"
echo "  Username:   ${USERNAME}"
echo "  Timezone:   ${TIMEZONE}"
echo "  Kernel:     ${KERNEL}"
if $LIVE_ISO; then
    echo "  Disk:       ${DISK}"
    echo "  EFI:        ${PART_EFI}"
    echo "  Root:       ${PART_ROOT} (LUKS2 + Btrfs)"
    echo "  Network:    ${NET_ADDRESS} via ${NET_GATEWAY} on ${NET_IFACE}"
fi
echo ""

if $LIVE_ISO; then
    read -rp "$(echo -e "${YELLOW}This will ERASE ${DISK}. Continue? [y/N]:${NC} ")" confirm
    if [[ "${confirm}" != [yY] ]]; then
        err "Aborted."
        exit 1
    fi
fi

# Run numbered install scripts in order
for script in "${SCRIPT_DIR}"/scripts/[0-9][0-9]-*.sh; do
    script_name="$(basename "${script}")"

    # On installed system, skip destructive scripts
    if ! $LIVE_ISO; then
        case "${script_name}" in
            00-preflight.sh|01-partition.sh|02-base.sh|03-configure.sh) continue ;;
        esac
    fi

    step "${script_name}"
    source "${script}"
done

echo ""
echo -e "${GREEN}${BOLD}Done.${NC}"
if $LIVE_ISO; then
    echo -e "Remove installation media and reboot."
    echo -e "After first boot, run ${BLUE}scripts/yubikey.sh${NC} to enroll your Yubikey."
    echo ""
    read -rp "Reboot now? [y/N]: " reboot_confirm
    if [[ "${reboot_confirm}" == [yY] ]]; then
        umount -R /mnt 2>/dev/null || true
        reboot
    fi
fi
