#!/usr/bin/env bash
# 08-dotfiles.sh — Deploy dotfiles to user home

USER_HOME="/mnt/home/${USERNAME}"
CONFIG_DIR="${USER_HOME}/.config"

log "Deploying dotfiles for ${USERNAME}..."

# Map dotfile dirs to their XDG config locations
declare -A DOTFILE_MAP=(
    ["hypr"]="hypr"
    ["waybar"]="waybar"
    ["alacritty"]="alacritty"
    ["wofi"]="wofi"
    ["mako"]="mako"
    ["starship"]="starship"
    ["gtk"]="gtk-3.0"
)

for src_dir in "${!DOTFILE_MAP[@]}"; do
    dest_name="${DOTFILE_MAP[$src_dir]}"
    src_path="${SCRIPT_DIR}/../dotfiles/${src_dir}"

    if [[ -d "${src_path}" ]]; then
        dest_path="${CONFIG_DIR}/${dest_name}"
        mkdir -p "${dest_path}"
        cp -r "${src_path}/." "${dest_path}/"
        log "  ${src_dir} -> ~/.config/${dest_name}"
    fi
done

# Zsh files go to home directory
if [[ -f "${SCRIPT_DIR}/../dotfiles/zsh/.zshrc" ]]; then
    cp "${SCRIPT_DIR}/../dotfiles/zsh/.zshrc" "${USER_HOME}/.zshrc"
    log "  zsh/.zshrc -> ~/.zshrc"
fi
if [[ -f "${SCRIPT_DIR}/../dotfiles/zsh/.zprofile" ]]; then
    cp "${SCRIPT_DIR}/../dotfiles/zsh/.zprofile" "${USER_HOME}/.zprofile"
    log "  zsh/.zprofile -> ~/.zprofile"
fi

# Fix ownership
arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

log "Dotfiles deployed."
