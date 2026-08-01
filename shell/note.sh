#!/usr/bin/env bash

NOTE_EDITOR="${NOTE_EDITOR:-"$EDITOR"}"
NOTE_PATH="${NOTE_PATH:-"$HOME/Documents/note"}"
NOTE_NAME="$(date +${NOTE_DAILY_FORMAT:-'%Y%m%d'})"

if [[ -f "$NOTE_PATH" ]]; then
  echo "$NOTE_PATH not directory"
  exit 1
elif [[ ! -d "$NOTE_PATH" ]]; then
  mkdir -p "$NOTE_PATH"
fi

show_help() {
  cat <<EOF
Create a daily note to a specific path and using date as naming template
use : note <option>

option : -e | --editor    specify text Editor
         -h | --help      show this help
         -r | --read      read today note as readonly
         -q | --quick     directly pass your argument to note

Available env :
  NOTE_EDITOR=<EDITOR program>  Default : $EDITOR | vi
  NOTE_PATH=<path to save>      Default : ~/Documents/note
  NOTE_NAME=<date format>       Default : '%Y%m%d'
EOF
}

#TODO: Rewrite
write_note() {
  "$NOTE_EDITOR" "${NOTE_PATH}/${NOTE_NAME}.md"
}

#TODO: Rewrite
quick_note() {
  printf '\n%s' "$*" >>"${NOTE_PATH}/${NOTE_NAME}.md"
}

#TODO: Rewrite
read_note() {
  if [[ ! -f "${NOTE_PATH}/${NOTE_NAME}.md" ]]; then
    echo "Not exist yet"
    exit 1
  fi
  cat "${NOTE_PATH}/${NOTE_NAME}.md" | less
}

#TODO: Rewrite
while $# -ge 1; do
  case "$1" in
  -e | --editor)
    if [[ -z "$2" ]]; then
      show_message narg "For Editor"
      break
    fi
    NOTE_EDITOR="$2"
    shift 2
    ;;
  -r | --read)
    read_note
    break
    ;;
  -h | --help)
    shift
    show_message help
    break
    ;;
  -q | --quick)
    shift
    quick_note "$*"
    break
    ;;
  *)
    write_note
    break
    ;;
  esac
done
