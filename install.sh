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

#-------------------------------------------------------------------------------
mkdir -p ~/.config/

auto=false

while getopts 'a' option; do
    case $option in
        a) auto=true ;;
        *) auto=false ;;
    esac
done

if $auto;
then
    echo ":: Auto setup"
else
    echo ":: Manual setup"
fi

# alacritty conf
if ask "alacritty.toml?"; then
    mkdir -p ~/.config/alacritty/
    rm -f ~/.config/alacritty/alacritty.toml
    ln -s "$(realpath "alacritty/alacritty.toml")" ~/.config/alacritty/alacritty.toml
fi

# zellij conf
if ask "zellij config.kdl?"; then
    mkdir -p ~/.config/zellij/
    rm -f ~/.config/zellij/config.kdl
    ln -s "$(realpath "zellij/config.kdl")" ~/.config/zellij/config.kdl

    # mkdir -p ~/.config/zellij/layouts/
    # rm -f ~/.config/zellij/layouts/default.kdl
    # ln -s "$(realpath "zellij/layouts/default.kdl")" ~/.config/zellij/layouts/default.kdl
fi

# nu shell conf
if ask "nushell config.nu, env.nu & nu scripts?"; then
    mkdir -p ~/.config/nushell/

    rm -f ~/.config/nushell/config.nu
    rm -f ~/.config/nushell/env.nu
    rm -f ~/.config/nushell/git-completions.nu
    rm -f ~/.config/nushell/conda.nu

    ln -s "$(realpath "nushell/config.nu")" ~/.config/nushell/config.nu
    ln -s "$(realpath "nushell/env.nu")" ~/.config/nushell/env.nu
    ln -s "$(realpath "nushell/git-completions.nu")" ~/.config/nushell/git-completions.nu
    ln -s "$(realpath "nushell/conda.nu")" ~/.config/nushell/conda.nu
fi

# helix conf
if ask "hexlix config.toml and mytheme.toml?"; then
    mkdir -p ~/.config/helix/
    mkdir -p ~/.config/helix/themes/

    rm -f ~/.config/helix/config.toml
    rm -f ~/.config/helix/themes/mytheme.toml

    ln -s "$(realpath "helix/config.toml")" ~/.config/helix/config.toml
    ln -s "$(realpath "helix/mytheme.toml")" ~/.config/helix/themes/mytheme.toml
fi

#-------------------------------------------------------------------------------
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
    rm -f ~/.config/starship.toml
    ln -s "$(realpath "starship/starship.toml")" ~/.config/starship.toml
    echo 'Note: Make sure to add equivalent of > $eval "$(starship init bash)" < to your shell config'
fi

echo "---"
# check selected shell
if ask "bash dotfiles in $SH?"; then
    echo >> $SH
    echo '# -------------- dotfiles install ---------------' >> $SH

    # Ask which files should be sourced
    for file in bash/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if ask "${filename}?"; then
                echo "source $(realpath "$file")" >> "$SH"
            fi
        fi
    done
fi
