#!/usr/bin/env bash
# USAGE: tests/run_tests.sh
# DESCRIPTION: Check tmux.conf in a throwaway tmux server, check each plugin pointer is on its origin, then run each plugin's tests/run_tests.sh.
# Prints PASS or FAIL per check and exits 1 if any check fails. Never touches the running tmux server.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
num_failures=0

# tmux can't open a socket path longer than about 100 characters, and $TMPDIR may already be that long.
if ! socket_dir="$(mktemp -d /tmp/tmux-check.XXXXXX)"; then
	echo "ERROR: run_tests.sh: cannot create a socket directory in /tmp" 1>&2
	exit 1
fi
socket_file="$socket_dir/socket"
trap 'command tmux -S "$socket_file" kill-server 2>/dev/null; rm -rf "$socket_dir"' EXIT


# ==============================================================================
# HELPERS
# ==============================================================================
function tmux() {
	command tmux -S "$socket_file" "$@"
}

function pass() {
	echo "PASS: $*"
}

function fail() {
	echo "FAIL: $*"
	num_failures=$((num_failures + 1))
}


# ==============================================================================
# CHECK CONFIG
# ==============================================================================
# tmux.conf loads the plugins installed under ~/.config/tmux, not the ones in this checkout if it lives elsewhere.
# source-file -n exits 0 even on unknown commands, and a plugin that fails to load exits 0 too; any output is an error.
if ! tmux -f /dev/null new-session -d; then
	fail "cannot start a throwaway tmux server on $socket_file"
elif ! output="$(tmux source-file tmux.conf 2>&1)" || [[ -n "$output" ]]; then
	fail "tmux.conf: $output"
else
	pass "tmux.conf loads"
fi


# ==============================================================================
# CHECK POINTERS
# ==============================================================================
# Plugin history gets rewritten upstream, so a committed pointer can name a commit its origin no longer has.
mapfile -t plugin_dirs < <(git config -f .gitmodules --get-regexp '\.path$' | awk '{print $2}')
for plugin_dir in "${plugin_dirs[@]}"; do
	if ! pointer="$(git rev-parse "HEAD:$plugin_dir" 2>&1)"; then
		fail "$plugin_dir: no committed pointer: $pointer"
		continue
	fi
	if ! output="$(git -C "$plugin_dir" fetch -q origin 2>&1)"; then
		fail "$plugin_dir: cannot fetch origin: $output"
		continue
	fi
	if ! git -C "$plugin_dir" merge-base --is-ancestor "$pointer" origin/HEAD 2>/dev/null; then
		fail "$plugin_dir: committed pointer $pointer is not on origin; push the plugin or commit a newer pointer"
		continue
	fi
	pass "$plugin_dir: committed pointer is on origin"
done


# ==============================================================================
# CHECK PLUGINS
# ==============================================================================
for plugin_dir in "${plugin_dirs[@]}"; do
	if [[ ! -x "$plugin_dir/tests/run_tests.sh" ]]; then
		continue
	fi
	echo "--- $plugin_dir/tests/run_tests.sh"
	if ! "$plugin_dir/tests/run_tests.sh"; then
		fail "$plugin_dir/tests/run_tests.sh"
	fi
done


# ==============================================================================
# REPORT
# ==============================================================================
if ((num_failures > 0)); then
	echo "$num_failures check(s) failed"
	exit 1
fi
echo "all checks passed"

