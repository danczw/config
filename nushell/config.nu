# Nushell Config File
#
# version = "0.89.0"

# >----- Scripts -----<
source ~/.config/nushell/git-completions.nu
source ~/.config/nushell/ayu-mirage.nu
use ~/.config/nushell/conda.nu

# >----- Prompt -----<
$env.STARSHIP_SHELL = "nu"
def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

def create_right_prompt [] {
    # let time_segment = ([(date now | format date '%m/%d/%Y %r')] | str join)
    # let host_segment = (sys).host | get hostname
    # let prompt = $"(ansi { fg: '#606670'})(whoami)@($host_segment) | ($time_segment)"
    # $prompt
    starship prompt --right
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = { create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }

# >----- Aliases -----<
# git
alias gs = git status
alias gd = git diff
alias gl = git log
alias gc = git commit

alias gpl = git pull
alias gps = git push
alias gst = git stash

# list
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

    table: {
        mode: none # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        show_empty: false # show 'empty list' and 'empty record' placeholders for command output
    }

    history: {
        file_format: "sqlite" # "sqlite" or "plaintext"
        isolation: false # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
    }

    filesize: {
        metric: true # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
    }

    use_ansi_coloring: true
    render_right_prompt_on_last_line: true # true or false to enable or disable right prompt to be rendered on last line of the prompt.
}
