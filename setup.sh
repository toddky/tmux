#!/usr/bin/env bash
declare -r CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CURRENT_DIR"
declare -r now=$(date +%Y%m%d-%H%M%S)

# Print stderr in red
exec 2> >(while read line; do echo -e "\e[31m[stderr]\e[0m $line"; done)

# Print custom pipe in blue
exec 5> >(while read line; do echo -e "\e[34m$line\e[0m"; done)

# Immediately exit on failure
set -eo pipefail
#set -euo pipefail

IFS=$'\n\t'

current_tmux=$(readlink -f ~/.tmux)
current_tmux_conf=$(readlink -f ~/.tmux)

# Create ~/.tmux symlink
if [[ $current_tmux != "$CURRENT_DIR" ]]; then
	echo "Creating ~/.tmux symlink..." 1>&5
	[[ -e ~/.tmux ]] && rm ~/.tmux
	ln -sf "$CURRENT_DIR" ~/.tmux
fi

# Create ~/.tmux.conf symlink
if [[ $current_tmux_conf != "$CURRENT_DIR/tmux.conf" ]]; then
	echo "Creating ~/.tmux.conf symlink..." 1>&5
	[[ -e ~/.tmux.conf ]] && mv ~/.tmux.conf ~/.tmux.conf.$now
	ln -sf "$CURRENT_DIR/tmux.conf" ~/.tmux.conf
fi

# Install plugins
echo "Installing tmux plugins..." 1>&5
git submodule update --init --remote --recursive
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/clean_plugins"
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/install_plugins"
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/update_plugins all"

