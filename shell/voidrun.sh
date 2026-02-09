#!/data/data/com.termux/files/usr/bin/bash

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
  --root        Run the following command as root (only works with custom commands)

Any other arguments after '--' will be passed directly to 'pd login void'.
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
        --bind /storage/9C33-6BBD:/storage/9C33-6BBD
        --env DISPLAY="${DISPLAY}"
        --env XAUTHORITY="${HOME}/.Xauthority"
        --env GALLIUM_DRIVER=virpipe
        --env MESA_GL_VERSION_OVERRIDE=4.0
    )

    if [[ "$opt_runasroot" != true ]]; then
        pd_args+=(--termux-home)
    fi

    proot-distro "${pd_args[@]}" -- /usr/bin/bash -lc "$cmd"
}

action_init() {
    if proot-distro install void > /dev/null 2>&1; then
        echo "[!] PD install OK"
    else
        echo "[!] PD install gagal atau sudah terpasang"
    fi

    proot-distro login void -- /bin/sh -c '
        xbps-install -Syu || { echo "Gagal update repositori"; exit 1; }
        xbps-install -y shadow sudo bash coreutils util-linux || {
            echo "Instalasi paket penting gagal"
            exit 1
        }
        USER_ENV='"${user_env}"'
        if ! id -u "$USER_ENV" >/dev/null 2>&1; then
            echo "Membuat user $USER_ENV ..."
            useradd -m -s /bin/bash -U -G wheel "$USER_ENV"
            passwd -d "$USER_ENV"
        else
            echo "User $USER_ENV sudah ada, lewati pembuatan."
        fi

        echo "Setup selesai. Anda dapat menjalankan:"
        echo "$script_name shell"
        echo "atau gunakan --root untuk menjalankan perintah sebagai root."
    '

}

action_update() {
    opt_runasroot=true
    void_execute "yes | xbps-install -Su && xbps-remove -O"
    echo "Update selesai, Bang."
}

action_install() {
    [[ $# -eq 0 ]] && {
        echo "need 1 argument"
        exit 1
    }
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
