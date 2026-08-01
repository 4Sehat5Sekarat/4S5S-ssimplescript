#!/data/data/com.termux/files/usr/bin/bash

SDCARD_PATH="${SDCARD_PATH:-}"
PD_DISTRO="debian"

if [[ "$(id -u)" == 0 ]]; then
  echo "[!] Please don't run as root"
  exit 1
fi

show_help() {
  cat <<EOF
Usage: $(basename "$0") <command> [options] [-- <args>]

Commands:
  init          Install $PD_DISTRO and run initial upgrade
  update        Update all packages inside $PD_DISTRO
  install       Install a package
  shell         Open a shell inside the $PD_DISTRO environment
  help          Show this help message

Options:
  --root        Run the following command as isolated root (only works with custom commands)
  --exec        Pass arguments after to '$PD_DISTRO'
Any other arguments after '--' will be passed directly to '$PD_DISTRO'.

external sdcard:
export this environment 'SDCARD_PATH' to bind external SDCard to the same path 
example
  'export SDCARD_PATH=/storage/<sdcard id>'
EOF
}

#TODO: Add hardware accel if possible
action_execute() {
  local cmd="$1"
  local pd_args=(
    login "$PD_DISTRO"
    --env DISPLAY="${DISPLAY}"
    --env XAUTHORITY="${HOME}/.Xauthority"
    # --env GALLIUM_DRIVER=virpipe
    # --env MESA_GL_VERSION_OVERRIDE=4.0
  )

  if [[ "$opt_run_asroot" == true ]]; then
    pd_args+=(--isolated)
    pd_args+=(--user "root")
  fi

  if [[ "$opt_run_asroot" != true ]]; then
    pd_args+=(--termux-home)
    pd_args+=(--user "$(whoami)")
    pd_args+=(--shared-tmp)
    if [[ -n $SDCARD_PATH ]]; then
      pd_args+=(--bind "$SDCARD_PATH:$SDCARD_PATH")
    fi
  fi

  proot-distro "${pd_args[@]}" -- /usr/bin/bash -lc "$cmd"
}

action_init() {
  local user_env="$(whoami)"

  echo "[!] PD install "$PD_DISTRO""
  if proot-distro install "$PD_DISTRO":latest >/dev/null 2>&1; then
    echo "[!] PD install OK"
  else
    echo "[!] PD install fail or already installed?"
  fi

  echo "[!] Init voidrun setup"
  proot-distro login "$PD_DISTRO" -- /bin/sh -c '
        apt update && apt upgrade || { echo "[!] Fail update"; exit 1; }
        apt install -y sudo bash coreutils util-linux || {
            echo "[!] Fail install needed packages"
            exit 1
        }
        USER_ENV='"${user_env}"'
        groupadd wheel >/dev/null
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
  if action_execute "apt update && apt upgrade"; then
    action_execute "apt autoclean"
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
  action_execute "apt install $@"
}

action_uninstall() {
  if [[ $# -eq 0 ]]; then
    echo "need 1 or more arguments"
    exit 1
  fi
  opt_run_asroot=true
  action_execute "apt purge $@" &&
    action_execute "apt autoremove"
}

#TODO: Complete this
# add feature to copy .desktop and edit exec=
action_list_desktopfiles() {
  opt_run_asroot=false
  action_execute "grep -r 'Name=' /usr/share/applications"
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
    action_execute "bash"
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
  desktopfiles)
    action_list_desktopfiles
    exit 0
    ;;
  --root)
    opt_run_asroot=true
    shift
    ;;
  --exec)
    shift
    action_execute "$*"
    exit 0
    ;;
  --)
    shift
    action_execute "$*"
    exit 0
    ;;
  *)
    action_execute "$*"
    exit 0
    ;;
  esac
done

show_help
