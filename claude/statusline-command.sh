#!/usr/bin/env bash

input=$(cat)

current_time=$(date +%H:%M:%S)
current_user=$(whoami)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
context_used=$(echo "$input" | jq -r '
  if .context_window.used_percentage != null then
    .context_window.used_percentage
  elif .context_window.current_usage != null then
    (.context_window.current_usage.input_tokens
     + (.context_window.current_usage.cache_creation_input_tokens // 0)
     + (.context_window.current_usage.cache_read_input_tokens // 0))
    / .context_window.context_window_size * 100
  else
    empty
  end
')
five_hour_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Renders a block progress bar (████░░░░░░) for a given percentage (0-100)
render_bar() {
    local pct_int
    pct_int=$(printf '%.0f' "$1")
    [ "$pct_int" -lt 0 ] && pct_int=0
    [ "$pct_int" -gt 100 ] && pct_int=100

    local width=10
    local filled=$(( (pct_int * width + 50) / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width

    local empty=$((width - filled))
    local bar=""
    local i
    for ((i = 0; i < filled; i++)); do bar="${bar}█"; done
    for ((i = 0; i < empty; i++)); do bar="${bar}░"; done
    echo "$bar"
}

# Picks an ANSI color code based on usage severity (green/yellow/red)
severity_color() {
    local pct_int
    pct_int=$(printf '%.0f' "$1")
    if [ "$pct_int" -ge 80 ]; then
        echo '0;31' # red
    elif [ "$pct_int" -ge 50 ]; then
        echo '0;33' # yellow
    else
        echo '0;32' # green
    fi
}

# Git branch (skip optional lock to avoid blocking)
git_branch=""
if [ -n "$current_dir" ] && [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$current_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
fi

# Build output using printf for ANSI colors
# Spaceship-inspired: time | user | dir | git | model | context
output=""

# Time (cyan)
output="${output}$(printf '\033[0;36m%s\033[0m' "$current_time")"

# User (green)
output="${output} $(printf '\033[0;32m%s\033[0m' "$current_user")"

# Dir (bold blue)
if [ -n "$current_dir" ]; then
    short_dir=$(echo "$current_dir" | sed "s|$HOME|~|")
    output="${output} $(printf '\033[0;34m%s\033[0m' "$short_dir")"
fi

# Git branch (magenta with  symbol)
if [ -n "$git_branch" ]; then
    output="${output} $(printf '\033[0;35m %s\033[0m' "$git_branch")"
fi

# Model (yellow)
if [ -n "$model_name" ]; then
    output="${output} $(printf '\033[0;33m%s\033[0m' "$model_name")"
fi

# Context usage as a progress bar, color-coded by severity
if [ -n "$context_used" ]; then
    context_formatted=$(printf '%.0f' "$context_used")
    context_bar=$(render_bar "$context_used")
    context_color=$(severity_color "$context_used")
    output="${output} $(printf "\033[%sm%s %s%%\033[0m" "$context_color" "$context_bar" "$context_formatted")"
fi

# 5-hour rate limit usage (blue)
if [ -n "$five_hour_used" ]; then
    five_hour_formatted=$(printf '%.0f' "$five_hour_used")
    output="${output} $(printf '\033[0;34m5h:%s%%\033[0m' "$five_hour_formatted")"
fi

# 7-day rate limit usage (magenta)
if [ -n "$seven_day_used" ]; then
    seven_day_formatted=$(printf '%.0f' "$seven_day_used")
    output="${output} $(printf '\033[0;35m7d:%s%%\033[0m' "$seven_day_formatted")"
fi

echo "$output"
