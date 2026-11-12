### Layout
```
.
├── tmux.conf            # settings; loads each plugin with run-shell at the bottom
├── setup.sh             # links this repo to ~/.config/tmux and removes legacy ~/.tmux links
├── install.sh           # builds tmux from source on Debian/Ubuntu
└── plugins/             # git submodules, each its own public GitHub repo
    ├── tmux-prefixless/ # key bindings and the scripts they run; has its own CLAUDE.md
    └── tmux-chameleon/  # colorscheme and status line
```

### Rules
1. This repo and both plugins are public on GitHub. Never add hostnames, internal paths, or anything that names private scripts' locations.
2. Commit plugin changes inside the plugin's repo first. Then commit the new submodule pointer in this repo on its own, as `⬆️ plugins: Update <plugin>.`
3. Plugin history gets rewritten upstream, so a pointer can name a commit that origin no longer has. If you push, push the plugin first. Before pushing this repo, check the committed pointer:
   ```bash
   sha="$(git rev-parse HEAD:plugins/<plugin>)"; git -C plugins/<plugin> fetch -q && git -C plugins/<plugin> merge-base --is-ancestor "$sha" origin/master && echo "ok: $sha" || echo "NOT on origin: $sha"
   ```
4. tmux.conf loads plugins from `~/.config/tmux/plugins/` and ignores XDG_CONFIG_HOME on purpose; setup.sh always links the repo there. Keep that form.
5. Key bindings go in tmux-prefixless and colors in tmux-chameleon. tmux.conf holds only settings, hooks and the plugin loads.

### Verify
- Never test against the running server. Source the config into a throwaway server on its own socket, then remove the socket, which tmux leaves behind. The socket lives in `/tmp`, not `$TMPDIR`: tmux fails with `File name too long` past about 100 characters.
  ```bash
  sock="$(mktemp -u /tmp/tmux-verify.XXXXXX)"; out="$(tmux -S "$sock" -f /dev/null new-session -d \; source-file tmux.conf 2>&1)"; status=$?; tmux -S "$sock" kill-server; rm -f "$sock"; printf '%s\n' "$out"; [ "$status" = 0 ] && [ -z "$out" ]
  ```
- Any output is a failure, even with exit status 0. A plugin that fails to load only prints `'.../<plugin>.tmux' returned 1`.
- Do not use `source-file -n` as a check. It exits 0 even on unknown commands and options.
- This check loads the plugins installed under `~/.config/tmux`, not the ones in a worktree or other checkout. Run the changed plugin's own checks too.
- Apply with `M-F5` only after the checks pass.
