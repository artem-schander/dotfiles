# tmux aliases
alias ta='tmux attach'
alias tls='tmux ls'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'
alias tks='tmux kill-session -t'

# tmux passes truecolor through (RGB feature); stop Claude Code clamping to 256 colors
export CLAUDE_CODE_TMUX_TRUECOLOR=1
