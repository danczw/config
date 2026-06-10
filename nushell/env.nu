# The prompt indicators are environmental variables that represent the state of the prompt
# $env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "
$env.PATH = (
  $env.PATH | split row (char esep) |
  append $"($env.HOME)/.cargo/bin" |
  append (try { $"(brew --prefix)/opt/llvm/bin" } catch { [] }) |
  append $"($env.HOME)/.local/share/pi-node/node-v22.22.3-linux-x64/bin"
)
$env.CONDA_NO_PROMPT = true
$env.VIRTUAL_ENV_DISABLE_PROMPT = true
$env.VISUAL = "hx"
$env.EDITOR = "hx"

$env.CARAPACE_BRIDGES = 'bash'
$env.CARAPACE_MATCH = '1'

mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
