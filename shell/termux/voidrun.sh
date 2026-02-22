#!/data/data/com.termux/files/usr/bin/bash

VOIDRUN_SDCARD_PATH="${VOIDRUN_SDCARD_PATH:-}"
script_name="voidrun"

if [[ "$(id -u)" == 0 ]]; then
  echo "[!] Please don't run as root"
  exit 1
fi

show_help() {
  cat <<EOF
Usage: $(basename "$0") <command> [options] [-- <args>]

Commands:
  init          Install Void Linux (if not installed) and run initial upgrade
  update        Update all packages inside Void
  install       Install a package
  shell         Open a shell inside the Void environment
  help          Show this help message

Options:
  --root        Run the following command as isolated root (only works with custom commands)
  --exec        Pass arguments after to 'void'
Any other arguments after '--' will be passed directly to 'void'.

external sdcard:
export this environment 'VOIDRUN_SDCARD_PATH' to bind external SDCard to the same path 
example
  'export VOIDRUN_SDCARD_PATH=/storage/<sdcard id>'
EOF
}

void_execute() {
  local cmd="$1"
  local pd_args=(
    login void
    --env DISPLAY="${DISPLAY}"
    --env XAUTHORITY="${HOME}/.Xauthority"
    --env GALLIUM_DRIVER=virpipe
    --env MESA_GL_VERSION_OVERRIDE=4.0
  )

  if [[ "$opt_run_asroot" == true ]]; then
    pd_args+=(--isolated)
    pd_args+=(--user "root")
  fi

  if [[ "$opt_run_asroot" != true ]]; then
    pd_args+=(--termux-home)
    pd_args+=(--user "$(whoami)")
    pd_args+=(--shared-tmp)
  fi

  if [[ -n $VOIDRUN_SDCARD_PATH ]]; then
    pd_args+=(--bind "$VOIDRUN_SDCARD_PATH:$VOIDRUN_SDCARD_PATH")
  fi

  proot-distro "${pd_args[@]}" -- /usr/bin/bash -lc "$cmd"
}

action_init() {
  local user_env="$(whoami)"

  echo "[!] PD install void"
  if proot-distro install void >/dev/null 2>&1; then
    echo "[!] PD install OK"
  else
    echo "[!] PD install fail or already installed?"
  fi

  echo "[!] Updating xbps"
  proot-distro login void -- /bin/sh -c 'xbps-install -u xbps' >/dev/null

  echo "[!] Init voidrun setup"
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
  opt_run_asroot=true
  if void_execute "xbps-install -Su"; then
    void_execute "xbps-remove -o"
    echo "[!] Update complete"
  else
    echo "[!] Update Failed"
  fi
}

action_install() {
  if [[ $# -eq 0 ]]; then
    echo "need 1 argument or more"
    exit 1
  fi
  opt_run_asroot=true
  void_execute "xbps-install -- $@"
}

action_uninstall() {
  if [[ $# -eq 0 ]]; then
    echo "need 1 argument or more"
    exit 1
  fi
  opt_run_asroot=true
  void_execute "xbps-remove -- $@" &&
    void_execute "xbps-remove -o"
}

opt_run_asroot=false

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
  uninstall)
    shift
    action_uninstall "$*"
    exit 0
    ;;
  --root)
    opt_run_asroot=true
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
