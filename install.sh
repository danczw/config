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

link_file() {
    TARGET="$1"
    LINK_NAME="$2"
    mkdir -p "$(dirname "$LINK_NAME")"
    ln -sf "$(realpath "$TARGET")" "$LINK_NAME"
    echo ":: Linked $(basename $LINK_NAME)"
}

setup_config() {
    TOOL="$1"
    FILES=("${@:2}") # Accept multiple file names

    echo -e "${RED}>> Setting up ${TOOL}...${NORMAL}"
    for FILE in "${FILES[@]}"; do
        SRC="${TOOL}/${FILE}"
        DEST="${HOME}/.config/${TOOL}/${FILE}"
        link_file "$SRC" "$DEST"
    done
}

download_with_link() {
    local URL="$1"
    local DEST="$2"
    local TMP
    TMP=$(mktemp)
    if curl -fsSL "$URL" -o "$TMP"; then
        { echo "# based on $URL"; echo; cat "$TMP"; } > "$DEST"
        echo ":: Downloaded $(basename $DEST)"
    else
        echo ":: WARNING: Failed to download $(basename $DEST)"
    fi
    rm -f "$TMP"
}

download_nu_completions() {
    local CARGO_COMP_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/custom-completions/cargo/cargo-completions.nu"
    local CONDA_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/modules/virtual_environments/nu_conda_2/conda.nu"
    local GIT_COMP_URL="https://raw.githubusercontent.com/nushell/nu_scripts/refs/heads/main/custom-completions/git/git-completions.nu"

    if ! command -v curl &>/dev/null; then
        echo ":: WARNING: curl not found — skipping nu completion download"
        return
    fi

    if ! ask "Download nu completions? Existing files will be overwritten"; then
        return
    fi

    echo -e "${RED}>> Downloading nu completions...${NORMAL}"
    download_with_link "$CARGO_COMP_URL" nushell/cargo-completions.nu
    download_with_link "$CONDA_URL"      nushell/conda.nu
    download_with_link "$GIT_COMP_URL"   nushell/git-completions.nu
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
    echo -e "${RED}:: Auto setup enabled${NORMAL}\n"

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

#-------------------------------------------------------------------------------
# alacritty conf
if ! $auto; then
    if ask "alacritty.toml?"; then
        set_alacritty=true
    fi
fi

if $set_alacritty; then
    setup_config alacritty "alacritty.toml"
fi

#-------------------------------------------------------------------------------
# git conf
if ! $auto; then
    if ask "git .gitconfig & .gitignore_global?"; then
        set_git=true
    fi
fi

if $set_git; then
    echo -e "${RED}>> Setting up git...${NORMAL}"
    link_file "git/.gitconfig" "${HOME}/.gitconfig"
    link_file "git/.gitignore_global" "${HOME}/.gitignore_global"
fi

#-------------------------------------------------------------------------------
# helix conf
if ! $auto; then
    if ask "helix config.toml, languages.toml and mytheme.toml?"; then
        set_helix=true
    fi
fi

if $set_helix; then
    setup_config helix "config.toml" "mytheme.toml" "languages.toml"
fi

#-------------------------------------------------------------------------------
# nushell conf
if $dl_files; then
    download_nu_completions
fi

if ! $auto; then
    if ask "nushell config.nu, env.nu & nu scripts?"; then
        set_nushell=true
    fi
fi

if $set_nushell; then
    setup_config nushell "ayu-mirage.nu" "cargo-completions.nu" "conda.nu" "config.nu" "env.nu" "git-completions.nu"
    if nu -c "mkdir (\$nu.data-dir | path join 'vendor/autoload'); starship init nu | save -f (\$nu.data-dir | path join 'vendor/autoload/starship.nu')"; then
        echo ":: Starship nushell integration initialized"
    else
        echo ":: WARNING: Starship nushell init failed — ensure nu and starship are on PATH, then re-run"
    fi
fi

#-------------------------------------------------------------------------------
# starship.rs conf
if ! $auto; then
    if ask "starship.toml?"; then
        set_starship=true
    fi
fi

if $set_starship; then
    setup_config starship "starship.toml"
    echo -e "${NORMAL}:: Note: Add the equivalent of the following to your shell config:"
    echo -e "   eval \"\$(starship init bash)\""
fi

#-------------------------------------------------------------------------------
# yazi conf
if ! $auto; then
    if ask "yazi yazi.toml & theme.toml?"; then
        set_yazi=true
    fi
fi

if $set_yazi; then
    setup_config yazi "yazi.toml" "theme.toml"
fi

#-------------------------------------------------------------------------------
# zellij conf
if ! $auto; then
    if ask "zellij config.kdl?"; then
        set_zellij=true
    fi
fi

if $set_zellij; then
    setup_config zellij "config.kdl"
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
    echo -e "${RED}>> Setting up zoxide...${NORMAL}"
    zoxide_path=~/.config/nushell/zoxide.nu
    zoxide_init_cmd="zoxide init nushell | save -f '$zoxide_path'"

    nu -c "$zoxide_init_cmd"
    echo ":: Generated zoxide.nu"
fi

#-------------------------------------------------------------------------------
if ! $auto; then
    # Bash dotfiles target: bash/zsh only — never nushell (bash source syntax is invalid in .nu files)
    SH="${HOME}/.bashrc"
    if [ -f "${HOME}/.zshrc" ]; then
        SH="${HOME}/.zshrc"
    fi

    echo
    echo ":: Using $SH as selected shell config file"

    if ask "bash dotfiles in $SH?"; then
        if ! grep -q '# -------------- dotfiles install ---------------' "$SH"; then
            echo >> "$SH"
            echo '# -------------- dotfiles install ---------------' >> "$SH"
        fi

        for file in bash/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                filepath="$(realpath "$file")"
                if grep -qF "source $filepath" "$SH"; then
                    echo ":: Already sourced: $filename"
                elif ask "${filename}?"; then
                    echo "source $filepath" >> "$SH"
                fi
            fi
        done
    fi
fi
