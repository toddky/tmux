#!/usr/bin/env bash
# USAGE: install.sh
# DESCRIPTION: Build and install tmux from source on Debian/Ubuntu.

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
tmux_version=3.5a
tarball_url="https://github.com/tmux/tmux/releases/download/${tmux_version}/tmux-${tmux_version}.tar.gz"


# ==============================================================================
# HELPERS
# ==============================================================================
function error() {
	echo "ERROR: $*" 1>&2
	exit 1
}


# ==============================================================================
# CHECK VERSION
# ==============================================================================
if [[ "$(tmux -V 2>/dev/null)" == "tmux ${tmux_version}" ]]; then
	echo "tmux ${tmux_version} is already installed"
	exit 0
fi


# ==============================================================================
# INSTALL DEPENDENCIES
# ==============================================================================
apt_packages=()
apt_packages+=(build-essential libevent-dev libncurses5-dev bison pkg-config autoconf automake)
if ! sudo apt install -y "${apt_packages[@]}"; then
	error "apt install failed; check sudo access and that this is a Debian/Ubuntu host"
fi


# ==============================================================================
# DOWNLOAD
# ==============================================================================
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

tarball_file="$build_dir/tmux-${tmux_version}.tar.gz"
if ! curl -fLo "$tarball_file" "$tarball_url"; then
	error "cannot download $tarball_url"
fi
if ! tar -xzf "$tarball_file" -C "$build_dir"; then
	error "cannot extract $tarball_file"
fi
source_dir="$build_dir/tmux-${tmux_version}"


# ==============================================================================
# BUILD
# ==============================================================================
# configure has no directory flag, so it runs in a subshell to keep the caller's cwd.
if ! (cd "$source_dir" && ./configure && make); then
	error "tmux build failed in $source_dir"
fi


# ==============================================================================
# INSTALL
# ==============================================================================
if ! sudo make -C "$source_dir" install; then
	error "make install failed"
fi

echo "Installed $(tmux -V)"
