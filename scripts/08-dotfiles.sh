#!/usr/bin/env bash
# 08-dotfiles.sh — Deploy dotfiles to user home

if $LIVE_ISO; then
    USER_HOME="${TARGET}/home/${USERNAME}"
else
    USER_HOME="$(eval echo "~${USERNAME}")"
fi
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
for f in .zshrc .zprofile; do
    if [[ -f "${SCRIPT_DIR}/../dotfiles/zsh/${f}" ]]; then
        cp "${SCRIPT_DIR}/../dotfiles/zsh/${f}" "${USER_HOME}/${f}"
        log "  zsh/${f} -> ~/${f}"
    fi
done

# Fix ownership
if $LIVE_ISO; then
    arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"
else
    chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}"
fi

log "Dotfiles deployed."
