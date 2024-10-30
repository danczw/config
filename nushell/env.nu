# The prompt indicators are environmental variables that represent the state of the prompt
# $env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "
$env.PATH = ($env.PATH | split row (char esep) | append $"($env.HOME)/.cargo/bin")
$env.CONDA_NO_PROMPT = true
$env.VISUAL = "helix"
$env.EDITOR = "helix"
