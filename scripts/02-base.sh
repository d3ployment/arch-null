#!/usr/bin/env bash
# 02-base.sh — Install base system

log "Installing base system with ${KERNEL}..."

BASE_PKGS=()
while IFS= read -r line; do
    pkg="${line%%#*}"
    pkg="${pkg// /}"
    [[ -z "${pkg}" ]] && continue
    BASE_PKGS+=("${pkg}")
done < "${SCRIPT_DIR}/${PKG_DIR}/base.txt"

pacstrap -K /mnt "${BASE_PKGS[@]}"

log "Base system installed."
