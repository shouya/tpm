# shared functions and constants

# using @tpm_plugins is now deprecated in favor of using @plugin syntax
tpm_plugins_variable_name="@tpm_plugins"
SHARED_TPM_PATH=""

# sets a "global variable" for the current file
shared_set_tpm_path_constant() {
	local string_path="$(tmux start-server\; show-environment -g TMUX_PLUGIN_MANAGER_PATH | cut -f2 -d=)/"
	# manually expanding tilde or `$HOME` variable.
	string_path="${string_path/#\~/$HOME}"
	SHARED_TPM_PATH="${string_path/#\$HOME/$HOME}"
}

_tmux_conf_contents() {
	cat /etc/tmux.conf ~/.tmux.conf 2>/dev/null
}

shared_get_tpm_plugins_list() {
	# DEPRECATED: lists plugins from @tpm_plugins option
	echo "$(tmux start-server\; show-option -gqv "$tpm_plugins_variable_name")"

	# read set -g @plugin "tmux-plugins/tmux-example-plugin" entries
	_tmux_conf_contents |
		awk '/^ *set +-g +@plugin/ { gsub(/'\''/,""); gsub(/'\"'/,""); print $4 }'
}

# Allowed plugin name formats:
# 1. "git://github.com/user/plugin_name.git"
# 2. "user/plugin_name"
shared_plugin_name() {
	local plugin="$1"
	# get only the part after the last slash, e.g. "plugin_name.git"
	local plugin_basename="$(basename "$plugin")"
	# remove ".git" extension (if it exists) to get only "plugin_name"
	local plugin_name="${plugin_basename%.git}"
	echo "$plugin_name"
}

shared_plugin_path() {
	local plugin=$1
	local plugin_name="$(shared_plugin_name "$plugin")"
	echo "${SHARED_TPM_PATH}${plugin_name}/"
}

# TMUX messaging is weird. You only get a nice clean pane if you do it with
# `run-shell` command.
echo_message() {
	local message="$1"
	tmux run-shell "echo '$message'"
}

reload_tmux_environment() {
	tmux source-file ~/.tmux.conf >/dev/null 2>&1
}

plugin_already_installed() {
	local plugin="$1"
	local plugin_path="$(shared_plugin_path "$plugin")"
	[ -d "$plugin_path" ] &&
		cd "$plugin_path" &&
		git remote >/dev/null 2>&1
}

end_message() {
	echo_message ""
	echo_message "TMUX environment reloaded."
	echo_message ""
	echo_message "Done, press ENTER to continue."
}

ensure_tpm_path_exists() {
	mkdir -p "$SHARED_TPM_PATH"
}

fail_helper() {
	local message="$1"
	echo "$message" >&2
	FAIL="true"
}

exit_value_helper() {
	if [ "$FAIL" == "true" ]; then
		exit 1
	else
		exit 0
	fi
}
