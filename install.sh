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

while getopts 'a' option; do
    case $option in
        a) auto=true ;;
        *) continue
    esac
done

# Tools included in auto setup (-a); set to false to skip a tool without removing it
auto_claude=true
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
# claude rig — agent files go to ~/.claude/agents (linked individually to keep existing agents), launcher to ~/.local/bin
if { $auto && $auto_claude; } || { ! $auto && ask "claude rig?"; }; then
    echo -e "${RED}>> Setting up claude rig...${NORMAL}"
    for agent in claude/agents/*.md; do
        link_file "$agent" "${HOME}/.claude/agents/$(basename "$agent")"
    done
    link_file "bin/rig" "${HOME}/.local/bin/rig"
fi

#-------------------------------------------------------------------------------
# git conf — links to ~ not ~/.config, so handled separately
if { $auto && $auto_git; } || { ! $auto && ask "git?"; }; then
    echo -e "${RED}>> Setting up git...${NORMAL}"
    link_file "git/.gitconfig" "${HOME}/.gitconfig"
    link_file "git/.gitignore_global" "${HOME}/.gitignore_global"
fi

#-------------------------------------------------------------------------------
# ssh conf — links to ~/.ssh, plus creates the ControlPath socket directory
if { $auto && $auto_ssh; } || { ! $auto && ask "ssh?"; }; then
    echo -e "${RED}>> Setting up ssh...${NORMAL}"
    mkdir -p ~/.ssh/cm
    chmod 700 ~/.ssh ~/.ssh/cm
    link_file "ssh/config" "${HOME}/.ssh/config"
fi

#-------------------------------------------------------------------------------
# nushell conf
if maybe_setup nushell "nushell?" \
    "ayu-mirage.nu" "config.nu" "env.nu" "ssh-agent.nu"; then
    # Generated once here instead of on every shell start; re-run after upgrading starship/carapace
    if nu -c "let dir = (\$nu.data-dir | path join 'vendor/autoload'); mkdir \$dir; starship init nu | save -f (\$dir | path join 'starship.nu'); carapace _carapace nushell | save -f (\$dir | path join 'carapace.nu')"; then
        echo ":: Starship and carapace nushell integrations initialized"
    else
        echo ":: WARNING: nushell init failed — ensure nu, starship and carapace are on PATH, then re-run"
    fi
fi

#-------------------------------------------------------------------------------
# starship conf — links to ~/.config/starship.toml (its default path), so handled separately
if { $auto && $auto_starship; } || { ! $auto && ask "starship?"; }; then
    echo -e "${RED}>> Setting up starship...${NORMAL}"
    link_file "starship/starship.toml" "${HOME}/.config/starship.toml"
    echo -e "${NORMAL}:: Note: Add the equivalent of the following to your shell config:"
    echo -e "   eval \"\$(starship init bash)\""
fi

maybe_setup helix  "helix?"  "config.toml" "mytheme.toml" "languages.toml" "ignore"
maybe_setup yazi   "yazi?"   "yazi.toml"
maybe_setup zellij "zellij?" "config.kdl"

#-------------------------------------------------------------------------------
# zoxide — generates a file rather than symlinking, so handled separately
if { $auto && $auto_zoxide; } || { ! $auto && ask "zoxide?"; }; then
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
