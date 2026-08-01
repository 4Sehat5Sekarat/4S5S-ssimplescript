#!/usr/bin/env bash

SP_SAVE_TEMP="${SP_SAVE_TEMP:-$HOME/.local/state/scratchpad.sh/}"
SP_MAX_TEMP="${SP_MAX_TEMP:-10}"
EDITOR="${EDITOR:-vi}"

is_saved=false

# Check is dir where script saved are ezist
if [[ ! -d "$SP_SAVE_TEMP" ]]; then
  mkdir -p "$SP_SAVE_TEMP"
fi

# Show help
show_help() {
  cat <<EOF
h | help  Show this message
e | edit  Re-Edit script
s | save  Save script
q | exit  Exit
x | exec  Execute script again
*         Show unknown option message

EDITOR    Change Editor
current editor $EDITOR
EOF
}

# Script file
create_script() {
  TEMP_SCRIPT="$(mktemp -p "$SP_SAVE_TEMP" script_XXXXXX.sh)"
  # Create shebang!
  printf '#!/usr/bin/env bash\n' >"$TEMP_SCRIPT"
}

# Editting script function
edit_script() {
  if [[ -z $EDITOR ]]; then
    echo "no \$EDITOR found"
  fi

  $EDITOR "$TEMP_SCRIPT"
  export TS="$TEMP_SCRIPT"
}

# Execute script function
execute() {
  trap '' INT
  printf '%s\n' "Execute script, Ctrl-c to kill"

  (
    trap - INT
    exec bash "$TEMP_SCRIPT"
  )

  printf '\n%s\n' "Done.."
  trap - INT

# Delete oldest script if more than max
#TODO: Need some rewrite
manage_script() {
  if [[ $is_saved == true ]]; then
    return
  fi

  local script_count=$(find "$SP_SAVE_TEMP" -maxdepth 1 -type f | wc -l)
  if [[ $script_count -ge $SP_MAX_TEMP ]]; then
    local oldest_file="$(find "$SP_SAVE_TEMP" -type f -printf '%T+ %p\n' | sort | head -1 | cut -d' ' -f2-)"
    rm "$oldest_file"
  fi
}

#TODO: Need some rewrite
save_script() {
  echo "message"
  if [[ $is_saved == false ]]; then
    local current_pwd="$(pwd)"
    local old_path="$TEMP_SCRIPT"
    TEMP_SCRIPT="${current_pwd}/$(basename "$TEMP_SCRIPT")"

    mv "$old_path" "$TEMP_SCRIPT"
    is_saved=true

    echo $TEMP_SCRIPT
  fi
}

user_action() {
  printf 'Are you done?. press x to execute or h to see another option. \n'
  while true; do
    printf ' ¿ > '
    read -r user_do

    case "$user_do" in
    help | h)
      show_help
      ;;
    edit | e)
      edit_script
      ;;
    save | s)
      save_script
      ;;
    exec | x)
      execute
      ;;
    exit | q)
      break
      ;;
    EDITOR)
      printf 'EDITOR = '
      read -r EDITOR
      ;;
    *)
      printf 'Unknown : %s\n' "$user_do"
      printf "To exit use CTRL+C or q"
      ;;
    esac
  done
}

# Everything done, so we need to manage it
create_script
edit_script # Editting script on init call
user_action
manage_script
