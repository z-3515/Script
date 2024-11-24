#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script với quyền root."
    exit 1
fi

# Đường dẫn đến file log
LOGFILE="/var/log/command_logs.log"

# Tạo file log nếu chưa tồn tại và thiết lập quyền
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
fi
chmod 664 "$LOGFILE"  # rw-rw-r--
chown root:root "$LOGFILE"

# Tạo script logger chính
cat << 'EOF' > /usr/local/bin/command_logger.sh
#!/bin/bash

# Đường dẫn đến file log
LOGFILE="/var/log/command_logs.log"

# Hàm ghi log
log_command() {
    # Bỏ qua các lệnh trống hoặc lệnh log_command để tránh loop
    [[ -z "$BASH_COMMAND" || "$BASH_COMMAND" == "log_command" ]] && return

    # Lấy thông tin lệnh
    local cmd
    cmd="$BASH_COMMAND"

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

    # Cấu hình cho Bash shell
    if [ -n "$BASH_VERSION" ]; then
        # Sử dụng PROMPT_COMMAND để gọi log_command sau mỗi lệnh
        PROMPT_COMMAND="log_command"
    fi

    # Cấu hình cho Zsh shell
    if [ -n "$ZSH_VERSION" ]; then
        autoload -Uz add-zsh-hook
        log_preexec() {
            log_command "$1"
        }
        add-zsh-hook preexec log_preexec
    fi

    # Cấu hình cho Ksh shell
    if [ -n "$KSH_VERSION" ]; then
        trap 'log_command' DEBUG
    fi
fi
EOF

# Thiết lập quyền cho script logger
chmod 755 /usr/local/bin/command_logger.sh
chown root:root /usr/local/bin/command_logger.sh

# Tạo script trong /etc/profile.d để load logger cho login shells
cat << 'EOF' > /etc/profile.d/command_logger.sh
# Source script logger cho login shells
if [ -f /usr/local/bin/command_logger.sh ]; then
    source /usr/local/bin/command_logger.sh
fi
EOF

# Thiết lập quyền cho script trong /etc/profile.d
chmod 644 /etc/profile.d/command_logger.sh
chown root:root /etc/profile.d/command_logger.sh

# Thêm vào /etc/bash.bashrc để load logger cho non-login shells
if ! grep -q "command_logger.sh" /etc/bash.bashrc; then
    echo "" >> /etc/bash.bashrc
    echo "# Source command logger cho tất cả người dùng" >> /etc/bash.bashrc
    echo "if [ -f /usr/local/bin/command_logger.sh ]; then" >> /etc/bash.bashrc
    echo "    source /usr/local/bin/command_logger.sh" >> /etc/bash.bashrc
    echo "fi" >> /etc/bash.bashrc
fi

# Thêm vào /etc/zsh/zshrc để load logger cho Zsh shells
if [ -f /etc/zsh/zshrc ]; then
    if ! grep -q "command_logger.sh" /etc/zsh/zshrc; then
        echo "" >> /etc/zsh/zshrc
        echo "# Source command logger cho tất cả người dùng" >> /etc/zsh/zshrc
        echo "if [ -f /usr/local/bin/command_logger.sh ]; then" >> /etc/zsh/zshrc
        echo "    source /usr/local/bin/command_logger.sh" >> /etc/zsh/zshrc
        echo "fi" >> /etc/zsh/zshrc
    fi
fi

# Thêm vào /etc/ksh.kshrc để load logger cho Ksh shells
if [ -f /etc/ksh.kshrc ]; then
    if ! grep -q "command_logger.sh" /etc/ksh.kshrc; then
        echo "" >> /etc/ksh.kshrc
        echo "# Source command logger cho tất cả người dùng" >> /etc/ksh.kshrc
        echo "if [ -f /usr/local/bin/command_logger.sh ]; then" >> /etc/ksh.kshrc
        echo "    source /usr/local/bin/command_logger.sh" >> /etc/ksh.kshrc
        echo "fi" >> /etc/ksh.kshrc
    fi
fi

echo "Cài đặt hệ thống ghi log các lệnh người dùng hoàn tất."
echo "Vui lòng đăng xuất và đăng nhập lại để các thay đổi có hiệu lực."
