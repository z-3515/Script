#!/bin/bash

LOGFILE="install_log.txt"
SNORT_BIN="/usr/local/snort/bin/snort"

# Function to log messages
log_message() {
    echo "$(date) : $1" | tee -a "$LOGFILE"
}

# Function to check command success and handle errors
check_success() {
    if [ $? -ne 0 ]; then
        log_message "Error: $1"
        echo -e "\033[1;31mError occurred: $1\033[0m" # Red color for error
        exit 1
    else
        log_message "Success: $1"
    fi
}

# Function to download files only if they don't exist
safe_wget() {
    URL=$1
    FILE=$2
    if [ -f "$FILE" ]; then
        log_message "File $FILE already exists. Skipping download."
    else
        log_message "Downloading $FILE..."
        wget "$URL" -O "$FILE" | tee -a "$LOGFILE"
        check_success "Downloaded $FILE"
    fi
}

# Function to extract files only if they haven't been extracted
safe_extract() {
    ARCHIVE=$1
    DIR=$2
    if [ -d "$DIR" ]; then
        log_message "Directory $DIR already exists. Skipping extraction."
    else
        log_message "Extracting $ARCHIVE..."
        tar -xzf "$ARCHIVE" | tee -a "$LOGFILE"
        check_success "Extracted $ARCHIVE"
    fi
}

# Function to git clone only if the directory doesn't exist
safe_git_clone() {
    REPO_URL=$1
    DIR=$2
    if [ -d "$DIR" ]; then
        log_message "Directory $DIR already exists. Skipping git clone."
    else
        log_message "Cloning repository from $REPO_URL..."
        git clone "$REPO_URL" "$DIR" | tee -a "$LOGFILE"
        check_success "Cloned repository from $REPO_URL"
    fi
}

# Function to add Snort to PATH based on shell type (bash, zsh, etc.)
add_to_path() {
    SHELL_TYPE=$(basename "$SHELL")
    case $SHELL_TYPE in
        bash)
            CONFIG_FILE=~/.bashrc
            ;;
        zsh)
            CONFIG_FILE=~/.zshrc
            ;;
        *)
            CONFIG_FILE=~/.profile
            ;;
    esac

    log_message "Adding Snort to PATH in $CONFIG_FILE"
    if ! grep -q "/usr/local/snort/bin" "$CONFIG_FILE"; then
        echo 'export PATH=/usr/local/snort/bin:$PATH' >> "$CONFIG_FILE"
        source "$CONFIG_FILE"
        log_message "Snort added to PATH. You may need to restart your terminal."
    else
        log_message "Snort is already in your PATH."
    fi
}

# Function to check for and fix executable permission for Snort
check_snort_binary() {
    log_message "Checking Snort binary..."
    if [ -f "$SNORT_BIN" ]; then
        log_message "Snort binary found at $SNORT_BIN"

        if [ -x "$SNORT_BIN" ]; then
            log_message "Snort binary is executable."
        else
            log_message "Snort binary is not executable. Setting executable permissions."
            chmod +x "$SNORT_BIN"
            check_success "Permissions updated"
        fi

        # Run Snort to check version
        log_message "Running Snort to check version:"
        "$SNORT_BIN" -V | tee -a "$LOGFILE"
    else
        log_message "Snort binary not found. Please check the installation."
        exit 1
    fi
}

# Start installation process
log_message "Starting installation process..."

# Install essential packages
sudo apt update
sudo apt install -y cmake git g++ build-essential autoconf libssl-dev libpthread-stubs0-dev automake libtool \
libgtk2.0-dev libglib2.0-dev libcmocka-dev flex hwloc libhwloc-dev luajit libluajit-5.1-dev pkg-config tcpdump libpcap-dev zlib1g \
openssl xz-utils | tee -a "$LOGFILE"
check_success "Essential packages installed"

# Create directory
log_message "Creating snort_src directory..."
mkdir -p ~/snort_src | tee -a "$LOGFILE"
check_success "Directory created"
cd ~/snort_src

# Install Tcmalloc - gperftools
log_message "Installing Tcmalloc (gperftools)..."
safe_wget "https://github.com/gperftools/gperftools/releases/download/gperftools-2.15/gperftools-2.15.tar.gz" "gperftools-2.15.tar.gz"
safe_extract "gperftools-2.15.tar.gz" "gperftools-2.15"
cd gperftools-2.15/
./configure | tee -a "$LOGFILE"
check_success "gperftools configured"
make | tee -a "$LOGFILE"
check_success "gperftools compiled"
sudo make install | tee -a "$LOGFILE"
check_success "gperftools installed"

# Install dnet
log_message "Installing dnet..."
cd ~/snort_src
safe_wget "https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-1.18.0.tar.gz" "libdnet-1.18.0.tar.gz"
safe_extract "libdnet-1.18.0.tar.gz" "libdnet-libdnet-1.18.0"
cd libdnet-libdnet-1.18.0/
./configure | tee -a "$LOGFILE"
check_success "dnet configured"
make | tee -a "$LOGFILE"
check_success "dnet compiled"
sudo make install | tee -a "$LOGFILE"
check_success "dnet installed"

# Install libdaq
log_message "Installing libdaq..."
cd ~/snort_src
safe_git_clone "https://github.com/snort3/libdaq.git" "libdaq"
cd libdaq/
./bootstrap | tee -a "$LOGFILE"
check_success "libdaq bootstrapped"
./configure | tee -a "$LOGFILE"
check_success "libdaq configured"
make | tee -a "$LOGFILE"
check_success "libdaq compiled"
sudo make install | tee -a "$LOGFILE"
sudo ldconfig | tee -a "$LOGFILE"
check_success "libdaq installed"

# Optional packages
log_message "Installing optional packages..."
sudo apt install ascii asciidoc cpputest asciidoc-dblatex dblatex dblatex-doc libboost-dev libsqlite3-dev libhyperscan-dev libunwind8 libunwind-dev source-highlight w3m uuid-runtime -y | tee -a "$LOGFILE"
check_success "Optional packages installed"

# Check Snort binary
check_snort_binary

# Prompt to add Snort to PATH
log_message "Prompting to add Snort to PATH"
read -p "Do you want to add Snort to your PATH? (y/n) " response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    add_to_path
else
    log_message "Snort was not added to PATH."
fi

log_message "Installation process completed."
