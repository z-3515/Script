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