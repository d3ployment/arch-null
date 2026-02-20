#!/usr/bin/env bash
set -euo pipefail

# Boot an Arch Linux VM via QEMU + VNC (works in WSL2)
# Downloads the ISO if needed, creates a virtual disk, shares this repo via 9p
#
# Dependencies:
#   pacman -S qemu-system-x86 edk2-ovmf
#
# Usage:
#   ./test-vm.sh              # downloads ISO, creates disk, boots VM
#   ./test-vm.sh --fresh      # wipe the test disk and start over
#
# Then connect a VNC client on Windows to localhost:5900

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="${SCRIPT_DIR}/.vm"
DISK="${VM_DIR}/test-disk.qcow2"
DISK_SIZE="40G"
ISO="${VM_DIR}/archlinux.iso"
RAM="4G"
CPUS="4"
VNC_PORT="5900"

# OVMF paths differ between distros
for ovmf_path in \
    /usr/share/edk2/x64/OVMF.4m.fd \
    /usr/share/edk2/x64/OVMF.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/qemu/OVMF.fd \
    /usr/share/ovmf/OVMF.fd; do
    if [[ -f "${ovmf_path}" ]]; then
        OVMF="${ovmf_path}"
        break
    fi
done

if [[ -z "${OVMF:-}" ]]; then
    echo "Error: OVMF (UEFI firmware) not found." >&2
    echo "Install it: pacman -S edk2-ovmf" >&2
    exit 1
fi

mkdir -p "${VM_DIR}"

# ── Fresh start ───────────────────────────────────────────
if [[ "${1:-}" == "--fresh" ]]; then
    echo "Wiping test disk..."
    rm -f "${DISK}"
fi

# ── Download Arch ISO ─────────────────────────────────────
if [[ ! -f "${ISO}" ]]; then
    echo "Downloading latest Arch Linux ISO..."
    MIRROR="https://geo.mirror.pkgbuild.com/iso/latest"
    ISO_NAME=$(curl -sL "${MIRROR}/" | grep -oP 'archlinux-\d{4}\.\d{2}\.\d{2}-x86_64\.iso' | head -1)
    if [[ -z "${ISO_NAME}" ]]; then
        echo "Error: Could not determine latest ISO filename." >&2
        exit 1
    fi
    curl -L -o "${ISO}" "${MIRROR}/${ISO_NAME}"
    echo "Downloaded ${ISO_NAME}"
fi

# ── Create test disk ──────────────────────────────────────
if [[ ! -f "${DISK}" ]]; then
    echo "Creating ${DISK_SIZE} test disk..."
    qemu-img create -f qcow2 "${DISK}" "${DISK_SIZE}"
fi

# ── KVM check ─────────────────────────────────────────────
KVM_FLAG=""
if [[ -w /dev/kvm ]]; then
    KVM_FLAG="-enable-kvm"
    echo "KVM available"
else
    echo "No KVM — VM will be slow but functional"
fi

# ── Boot VM ───────────────────────────────────────────────
echo ""
echo "Booting Arch Linux VM..."
echo "────────────────────────────────────────"
echo "Connect VNC client to localhost:${VNC_PORT}"
echo ""
echo "Inside the VM:"
echo "  mkdir -p /root/arch-null"
echo "  mount -t 9p -o trans=virtio arch-null /root/arch-null"
echo "  cd /root/arch-null"
echo "  vim config.sh        # set DISK=/dev/vda"
echo "  ./install.sh"
echo "────────────────────────────────────────"
echo ""

qemu-system-x86_64 \
    ${KVM_FLAG} \
    -m "${RAM}" \
    -smp "${CPUS}" \
    -bios "${OVMF}" \
    -drive file="${DISK}",format=qcow2,if=virtio \
    -cdrom "${ISO}" \
    -boot d \
    -virtfs local,path="${SCRIPT_DIR}",mount_tag=arch-null,security_model=mapped-xattr,id=arch-null \
    -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 \
    -vnc 0.0.0.0:0 \
    -vga std \
    -daemonize

echo "VM running in background."
echo "  VNC:  localhost:${VNC_PORT}"
echo "  SSH:  ssh -p 2222 root@localhost (after setting passwd in VM)"
echo "  Stop: kill \$(cat ${VM_DIR}/qemu.pid 2>/dev/null) or pkill qemu-system"
