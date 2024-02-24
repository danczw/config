# !/bin/bash
# Install script for the dotfiles
# based on https://github.com/bartekspitza/dotfiles

# Ask Y/n
function ask() {
    read -p $'Use \e[31m'"$1"$'\e[0m (Y/n): ' resp
    if [ -z "$resp" ]; then
        response_lc="y" # empty is Yes
    else
        response_lc=$(echo "$resp" | tr '[:upper:]' '[:lower:]') # case insensitive
    fi

    [ "$response_lc" = "y" ]
}

# Tmux conf
# if ask "Do you want to install .tmux.conf?"; then
#     ln -s "$(realpath ".tmux.conf")" ~/.tmux.conf
# fi

# Vim conf
# if ask "Do you want to install .vimrc?"; then
#     ln -s "$(realpath ".vimrc")" ~/.vimrc
# fi

# nu shell conf
if ask "config.nu?"; then
    rm -f ~/.config/nushell/config.nu
    ln -s "$(realpath "nushell/config.nu")" ~/.config/nushell/config.nu
fi

# Check what shell is being used
SH="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"
NUSH="${HOME}/.config/nushell/config.nu"

if [ -f "$ZSHRC" ]; then
	SH="$ZSHRC"
fi
if [ -f "$NUSH" ]; then
    SH="$NUSH"
fi
echo "Using $SH"

# starship.rs conf
if ask "starship.toml?"; then
    ln -s "$(realpath "starship.rs/starship.toml")" ~/.config/starship.toml
    echo eval "$(starship init bash)" >> $SH
fi

echo "---"
# check if selected shell is nushell
if ask "dotfiles in $SH?"; then
    echo >> $SH
    echo '# -------------- dotfiles install ---------------' >> $SH

    # Ask which files should be sourced
    for file in shell/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if ask "${filename}?"; then
                echo "source $(realpath "$file")" >> "$SH"
            fi
        fi
    done
fi
