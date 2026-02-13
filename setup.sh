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
git submodule sync
git submodule update --init --remote --recursive

# Add SSH remotes named "github" for each submodule
echo "Adding github (SSH) remotes..." 1>&5
git submodule foreach '
	https_url=$(git remote get-url origin)
	ssh_url=$(echo "$https_url" | sed "s|https://github.com/|git@github.com:|")
	if [ "$https_url" != "$ssh_url" ]; then
		git remote set-url --add --push origin "$ssh_url"
		git remote add github "$ssh_url" 2>/dev/null || git remote set-url github "$ssh_url"
	fi
'
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/clean_plugins"
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/install_plugins"
tmux run-shell "$CURRENT_DIR/plugins/tpm/bin/update_plugins all"

