#!/usr/bin/env bash

NOTE_EDITOR="${NOTE_EDITOR:-vi}"
NOTE_PATH="${NOTE_PATH:-"$HOME/Documents/note"}"
NOTE_NAME="$(date +${NOTE_DAILY_FORMAT:-'%Y%m%d'})"

show_message() {
  case "$1" in
    help)
      printf "%s\n" """
Create a daily note to a specific path and using date as naming template
use : note <option>
option : -e | --editor    specify text Editor
         -h | --help      show this help
         -r | --read      read today note as readonly
         -q | --quick     directly pass your argument to note
You can export variable :
  NOTE_EDITOR=<EDITOR program>  Default : vi
  NOTE_PATH=<path to save>      Default : ~/Documents/note
  NOTE_NAME=<date format>       Default : '%Y%m%d'
      """
    ;;
    narg)
      printf "%s %s\n" "Need more argument" "$2"
    ;;
    *) echo default
    ;;
  esac
  
}

#TODO: Rewrite
write_note() {
  mkdir -p "$NOTE_PATH"
  "$NOTE_EDITOR" "${NOTE_PATH}/${NOTE_NAME}.md"
}


#TODO: Rewrite
quick_note() {
  mkdir -p "$NOTE_PATH"
  printf "\n$*" >> "${NOTE_PATH}/${NOTE_NAME}.md"
}


#TODO: Rewrite
read_note() {
  mkdir -p "$NOTE_PATH"
  cat "${NOTE_PATH}/${NOTE_NAME}.md" | less
}


#TODO: Rewrite
while true; do
  case "$1" in
    -e|--editor)
      if [[ -z "$2" ]]; then
        show_message narg "For Editor"
        break
      fi
      NOTE_EDITOR="$2"
      shift 2
    ;;
    -r|--read)
      read_note
      break
    ;;
    -h|--help)
      shift
      show_message help
      break
    ;;
    -q|--quick)
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
