#!/data/data/com.termux/files/usr/bin/bash

VOIDRUN_SDCARD_PATH="${VOIDRUN_SDCARD_PATH:-}"
user_env=$(whoami)
script_name="voidrun"

show_help() {
  cat <<EOF
Usage: $(basename "$0") <command> [options] [-- <args>]

Commands:
  init          Install Void Linux (if not installed) and run initial upgrade
  update        Update all packages inside Void
  shell         Open a shell inside the Void environment
  help          Show this help message

Options:
  --root        Run the following command as root and isolated (only works with custom commands)
  --exec        Pass arguments after to 'void'
Any other arguments after '--' will be passed directly to 'void'.

external SDCard:
export this environment 'VOIDRUN_SDCARD_PATH' to bind external SDCard to the same path
example 'export VOIDRUN_SDCARD_PATH=/storage/<sdcard id>'
EOF
}

void_execute() {
  local cmd="$1"

  if [[ "$opt_runasroot" == true ]]; then
    user_env="root"
  fi

  local pd_args=(
    login void
    --shared-tmp
    --user "$user_env"
    --env DISPLAY="${DISPLAY}"
    --env XAUTHORITY="${HOME}/.Xauthority"
    --env GALLIUM_DRIVER=virpipe
    --env MESA_GL_VERSION_OVERRIDE=4.0
  )

  if [[ "$opt_runasroot" == true ]]; then
    pd_args+=(--isolated)
  fi

  if [[ "$opt_runasroot" != true ]]; then
    pd_args+=(--termux-home)
  fi

  if [[ -n $VOIDRUN_SDCARD_PATH ]]; then
    pd_args+=(--bind "$VOIDRUN_SDCARD_PATH:$VOIDRUN_SDCARD_PATH")
  fi

  proot-distro "${pd_args[@]}" -- /usr/bin/bash -lc "$cmd"
}

action_init() {
  if proot-distro install void >/dev/null 2>&1; then
    echo "[!] PD install OK"
  else
    echo "[!] PD install fail or already installed?"
  fi

  proot-distro login void -- /bin/sh -c '
        xbps-install -Syu || { echo "[!] Fail update repo"; exit 1; }
        xbps-install -y shadow sudo bash coreutils util-linux || {
            echo "[!] Fail install needed packages"
            exit 1
        }
        USER_ENV='"${user_env}"'
        if ! id -u "$USER_ENV" >/dev/null 2>&1; then
            echo "[!] Creating $USER_ENV ..."
            useradd -m -s /bin/bash -U -G wheel "$USER_ENV"
            passwd -d "$USER_ENV"
        else
            echo "[!] User $USER_ENV already exist."
        fi

        echo "[!] Setup Complete!"
    '
}

action_update() {
  opt_runasroot=true
  void_execute "xbps-install -Su" &&
    echo "[!] Update complete" || echo "[!] Update Failed"
}

action_install() {
  if [[ $# -eq 0 ]]; then
    echo "need 1 argument"
    exit 1
  fi
  opt_runasroot=true
  void_execute "xbps-install -- $@"
}

opt_runasroot=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  init)
    action_init
    exit 0
    ;;
  update)
    action_update
    exit 0
    ;;
  help)
    show_help
    exit 0
    ;;
  shell)
    void_execute "bash"
    exit 0
    ;;
  install)
    shift
    action_install "$*"
    exit 0
    ;;
  --root)
    opt_runasroot=true
    shift
    ;;
  --exec)
    shift
    void_execute "$*"
    exit 0
    ;;
  --)
    shift
    void_execute "$*"
    exit 0
    ;;
  *)
    void_execute "$*"
    exit 0
    ;;
  esac
done

show_help
