#!/usr/bin/env bash
declare -r cmd=$(tmux display-message -p '#{pane_current_command}')

case "$cmd" in

	# Keep pane alive if running LSF job
	nios)
		tmux display-message "Unable to kill-pane running '$cmd'"
		;;

	# Confirm before killing pane
	vim|ssh)
		tmux confirm-before -p "kill-pane running '$cmd'? (y/n)" kill-pane
		;;

	# Kill pane running zsh
	zsh)
		tmux kill-pane
		;;

	*)
		tmux confirm-before -p "kill-pane running '$cmd'? (y/n)" kill-pane
		;;
esac

