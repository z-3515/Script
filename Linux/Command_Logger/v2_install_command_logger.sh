#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script với quyền root."
    exit 1
fi

echo "[DEBUG] Đã kiểm tra quyền root."

# Đường dẫn đến file log
LOGFILE="/var/log/command_logs.log"
LOGDIR=$(dirname "$LOGFILE")

# Tạo thư mục chứa file log nếu chưa tồn tại
if [ ! -d "$LOGDIR" ]; then
    echo "[DEBUG] Thư mục $LOGDIR không tồn tại. Đang tạo..."
    mkdir -p "$LOGDIR" || { echo "Không thể tạo thư mục $LOGDIR"; exit 1; }
fi

# Tạo file log nếu chưa tồn tại và thiết lập quyền
if [ ! -f "$LOGFILE" ]; then
    echo "[DEBUG] File log $LOGFILE không tồn tại. Đang tạo..."
    if ! touch "$LOGFILE"; then
        echo "Không thể tạo file log $LOGFILE";
        exit 1
    fi
fi
chmod 640 "$LOGFILE" || { echo "Không thể thiết lập quyền cho file log $LOGFILE"; exit 1; }
chown root:adm "$LOGFILE" || { echo "Không thể thiết lập chủ sở hữu cho file log $LOGFILE"; exit 1; }

# Tạo script logger chính
echo "[DEBUG] Đang tạo script logger chính..."
cat << 'EOF' > /usr/local/bin/command_logger.sh
#!/bin/bash

# Đường dẫn đến file log
LOGFILE="/var/log/command_logs.log"

# Đảm bảo rằng LOGFILE là một đường dẫn hợp lệ và không thể chỉnh sửa bởi người dùng
if [[ "$LOGFILE" != /* ]]; then
    echo "LOGFILE phải là đường dẫn tuyệt đối"
    exit 1
fi

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
    shell=$(SHELL)

    # Ghi vào file log
    echo "$time | $user | $pwd | \"$cmd\"" | $shell>> "$LOGFILE" || {
        echo "Không thể ghi vào file log $LOGFILE";
    }
    echo "[DEBUG] Lệnh đã được ghi vào log: $cmd"
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

# Kiểm tra lỗi khi tạo script logger
if [ $? -ne 0 ]; then
    echo "Không thể tạo script logger chính."
    exit 1
fi

# Thiết lập quyền cho script logger
echo "[DEBUG] Đang thiết lập quyền cho script logger..."
chmod 755 /usr/local/bin/command_logger.sh || { echo "Không thể thiết lập quyền cho script /usr/local/bin/command_logger.sh"; exit 1; }
chown root:root /usr/local/bin/command_logger.sh || { echo "Không thể thiết lập chủ sở hữu cho script /usr/local/bin/command_logger.sh"; exit 1; }

# Tạo script trong /etc/profile.d để load logger cho login shells
echo "[DEBUG] Đang tạo script trong /etc/profile.d để load logger..."
if [ -f /etc/profile.d/command_logger.sh ]; then
    echo "[DEBUG] File /etc/profile.d/command_logger.sh đã tồn tại. Đang xóa..."
    rm /etc/profile.d/command_logger.sh || { echo "Không thể xóa script cũ trong /etc/profile.d"; exit 1; }
fi
cat << 'EOF' > /etc/profile.d/command_logger.sh
# Source script logger cho login shells
if [ -f /usr/local/bin/command_logger.sh ]; then
    source /usr/local/bin/command_logger.sh
fi
EOF

# Kiểm tra lỗi khi tạo script trong /etc/profile.d
if [ $? -ne 0 ]; then
    echo "Không thể tạo script trong /etc/profile.d để load logger."
    exit 1
fi

# Thiết lập quyền cho script trong /etc/profile.d
echo "[DEBUG] Đang thiết lập quyền cho script trong /etc/profile.d..."
chmod 644 /etc/profile.d/command_logger.sh || { echo "Không thể thiết lập quyền cho script /etc/profile.d/command_logger.sh"; exit 1; }
chown root:root /etc/profile.d/command_logger.sh || { echo "Không thể thiết lập chủ sở hữu cho script /etc/profile.d/command_logger.sh"; exit 1; }

# Kiểm tra các shell hiện có trên hệ thống để cấu hình logger
available_shells=$(cat /etc/shells | grep -v '^#')
for shell in $available_shells; do
    if [[ "$shell" == *"bash"* ]]; then
        # Thêm vào /etc/bash.bashrc để load logger cho non-login shells
        if [ -f /etc/bash.bashrc ]; then
            if ! grep -q "command_logger.sh" /etc/bash.bashrc; then
                echo "" >> /etc/bash.bashrc || { echo "Không thể ghi vào /etc/bash.bashrc"; exit 1; }
                echo "# Source command logger cho tất cả người dùng" >> /etc/bash.bashrc || { echo "Không thể ghi vào /etc/bash.bashrc"; exit 1; }
                echo "if [ -f /usr/local/bin/command_logger.sh ]; then" >> /etc/bash.bashrc || { echo "Không thể ghi vào /etc/bash.bashrc"; exit 1; }
                echo "    source /usr/local/bin/command_logger.sh" >> /etc/bash.bashrc || { echo "Không thể ghi vào /etc/bash.bashrc"; exit 1; }
                echo "fi" >> /etc/bash.bashrc || { echo "Không thể ghi vào /etc/bash.bashrc"; exit 1; }
            fi
        fi
    elif [[ "$shell" == *"zsh"* ]]; then
        # Thêm vào /etc/zsh/zshrc để load logger cho Zsh shells
        if [ -f /etc/zsh/zshrc ]; then
            if ! grep -q "command_logger.sh" /etc/zsh/zshrc; then
                echo "" >> /etc/zsh/zshrc || { echo "Không thể ghi vào /etc/zsh/zshrc"; exit 1; }
                echo "# Source command logger cho tất cả người dùng" >> /etc/zsh/zshrc || { echo "Không thể ghi vào /etc/zsh/zshrc"; exit 1; }
                echo "if [ -f /usr/local/bin/command_logger.sh ]; then" >> /etc/zsh/zshrc || { echo "Không thể ghi vào /etc/zsh/zshrc"; exit 1; }
                echo "    source /usr/local/bin/command_logger.sh" >> /etc/zsh/zshrc || { echo "Không thể ghi vào /etc/zsh/zshrc"; exit 1; }
                echo "fi" >> /etc/zsh/zshrc || { echo "Không thể ghi vào /etc/zsh/zshrc"; exit 1; }
                echo "[DEBUG] Đã thêm command_logger vào /etc/zsh/zshrc."
            fi
        fi
    fi
done

echo "Cài đặt hệ thống ghi log các lệnh người dùng hoàn tất."
echo "Vui lòng đăng xuất và đăng nhập lại để các thay đổi có hiệu lực."
