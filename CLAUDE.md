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
3. Plugin history gets rewritten upstream, so a pointer can name a commit that origin no longer has. Push the plugin before this repo, then check each new pointer: `git -C plugins/<plugin> fetch && git -C plugins/<plugin> merge-base --is-ancestor <sha> origin/master`.
4. tmux.conf loads plugins from `~/.config/tmux/plugins/` and ignores XDG_CONFIG_HOME on purpose; setup.sh always links the repo there. Keep that form.
5. Key bindings go in tmux-prefixless and colors in tmux-chameleon. tmux.conf holds only settings and the plugin loads.

### Verify
- Never test against the running server. Source the config into a throwaway server on its own socket, then remove the socket, which tmux leaves behind:
  ```bash
  sock="$(mktemp -u "${TMPDIR:-/tmp}/tmux-verify.XXXXXX")"; tmux -S "$sock" -f /dev/null new-session -d \; source-file tmux.conf; status=$?; tmux -S "$sock" kill-server; rm -f "$sock"; (exit "$status")
  ```
- Do not use `source-file -n` as a check. It exits 0 even on unknown commands and options.
- The plugins load through run-shell, so their errors show as tmux messages, not as the exit status above. Run the changed plugin's own checks too.
- Apply with `M-F5` only after the checks pass.
