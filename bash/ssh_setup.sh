# Start (or reuse) an ssh-agent for this shell. Shares the env file with
# nushell/ssh-agent.nu so bash and nu use one agent. Keys are added on first
# use via `AddKeysToAgent yes` in ~/.ssh/config.
ssh_env_file=~/.cache/nushell/ssh-agent.env

ssh_agent_alive() {
    [ -S "$SSH_AUTH_SOCK" ] && { [ -z "$SSH_AGENT_PID" ] || kill -0 "$SSH_AGENT_PID" 2>/dev/null; }
}

if ! ssh_agent_alive; then
    [ -f "$ssh_env_file" ] && . "$ssh_env_file" >/dev/null
    if ! ssh_agent_alive; then
        mkdir -p "$(dirname "$ssh_env_file")"
        ssh-agent -s > "$ssh_env_file"
        . "$ssh_env_file" >/dev/null
    fi
fi
