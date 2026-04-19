#!/usr/bin/env bash
set -e

VERSION=3.5a

if [[ "$(tmux -V 2>/dev/null)" == "tmux ${VERSION}" ]]; then
    echo "tmux ${VERSION} is already installed"
    exit 0
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

sudo apt install -y build-essential libevent-dev libncurses5-dev bison pkg-config autoconf automake

curl -Lo "$TMPDIR/tmux-${VERSION}.tar.gz" "https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz"
tar -xzf "$TMPDIR/tmux-${VERSION}.tar.gz" -C "$TMPDIR"
cd "$TMPDIR/tmux-${VERSION}"
./configure && make
sudo make install

echo "Installed tmux $(tmux -V)"
