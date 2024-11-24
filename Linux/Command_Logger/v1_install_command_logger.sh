#!/bin/bash

# ================== CẤU HÌNH ==================

# Thư mục và file log
LOG_DIR="/var/log/command_logs"
LOG_FILE="$LOG_DIR/commands.log"

# Cấu hình logging script
LOGGING_SCRIPT='
# Hàm ghi log lệnh
log_command() {
    # Lấy thời gian hiện tại
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Lấy tên người dùng
    USER_NAME=$(whoami)
    
    # Lấy thư mục hiện tại
    PWD_DIR=$(pwd)
    
    # Lấy địa chỉ IP của kết nối SSH (nếu có)
    IP_ADDRESS=$(who am i | awk "{print \$5}" | tr -d "()")
    
    # Lấy lệnh vừa thực hiện
    # Đối với Bash
    if [ -n "$BASH_VERSION" ]; then
        COMMAND=$(history 1 | sed "s/^ *[0-9]* *//")
    fi
    
    # Đối với Zsh
    if [ -n "$ZSH_VERSION" ]; then
        COMMAND=$(fc -ln -1)
    fi
    
    # Lấy mã thoát của lệnh vừa thực hiện
    EXIT_CODE=$?
    
    # Ghi thông tin vào file log
    echo "$TIMESTAMP | $USER_NAME | $PWD_DIR | $IP_ADDRESS | $COMMAND | Exit Code: $EXIT_CODE" >> /var/log/command_logs/commands.log
}

# Thêm hàm vào PROMPT_COMMAND cho bash
if [ -n "$BASH_VERSION" ]; then
    PROMPT_COMMAND="log_command; $PROMPT_COMMAND"
fi

# Thêm hàm vào precmd cho zsh
if [ -n "$ZSH_VERSION" ]; then
    precmd_functions+=(log_command)
fi
'

# ================== THỰC THI ==================

# Tạo thư mục log nếu chưa tồn tại
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    chmod 777 "$LOG_DIR"
    echo "Đã tạo thư mục log tại $LOG_DIR"
fi

# Tạo file log nếu chưa tồn tại
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    echo "Đã tạo file log tại $LOG_FILE"
fi

# Hàm kiểm tra và thêm logging script vào file cấu hình
add_logging_to_config() {
    local config_file=$1
    local shell_name=$2

    if grep -q "log_command" "$config_file"; then
        echo "Logging đã được thiết lập trong $config_file"
    else
        echo "$LOGGING_SCRIPT" >> "$config_file"
        echo "Đã thêm cấu hình logging vào $config_file cho $shell_name"
    fi
}

# Cập nhật cấu hình cho Bash
BASH_CONFIG="/etc/bash.bashrc"
if [ -f "$BASH_CONFIG" ]; then
    add_logging_to_config "$BASH_CONFIG" "Bash"
else
    echo "$BASH_CONFIG không tồn tại. Bỏ qua cấu hình cho Bash."
fi

# Cập nhật cấu hình cho Zsh
ZSH_CONFIG="/etc/zsh/zshrc"
if [ -f "$ZSH_CONFIG" ]; then
    add_logging_to_config "$ZSH_CONFIG" "Zsh"
else
    echo "$ZSH_CONFIG không tồn tại. Bỏ qua cấu hình cho Zsh."
fi

echo "Hoàn tất thiết lập ghi log lệnh cho tất cả người dùng."
