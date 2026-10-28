# The prompt indicators are environmental variables that represent the state of the prompt
# $env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "
$env.PATH = (
  $env.PATH | split row (char esep) |
  append $"($env.HOME)/.local/bin" |
  append $"($env.HOME)/.cargo/bin" |
  append ($env.HOMEBREW_PREFIX? | default "/home/linuxbrew/.linuxbrew" | path join "opt/llvm/bin") |
  append $"($env.HOME)/.local/share/pi-node/current/bin"
)
$env.VIRTUAL_ENV_DISABLE_PROMPT = true
$env.VISUAL = "hx"
$env.EDITOR = "hx"

$env.CARAPACE_BRIDGES = 'bash'
$env.CARAPACE_MATCH = '1'
