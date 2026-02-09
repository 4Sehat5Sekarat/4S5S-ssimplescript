#!/bin/sh

SCRIPT_VER="0.4"
F_NOTE_FILE="${F_NOTE_FILE:-$HOME/Documents/f_log.txt}"
F_NOTE_PREFIX="${F_NOTE_PREFIX:+$F_NOTE_PREFIX}"
F_NOTE_SUFFIX="${F_NOTE_SUFFIX:+$F_NOTE_SUFFIX}"
F_NOTE_DATETIME=${F_NOTE_DATETIME:-'%H:%M, %d-%m-%Y'}

mkdir -p "$(dirname "$F_NOTE_FILE")"
touch "$F_NOTE_FILE"


# Changelog message
changelog() {
  cat <<EOF
0.0 - At least it works ==> Created accidentally

0.1 - Some Little Update
    - change some code!
    - add some argument

0.2 - Add prefix for starting word
    - Add Write mode (to hide from cli history)

0.3 - Rewrite some stuff after learning some stuff

0.4 - Rename variable
    - Add SUFFIX
    - Add help messages
    - Add Datetime format
EOF
}


# Help messages
message_help() {
  cat <<EOF
Write a single line note with datetime
fnote [option]... < Your Notes >
  -c | --changelog    Show Changelog
  -d | --datetime     Datetime format (use help datetime to get format)
  -e | --editor       Open file with $EDITOR
  -f | --file         Save to choosed file path
  -h | --help         Show this help text
  -p | --prefix       PREFIX text on your notes
  -r | --read         Read all your notes
  -s | --suffix       SUFFIX text on your notes
  -v | --version      Show current Version
  -w | --where        Show where note file will be written

you can use external variable, but option are more prioritized.
currently you can use :
   F_NOTE_PREFIX      same like --prefix option
   F_NOTE_SUFFIX      same like --suffix option
   F_NOTE_FILE        place where your note are saved currently on ($F_NOTE_FILE)
EOF
}

# Write note
# TODO: need to rewrite later
action_write() {
  note_text="${F_NOTE_PREFIX}$*${F_NOTE_SUFFIX}"
  date_text="$(date +"$F_NOTE_DATETIME")"
  printf '%s - %s\n' "$date_text" "$note_text">> "$F_NOTE_FILE"
}


action_read() {
  if [ $# -eq 0 ]; then
    cat "$F_NOTE_FILE"
  fi

  case "$1" in
    1) echo 1
    ;;
    2|3) echo 2 or 3
    ;;
  esac
  
}


# Enter write mode when no arg or note written
if [ $# -eq 0 ]; then
  printf '%s\n' "Press ENTER when done"
  read -r line
  action_write "$line"
  exit 0
fi


# Check condition
while true; do
  case "$1" in
  -v|--version)
    printf '%s\n' "$SCRIPT_VER"
    exit 0
    ;;
  -r|--read)
    action_read $2
    exit 0
    ;;
  -e|--editor)
    "$EDITOR" "$F_NOTE_FILE"
    exit 0
    ;;
  -c|--changelog)
    changelog
    exit 0
    ;;
  -w|--where)
    printf '%s\n' "$F_NOTE_FILE"
    exit 0
    ;;
  -p|--prefix)
    F_NOTE_PREFIX="$2"
    shift 2
    ;;
  -s|--suffix)
    F_NOTE_SUFFIX="$2"
    shift 2 
    ;;
  -h|--help)
    message_help
    exit 0
    ;;
  -f|--file)
    F_NOTE_FILE="$2"
    shift 2 
    ;;
  -d|--datetime)
    F_NOTE_DATETIME="$2"
    shift 2 
    ;;
  -*)
    printf '%s %s\n' "Unknown option:" "$1"
    exit 1
    ;;
  *)
    action_write "$@"
    exit 0
    ;;
  esac
done
