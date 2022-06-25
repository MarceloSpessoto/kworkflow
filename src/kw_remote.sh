include "$KW_LIB_DIR/kwlib.sh"
include "$KW_LIB_DIR/remote.sh"

declare -gA options_values
declare -g local_remote_config_file="${PWD}/.kw/remote.config"

function remote_main()
{
  if [[ "$1" =~ -h|--help ]]; then
    remote_help "$1"
    exit 0
  fi

  parse_remote_options "$@"
  if [[ "$?" != 0 ]]; then
    complain "Invalid option: ${options_values['ERROR']}"
    return 22 # EINVAL
  fi

  if [[ -n "${options_values['ADD']}" ]]; then
    add_new_remote
    return "$?"
  fi

  if [[ -n "${options_values['REMOVE']}" ]]; then
    remove_remote
    return "$?"
  fi

  if [[ -n "${options_values['RENAME']}" ]]; then
    rename_remote
    return "$?"
  fi
}

function add_new_remote()
{
  local name
  local remote
  local host_ssh_config
  local user_ssh_config
  local port_ssh_config

  read -ra add_parameters <<< "${options_values['PARAMETERS']}"

  # We expect at exact two parameters
  if [[ "${#add_parameters[*]}" != 2 ]]; then
    complain 'Expected: add <name-without-space> <[user@]ip[:port]>'
    exit 22 # EINVAL
  fi

  name=${add_parameters[0]}
  remote=${add_parameters[1]}

  populate_remote_info "$remote"
  if [[ "$?" == 22 ]]; then
    complain 'Expected: <[user@]ip[:port]>'
    exit 22 # EINVAL
  fi

  # If we don't have a remote.config file yet, let's create it
  if [[ ! -f "${local_remote_config_file}" ]]; then
    if [[ ! -d "${PWD}/.kw" ]]; then
      complain 'Did you run kw init? It looks like that you do not have the .kw folder'
      exit 22 # EINVAL
    fi
    touch "$local_remote_config_file"
  fi

  remote="${remote_parameters['REMOTE_USER']}@${remote_parameters['REMOTE_IP']}"
  remote+=":${remote_parameters['REMOTE_PORT']}"

  # Check if remote name already exists
  grep -xq "^Host ${name}$" "$local_remote_config_file"
  if [[ "$?" == 0 ]]; then
    sed -i -r "/^Host ${name}$/{n;s/Hostname.*/Hostname ${remote_parameters['REMOTE_IP']}/}" "$local_remote_config_file"
    sed -i -r "/^Host ${name}$/{n;n;s/Port.*/Port ${remote_parameters['REMOTE_PORT']}/}" "$local_remote_config_file"
    sed -i -r "/^Host ${name}$/{n;n;n;s/User.*/User ${remote_parameters['REMOTE_USER']}/}" "$local_remote_config_file"
    return
  fi

  # New entry
  {
    printf 'Host %s\n' "$name"
    printf '  Hostname %s\n' "${remote_parameters['REMOTE_IP']}"
    printf '  Port %s\n' "${remote_parameters['REMOTE_PORT']}"
    printf '  User %s\n' "${remote_parameters['REMOTE_USER']}"
  } >> "$local_remote_config_file"
}

function remove_remote()
{
  local target_remote

  read -ra remove_parameters <<< "${options_values['PARAMETERS']}"

  # We expect at exact two parameters
  if [[ "${#remove_parameters[*]}" != 1 ]]; then
    complain 'Expected: remove <name-without-space>'
    exit 22 # EINVAL
  fi

  target_remote="${remove_parameters[0]}"

  # Check if remote name exists
  grep -xq "^Host ${target_remote}$" "$local_remote_config_file"
  if [[ "$?" == 0 ]]; then
    sed -i -r "/^Host ${target_remote}$/{n;/Hostname.*/d}" "$local_remote_config_file"
    sed -i -r "/^Host ${target_remote}$/{n;/Port.*/d}" "$local_remote_config_file"
    sed -i -r "/^Host ${target_remote}$/{n;/User.*/d}" "$local_remote_config_file"
    sed -i -r "/^Host ${target_remote}/d" "$local_remote_config_file"
    sed -i -r '/^$/d' "$local_remote_config_file"
  else
    complain "We could not find ${target_remote}"
    return 22 # EINVAL
  fi
}

function rename_remote()
{
  local old_name
  local new_name

  read -ra rename_parameters <<< "${options_values['PARAMETERS']}"

  # We expect at exact two parameters
  if [[ "${#rename_parameters[*]}" != 2 ]]; then
    complain 'Expected: rename <OLD-name-without-space> <NEW-name-without-space>'
    exit 22 # EINVAL
  fi

  old_name=${rename_parameters[0]}
  new_name=${rename_parameters[1]}

  # If we don't have a remote.config file yet, let's create it
  if [[ ! -f "${local_remote_config_file}" ]]; then
    if [[ ! -d "${PWD}/.kw" ]]; then
      complain 'Did you run kw init? It looks like that you do not have the .kw folder'
      exit 22 # EINVAL
    fi
  fi

  # Check if new name already exists
  grep -xq "^Host ${new_name}$" "$local_remote_config_file"
  if [[ "$?" == 0 ]]; then
    complain "It looks like that '${new_name}' already exists"
    complain "Please, choose another name or remove '${old_name}' first"
    return 22 # EINVAL
  fi

  # Check if remote name already exists
  grep -xq "^Host ${old_name}$" "$local_remote_config_file"
  if [[ "$?" == 0 ]]; then
    sed -i -r "s/^Host $old_name/Host $new_name/" "$local_remote_config_file"
    return
  else
    complain "It looks like that ${old_name} does not exists"
    return 22 # EINVAL
  fi
}

function parse_remote_options()
{
  local long_options='add,remove,rename,verbose'
  local short_options='v'

  options="$(kw_parse "$short_options" "$long_options" "$@")"

  if [[ "$?" != 0 ]]; then
    options_values['ERROR']="$(kw_parse_get_errors 'kw remote' "$short_options" \
      "$long_options" "$@")"
    return 22 # EINVAL
  fi

  # Default values
  options_values['ADD']=''
  options_values['REMOVE']=''
  options_values['RENAME']=''
  options_values['VERBOSE']=''
  options_values['PARAMETERS']=''

  remote_parameters['REMOTE_IP']=''
  remote_parameters['REMOTE_PORT']=''
  remote_parameters['REMOTE_USER']=''

  eval "set -- $options"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --help | -h)
        remote_help "$1"
        exit
        ;;
      add)
        options_values['ADD']=1
        shift
        ;;
      remove)
        options_values['REMOVE']=1
        shift
        ;;
      rename)
        options_values['RENAME']=1
        shift
        ;;
      --verbose | -v)
        echo "VERBOSE"
        shift
        ;;
      --)
        shift
        ;;
      *)
        options_values['PARAMETERS']+="$1 "
        shift
        ;;
    esac
  done

}

function remote_help()
{
  if [[ "$1" == --help ]]; then
    include "$KW_LIB_DIR/help.sh"
    kworkflow_man 'remote'
    return
  fi
  printf '%s\n' 'kw remote:' \
    '  remote - handle remote options' \
    '  remote add <name> <USER@IP:PORT> - Add new remote' \
    '  remote remove <name> - Remove remote' \
    '  remote rename <old> <new> - Rename remote' \
    '  remote (--verbose | -v) - be verbose'
}