# Nushell Config File

# >----- Scripts -----<
source ~/.config/nushell/ayu-mirage.nu
source ~/.config/nushell/cargo-completions.nu
source ~/.config/nushell/git-completions.nu
source ~/.config/nushell/zoxide.nu
use ~/.config/nushell/conda.nu

# >----- Prompt -----<
$env.STARSHIP_SHELL = "nu"
def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

def create_right_prompt [] {
    starship prompt --right
}

def create_right_transient_prompt [] {
    let time_segment = ([(date now | format date '%H:%M:%S ')] | str join)
    let prompt = $"(ansi { fg: '#686868'})($time_segment)"
    $prompt
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = { create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { $"(ansi { fg: '#606670'})(':: ')" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { create_right_prompt }

# >----- Aliases -----<
# git
alias gs = git status
alias gd = git diff
alias gl = git log
alias gc = git commit

alias gpl = git pull
alias gps = git push
alias gst = git stash
alias gsw = git switch

alias ga. = git add .
alias gap = git add -p

# list
alias ls = ls -a
alias ll = ls -la

# misc
alias today = date now

# navigation
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..
alias home = cd ~

# environment
def --env lenv [] {
    let env_toml = open .env | from toml;
    print $"Loading .env - ($env_toml)";
    load-env $env_toml;
}

# python
alias venv = sh -i -c '. .venv/bin/activate ; nu'

# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
# And here is the theme collection
# https://github.com/nushell/nu_scripts/tree/main/themes

$env.config = {
    show_banner: false # true or false to enable or disable the welcome banner at startup

    cursor_shape: {
        emacs: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (line is the default)
        vi_insert: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (block is the default)
        vi_normal: underscore # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (underscore is the default)
    }

    table: {
        mode: none # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        show_empty: false # show 'empty list' and 'empty record' placeholders for command output
    }

    use_ansi_coloring: true
    render_right_prompt_on_last_line: true # true or false to enable or disable right prompt to be rendered on last line of the prompt.
}
