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
chmod 622 "$LOGFILE"  # rw--w--w-
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

echo "Cài đặt hệ thống ghi log các lệnh người dùng hoàn tất."
echo "Vui lòng đăng xuất và đăng nhập lại để các thay đổi có hiệu lực."
