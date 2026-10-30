# rig

`rig` starts a small team of Claude agents, one per [zellij](https://github.com/zellij-org/zellij) pane, and lets you talk to them from the shell. `rig help` prints a short reference of everything below.

## Agents

| Role | Job | Tools |
|------|-----|-------|
| `gate` | the only agent you talk to; plans and delegates, does quick lookups itself, never edits | no edit tools, SendMessage |
| `exec` | implements what gate hands over | all, including web |
| `watch` | reviews finished changes | no edit tools |
| `probe` | runs tests and checks, reports pass or fail | no edit tools |
| `crawler` | researches code, docs and the web | no edit tools, plus web |

The default team is `gate`, `exec` and `watch`. Agent definitions live in `claude/agents/rig-<role>.md`.

## Install

`install.sh` (the claude rig step) links the agent files into `~/.claude/agents`, `bin/rig` into `~/.local/bin` and the completion spec into `~/.config/carapace/specs`.

## Quick start

```
rig up "write a bash script hello.sh that prints hello"
```

Inside zellij this opens a `rig` tab; outside it starts a session named `rig-<dir name>`. The optional message is gate's first task. Gate waits until every worker has sent a ready note (with its role), then sends all agents a roster. After that, workers can hand work to each other directly, e.g. exec asks watch to review a finished change, and tell gate in one line.

## Commands

| Command | Does |
|---------|------|
| `rig up [-C dir] [-m model] [-p mode] [-t team] [message]` | start the team, or switch to it if it is running |
| `rig down [-C dir]` | close the rig tab (inside zellij) or kill the session |
| `rig send [-C dir] <pane> <message>` | type a message into one pane (role name or pane id) and press Enter |
| `rig send --list` | list the agent panes as `<name> <pane id> <agent>` |
| `rig model [-C dir] [all\|role] <model>` | type `/model` into every agent, or one |
| `rig broadcast [-C dir] <message>` | send a message to every agent |
| `rig help` | print the reference |

`-C dir` selects the project directory (default: the current one).

## Team definition

A team is `gate` plus 1-5 workers, gate first. Each role needs an agent file `rig-<role>` in `~/.claude/agents`. The source is, first match wins:

1. `-t role[:model[:mode]],...`, e.g. `-t gate,exec:sonnet:plan,watch,probe`
2. `.rig.toml` in the project directory:

   ```toml
   [[agent]]
   role = "gate"

   [[agent]]
   role = "exec"
   model = "sonnet"   # optional
   mode = "plan"      # optional
   ```

3. the default, `gate,exec,watch`

A role's own model or mode overrides `-m` and `-p`.

Layout: gate fills the left side, the workers are stacked on the right in the order given. From four workers on they form two columns.

## Permission modes

`-p` takes `acceptEdits`, `auto`, `dontAsk`, `manual` or `plan` and applies to every agent unless a role sets its own. `bypassPermissions` is not allowed. A worker in `plan` mode cannot edit files until its plan is approved.

## Limits

- `send`, `model` and `broadcast` type into the input box, so they only land while the agents are idle. Newlines are flattened to spaces.
- `rig up` on a running rig only switches to it; the message, `-m`, `-p` and `-t` are ignored (use `rig model`).
- One rig per directory.
- The sessions show up in `claude --resume`; they are named after their role.
- Only `exec` and `crawler` have web access.

## Completion

The carapace spec `carapace/rig.yaml` completes commands, flags, `-p` modes, `-t` roles (read from `~/.claude/agents`) and pane names (from `rig send --list`, only while a rig runs). Check it with `carapace rig export rig up -p ''`.
