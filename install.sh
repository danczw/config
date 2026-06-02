#!/bin/bash
# Install script for the dotfiles

NORMAL=$'\e[0m'
RED=$'\e[31m'

# Prompt the user with a Y/n question; returns 0 for yes, 1 for no.
ask() {
    read -p "Use ${RED}${1}${NORMAL} (Y/n): " resp
    if [ -z "$resp" ]; then
        response_lc="y"
    else
        response_lc=$(echo "$resp" | tr '[:upper:]' '[:lower:]')
    fi

    [ "$response_lc" = "y" ]
}

# Create a symlink from TARGET to LINK_NAME, creating parent dirs as needed.
link_file() {
    TARGET="$1"
    LINK_NAME="$2"
    mkdir -p "$(dirname "$LINK_NAME")"
    ln -sf "$(realpath "$TARGET")" "$LINK_NAME"
    echo ":: Linked $(basename $LINK_NAME)"
}

# Symlink all given FILES from the TOOL source dir into ~/.config/TOOL/.
setup_config() {
    TOOL="$1"
    FILES=("${@:2}")

    echo -e "${RED}>> Setting up ${TOOL}...${NORMAL}"
    for FILE in "${FILES[@]}"; do
        SRC="${TOOL}/${FILE}"
        DEST="${HOME}/.config/${TOOL}/${FILE}"
        link_file "$SRC" "$DEST"
    done
}

# Download URL to DEST, prepending a source comment at the top of the file.
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

# Download the latest nu completion scripts from nushell/nu_scripts into nushell/.
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

# In manual mode, ask whether to set up TOOL; in auto mode, run only if auto_<tool>=true.
# Returns 1 if skipped, 0 if setup ran. Remaining args are passed to setup_config.
maybe_setup() {
    local tool="$1"; local prompt="$2"; shift 2
    local auto_var="auto_${tool}"
    if $auto; then
        ${!auto_var} || return 1
    elif ! ask "$prompt"; then
        return 1
    fi
    setup_config "$tool" "$@"
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

# Tools included in auto setup (-a); set to false to skip a tool without removing it
auto_alacritty=false  # terminal-specific, opt-in only
auto_git=true
auto_helix=true
auto_nushell=true
auto_ssh=true
auto_starship=true
auto_yazi=true
auto_zellij=true
auto_zoxide=true

if $auto; then
    echo -e "${RED}:: Auto setup enabled${NORMAL}\n"
else
    echo ":: Manual setup"
fi

#-------------------------------------------------------------------------------
# alacritty conf — links to ~ not ~/.config, so handled separately
if { $auto && $auto_alacritty; } || { ! $auto && ask "alacritty.toml?"; }; then
    setup_config alacritty "alacritty.toml"
fi

#-------------------------------------------------------------------------------
# git conf — links to ~ not ~/.config, so handled separately
if { $auto && $auto_git; } || { ! $auto && ask "git .gitconfig & .gitignore_global?"; }; then
    echo -e "${RED}>> Setting up git...${NORMAL}"
    link_file "git/.gitconfig" "${HOME}/.gitconfig"
    link_file "git/.gitignore_global" "${HOME}/.gitignore_global"
fi

#-------------------------------------------------------------------------------
# ssh conf — links to ~/.ssh, plus creates the ControlPath socket directory
if { $auto && $auto_ssh; } || { ! $auto && ask "ssh config?"; }; then
    echo -e "${RED}>> Setting up ssh...${NORMAL}"
    mkdir -p ~/.ssh/cm
    chmod 700 ~/.ssh ~/.ssh/cm
    link_file "ssh/config" "${HOME}/.ssh/config"
fi

#-------------------------------------------------------------------------------
# nushell conf
if $dl_files; then
    download_nu_completions
fi

if maybe_setup nushell "nushell config.nu, env.nu & nu scripts?" \
    "ayu-mirage.nu" "cargo-completions.nu" "conda.nu" "config.nu" "env.nu" "git-completions.nu"; then
    if nu -c "mkdir (\$nu.data-dir | path join 'vendor/autoload'); starship init nu | save -f (\$nu.data-dir | path join 'vendor/autoload/starship.nu')"; then
        echo ":: Starship nushell integration initialized"
    else
        echo ":: WARNING: Starship nushell init failed — ensure nu and starship are on PATH, then re-run"
    fi
fi

#-------------------------------------------------------------------------------
if maybe_setup starship "starship.toml?" "starship.toml"; then
    echo -e "${NORMAL}:: Note: Add the equivalent of the following to your shell config:"
    echo -e "   eval \"\$(starship init bash)\""
fi

maybe_setup helix  "helix config.toml, languages.toml and mytheme.toml?" "config.toml" "mytheme.toml" "languages.toml"
maybe_setup yazi   "yazi yazi.toml & theme.toml?" "yazi.toml" "theme.toml"
maybe_setup zellij "zellij config.kdl?" "config.kdl"

#-------------------------------------------------------------------------------
# zoxide — generates a file rather than symlinking, so handled separately
if { $auto && $auto_zoxide; } || { ! $auto && ask "init zoxide?"; }; then
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
