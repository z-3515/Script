#!/bin/bash

# Đường dẫn đến file log
LOGFILE="/var/log/command_logs.log"

# Hàm ghi log
log_command() {
    # Bỏ qua các lệnh trống hoặc lệnh log_command để tránh loop
    [[ -z "$BASH_COMMAND" || "$BASH_COMMAND" == "log_command" ]] && return

    # Lấy thông tin lệnh
    local cmd
    if [ -n "$BASH_COMMAND" ]; then
        cmd="$BASH_COMMAND"
    elif [ -n "$ZSH_VERSION" ]; then
        cmd="$1"
    else
        cmd="$(history 1 | sed 's/^ *[0-9]* *//')"
    fi

    # Lấy thông tin khác
    local time user pwd
    time=$(date "+%Y-%m-%d %H:%M:%S")
    user=$(whoami)
    pwd=$(pwd)

    # Ghi vào file log
    echo "$time | $user | $pwd | \"$cmd\"" >> "$LOGFILE"
}

# Tránh lặp vô hạn khi source nhiều lần
if [ -z "$COMMAND_LOGGER_SOURCED" ]; then
    export COMMAND_LOGGER_SOURCED=1

    # Cấu hình cho từng shell
    if [ -n "$BASH_VERSION" ]; then
        # Bash shell
        # Gọi log_command trước mỗi lệnh được thực thi
        trap 'log_command' DEBUG
    elif [ -n "$ZSH_VERSION" ]; then
        # Zsh shell
        autoload -Uz add-zsh-hook
        log_preexec() {
            log_command "$1"
        }
        add-zsh-hook preexec log_preexec
    fi
fi