# Start (or reuse) an ssh-agent for this shell. The agent's env is cached at
# ~/.cache/ssh-agent.env so multiple shells share one agent. Pair with
# `AddKeysToAgent yes` in ~/.ssh/config — keys are then added on first use.

let ssh_env_file = ($nu.cache-dir | path join "ssh-agent.env")

def --env load-ssh-agent-env [path: string] {
    if not ($path | path exists) { return false }
    let pairs = (
        open --raw $path
        | lines
        | where {|l| $l | str starts-with "SSH_" }
        | parse '{name}={value}; export {_};'
        | select name value
    )
    if ($pairs | is-empty) { return false }
    load-env ($pairs | reduce --fold {} {|it, acc| $acc | upsert $it.name $it.value })
    true
}

def is-ssh-agent-alive [] {
    if ($env.SSH_AUTH_SOCK? | is-empty) { return false }
    if not ($env.SSH_AUTH_SOCK | path exists) { return false }
    if ($env.SSH_AGENT_PID? | is-empty) { return true }
    (do -i { ^kill -0 $env.SSH_AGENT_PID } | complete | get exit_code) == 0
}

if not (is-ssh-agent-alive) {
    if (load-ssh-agent-env $ssh_env_file) and (is-ssh-agent-alive) {
        # reused agent from $ssh_env_file
    } else {
        mkdir ($ssh_env_file | path dirname)
        ^ssh-agent -s | save -f $ssh_env_file
        load-ssh-agent-env $ssh_env_file | ignore
    }
}
