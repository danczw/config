#!/bin/bash
# Install script for the dotfiles

NORMAL=$'\e[0m'
RED=$'\e[31m'

# Ask Y/n
function ask() {
    read -p "Use ${RED}${1}${NORMAL} (Y/n): " resp
    if [ -z "$resp" ]; then
        response_lc="y" # empty is Yes
    else
        response_lc=$(echo "$resp" | tr '[:upper:]' '[:lower:]') # case insensitive
    fi

    [ "$response_lc" = "y" ]
}

#-------------------------------------------------------------------------------

auto=false
dl_files=false

while getopts 'al' option; do
    case $option in
        a) auto=true ;;
        l) dl_files=true;;
        *) continue
    esac
done


set_alacritty=false
set_git=false
set_helix=false
set_nushell=false
set_starship=false
set_yazi=false
set_zellij=false
set_zoxide=false

if $auto; then
    echo -e "${RED}!!${NORMAL} Auto setup\n"

    set_git=true
    set_helix=true
    set_nushell=true
    set_starship=true
    set_yazi=true
    set_zellij=true
    set_zoxide=true
else
    echo ":: Manual setup"
fi

mkdir -p ~/.config/

#-------------------------------------------------------------------------------
# alacritty conf
if ! $auto; then
    if ask "alacritty.toml?"; then
        set_alacritty=true
    fi
fi

if $set_alacritty; then
    mkdir -p ~/.config/alacritty/
    ln -sf "$(realpath "alacritty/alacritty.toml")" ~/.config/alacritty/alacritty.toml
    echo ":: alacritty.toml linked"
fi

#-------------------------------------------------------------------------------
# git conf
if ! $auto; then
    if ask "git .gitconfig & .gitignore_global?"; then
        set_git=true
    fi
fi

if $set_git; then
    ln -sf "$(realpath "git/.gitconfig")" ~/.gitconfig
    ln -sf "$(realpath "git/.gitignore_global")" ~/.config/alacritty/alacritty.toml
    echo ":: git .gitconfig linked"
    echo ":: git .gitignore_global linked"
fi

#-------------------------------------------------------------------------------
# helix conf
if ! $auto; then
    if ask "helix config.toml, languages.toml and mytheme.toml?"; then
        set_helix=true
    fi
fi

if $set_helix; then
    mkdir -p ~/.config/helix/
    mkdir -p ~/.config/helix/themes/

    ln -sf "$(realpath "helix/config.toml")" ~/.config/helix/config.toml
    ln -sf "$(realpath "helix/mytheme.toml")" ~/.config/helix/themes/mytheme.toml
    ln -sf "$(realpath "helix/languages.toml")" ~/.config/helix/languages.toml

    echo ":: helix config.toml linked"
    echo ":: helix mytheme.toml linked"
    echo ":: helix languages.toml linked"
fi

#-------------------------------------------------------------------------------
# nushell conf
# CARGO_COMP_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/custom-completions/cargo/cargo-completions.nu"
# CONDA_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/modules/virtual_environments/nu_conda_2/conda.nu"
# GIT_COMP_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/custom-completions/git/git-completions.nu"

if ! $auto; then
    if ask "nushell config.nu, env.nu & nu scripts?"; then
        set_nushell=true
    fi
fi

if $set_nushell; then
    mkdir -p ~/.config/nushell/

    nu_files=("ayu-mirage.nu" "cargo-completions.nu" "conda.nu" "config.nu" "env.nu" "git-completions.nu")

    for file in "${nu_files[@]}"; do
        ln -sf "$(realpath "nushell/$file")" "$HOME/.config/nushell/$file"
        echo ":: nushell $file linked"
    done
fi

#-------------------------------------------------------------------------------
# starship.rs conf
if ! $auto; then
    if ask "starship.toml?"; then
        set_starship=true
    fi
fi

if $set_starship; then
    ln -sf "$(realpath "starship/starship.toml")" ~/.config/starship.toml

    echo ":: starship.toml linked"
    echo -e "   ${RED}!!${NORMAL} Make sure to add equivalent of > \$eval '\$(starship init bash)' < to your shell config"
fi

#-------------------------------------------------------------------------------
# yazi conf
if ! $auto; then
    if ask "yazi yazi.toml & theme.toml?"; then
        set_yazi=true
    fi
fi

if $set_yazi; then
    mkdir -p ~/.config/yazi/
    ln -sf "$(realpath "yazi/yazi.toml")" ~/.config/yazi/yazi.toml
    ln -sf "$(realpath "yazi/theme.toml")" ~/.config/yazi/theme.toml
    echo ":: yazi yazi.toml linked"
    echo ":: yazi theme.toml linked"
fi

#-------------------------------------------------------------------------------
# zellij conf
if ! $auto; then
    if ask "zellij config.kdl?"; then
        set_zellij=true
    fi
fi

if $set_zellij; then
    mkdir -p ~/.config/zellij/
    ln -sf "$(realpath "zellij/config.kdl")" ~/.config/zellij/config.kdl
    echo ":: zellij config.kdl linked"

    # mkdir -p ~/.config/zellij/layouts/
    # rm -f ~/.config/zellij/layouts/default.kdl
    # ln -s "$(realpath "zellij/layouts/default.kdl")" ~/.config/zellij/layouts/default.kdl
fi

#-------------------------------------------------------------------------------
# zoxide conf
if ! $auto; then
    if ask "init zoxide?"; then
        set_zoxide=true
    fi
fi

if $set_zoxide; then
    zoxide_path=~/.config/nushell/zoxide.nu
    zoxide_init_cmd="zoxide init nushell | save -f '$zoxide_path'"

    nu -c "$zoxide_init_cmd"
    echo ":: zoxide initialized"
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
