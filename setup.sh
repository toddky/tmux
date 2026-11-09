#!/usr/bin/env bash
# USAGE: setup.sh
# DESCRIPTION: Link this repo to ~/.config/tmux, remove legacy ~/.tmux links, and install plugins.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
now="$(date +%Y%m%d-%H%M%S)"

# tmux.conf and plugins.conf hardcode ~/.config/tmux, so this ignores XDG_CONFIG_HOME on purpose.
config_dir="$HOME/.config/tmux"

# Print stderr in red
exec 2> >(while IFS= read -r line; do echo -e "\e[31m[stderr]\e[0m $line"; done)


# ==============================================================================
# HELPERS
# ==============================================================================
function print_step() {
	echo -e "\e[34m$*\e[0m"
}

function error() {
	echo "ERROR: $*" 1>&2
	exit 1
}

function backup() {
	local file="$1"
	print_step "Backing up $file to $file.$now..."
	if ! mv "$file" "$file.$now"; then
		error "cannot back up $file"
	fi
}


# ==============================================================================
# LINK CONFIG
# ==============================================================================
if [[ "$(realpath "$config_dir" 2>/dev/null)" != "$SCRIPT_DIR" ]]; then
	print_step "Creating $config_dir symlink..."
	if ! mkdir -p "$(dirname "$config_dir")"; then
		error "cannot create $(dirname "$config_dir")"
	fi
	if [[ -e "$config_dir" || -L "$config_dir" ]]; then
		backup "$config_dir"
	fi
	if ! ln -s "$SCRIPT_DIR" "$config_dir"; then
		error "cannot link $config_dir to $SCRIPT_DIR"
	fi
fi


# ==============================================================================
# REMOVE LEGACY LINKS
# ==============================================================================
# ~/.tmux.conf takes precedence over ~/.config/tmux/tmux.conf, so it must not exist.
for legacy_file in "$HOME/.tmux" "$HOME/.tmux.conf"; do
	[[ -e "$legacy_file" || -L "$legacy_file" ]] || continue
	if [[ -L "$legacy_file" && "$(realpath "$legacy_file" 2>/dev/null)" == "$SCRIPT_DIR"* ]]; then
		print_step "Removing legacy $legacy_file symlink..."
		if ! rm "$legacy_file"; then
			error "cannot remove $legacy_file"
		fi
		continue
	fi
	backup "$legacy_file"
done


# ==============================================================================
# INSTALL PLUGINS
# ==============================================================================
print_step "Installing tmux plugins..."
if ! git submodule sync; then
	error "git submodule sync failed"
fi
if ! git submodule update --init --recursive; then
	error "git submodule update failed; commit or stash local changes in plugins/ and rerun"
fi


# ==============================================================================
# ADD SSH REMOTES
# ==============================================================================
# Fetch over HTTPS so a fresh host needs no keys; push over SSH so pushes don't need a token.
print_step "Adding github (SSH) remotes..."
mapfile -t submodule_dirs < <(git submodule foreach --quiet 'echo "$sm_path"')
for submodule_dir in "${submodule_dirs[@]}"; do
	https_url="$(git -C "$submodule_dir" remote get-url origin)"
	ssh_url="${https_url/#https:\/\/github.com\//git@github.com:}"
	[[ "$ssh_url" != "$https_url" ]] || continue

	# --replace-all keeps reruns from stacking duplicate push URLs.
	if ! git -C "$submodule_dir" config --replace-all remote.origin.pushurl "$ssh_url"; then
		error "cannot set push URL for $submodule_dir"
	fi
	if git -C "$submodule_dir" remote get-url github &>/dev/null; then
		git -C "$submodule_dir" remote set-url github "$ssh_url"
	else
		git -C "$submodule_dir" remote add github "$ssh_url"
	fi
done
