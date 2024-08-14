# !/bin/bash
# Install script for the dotfiles

NORMAL='\e[0m'
RED='\e[31m'

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

auto=false

while getopts 'a' option; do
    case $option in
        a) auto=true ;;
        *) auto=false ;;
    esac
done

if $auto; then
    echo -e "${RED}!!${NORMAL} Auto setup"
else
    echo ":: Manual setup"
fi

#-------------------------------------------------------------------------------
mkdir -p ~/.config/

# alacritty conf
if $auto; then
    set_alacritty=true
elif ask "alacritty.toml?"; then
    set_alacritty=true
else
    set_alacritty=false
fi

if $set_alacritty; then
    mkdir -p ~/.config/alacritty/
    rm -f ~/.config/alacritty/alacritty.toml
    ln -s "$(realpath "alacritty/alacritty.toml")" ~/.config/alacritty/alacritty.toml
    echo ":: alacritty.toml linked"
fi

# zellij conf
if $auto; then
    set_zellij=true
elif ask "zellij config.kdl?"; then
    set_zellij=true
else
    set_zellij=false
fi

if $set_zellij; then
    mkdir -p ~/.config/zellij/
    rm -f ~/.config/zellij/config.kdl
    ln -s "$(realpath "zellij/config.kdl")" ~/.config/zellij/config.kdl
    echo ":: zellij config.kdl linked"

    # mkdir -p ~/.config/zellij/layouts/
    # rm -f ~/.config/zellij/layouts/default.kdl
    # ln -s "$(realpath "zellij/layouts/default.kdl")" ~/.config/zellij/layouts/default.kdl
fi

# nu shell conf
if $auto; then
    set_nushell=true
elif ask "nushell config.nu, env.nu & nu scripts?"; then
    set_nushell=true
else
    set_nushell=false
fi

if $set_nushell; then
    mkdir -p ~/.config/nushell/

    rm -f ~/.config/nushell/config.nu
    rm -f ~/.config/nushell/env.nu
    rm -f ~/.config/nushell/git-completions.nu
    rm -f ~/.config/nushell/conda.nu
    rm -f ~/.config/nushell/ayu-mirage.nu

    ln -s "$(realpath "nushell/config.nu")" ~/.config/nushell/config.nu
    ln -s "$(realpath "nushell/env.nu")" ~/.config/nushell/env.nu
    ln -s "$(realpath "nushell/git-completions.nu")" ~/.config/nushell/git-completions.nu
    ln -s "$(realpath "nushell/conda.nu")" ~/.config/nushell/conda.nu
    ln -s "$(realpath "nushell/ayu-mirage.nu")" ~/.config/nushell/ayu-mirage.nu

    echo ":: nushell config.nu linked"
    echo ":: nushell env.nu linked"
    echo ":: nushell git-completions.nu linked"
    echo ":: nushell conda.nu linked"
    echo ":: nushell ayu-mirage.nu linked"
fi

# helix conf
if $auto; then
    set_helix=true
elif ask "hexlix config.toml and mytheme.toml?"; then
    set_helix=true
else
    set_helix=false
fi

if $set_helix; then
    mkdir -p ~/.config/helix/
    mkdir -p ~/.config/helix/themes/

    rm -f ~/.config/helix/config.toml
    rm -f ~/.config/helix/themes/mytheme.toml

    ln -s "$(realpath "helix/config.toml")" ~/.config/helix/config.toml
    ln -s "$(realpath "helix/mytheme.toml")" ~/.config/helix/themes/mytheme.toml

    echo ":: helix config.toml linked"
    echo ":: helix mytheme.toml linked"
fi

# starship.rs conf
if $auto; then
    set_starship=true
elif ask "starship.toml?"; then
    set_starship=true
else
    set_starship=false
fi

if $set_starship; then
    rm -f ~/.config/starship.toml
    ln -s "$(realpath "starship/starship.toml")" ~/.config/starship.toml

    echo ":: starship.toml linked"
    echo -e "${RED}!!${NORMAL} Make sure to add equivalent of > \$eval '\$(starship init bash)' < to your shell config"
fi

#-------------------------------------------------------------------------------
if $auto; then
    exit
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

echo
echo ":: Using $SH as selected shell config file"

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
