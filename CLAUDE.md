### Layout
```
.
├── tmux.conf            # settings; loads each plugin with run-shell at the bottom
├── setup.sh             # links this repo to ~/.config/tmux and removes legacy ~/.tmux links
├── install.sh           # builds tmux from source on Debian/Ubuntu
├── tests/run_tests.sh   # checks tmux.conf, the plugin pointers, and runs each plugin's tests
└── plugins/             # git submodules, each its own public GitHub repo
    ├── tmux-prefixless/ # key bindings and the scripts they run; has its own CLAUDE.md
    └── tmux-chameleon/  # colorscheme and status line
```

### Rules
1. This repo and both plugins are public on GitHub. Never add hostnames, internal paths, or anything that names private scripts' locations.
2. Commit plugin changes inside the plugin's repo first. Then commit the new submodule pointer in this repo on its own, as `⬆️ plugins: Update <plugin>.`
3. Plugin history gets rewritten upstream, so a pointer can name a commit that origin no longer has. If you push, push the plugin first, and push this repo only once `tests/run_tests.sh` passes its pointer checks.
4. tmux.conf loads plugins from `~/.config/tmux/plugins/` and ignores XDG_CONFIG_HOME on purpose; setup.sh always links the repo there. Keep that form.
5. Key bindings go in tmux-prefixless and colors in tmux-chameleon. tmux.conf holds only settings, hooks and the plugin loads.

### Verify
- Run `tests/run_tests.sh`. It loads tmux.conf in a throwaway server, checks each committed plugin pointer is on its origin, then runs each plugin's own `tests/run_tests.sh`. It must exit 0.
- Never test against the running server, and never use `source-file -n` as a check; it exits 0 even on unknown commands and options.
- tmux.conf loads the plugins installed under `~/.config/tmux`, not the ones in a worktree or other checkout.
- Apply with `M-F5` only after `tests/run_tests.sh` passes.
