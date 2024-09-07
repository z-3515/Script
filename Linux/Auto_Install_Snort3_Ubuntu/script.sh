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

# Install snap and cmake
log_message "Installing snap..."
sudo apt update
sudo apt install -y snap snapd | tee -a "$LOGFILE"
sudo systemctl start snapd
sudo systemctl snable snapd
check_success "Snap installed"

log_message "Installing cmake via snap..."
sudo snap install cmake --classic | tee -a "$LOGFILE"
check_success "CMake installed via snap"

# Install git
log_message "APT update ..."
sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoclean && sudo apt-get autoremove -y | tee -a "$LOGFILE"
check_success "update success"

# Install git
log_message "Installing git ..."
sudo apt-get install git -y | tee -a "$LOGFILE"
check_success "git installed"

# Install g++
log_message "Installing g++ ..."
sudo apt-get install g++ -y | tee -a "$LOGFILE"
check_success "g++ installed"

# Install dependiences
log_message "Install dependiences ..."
sudo apt-get install  openssl* libssl-dev build-essential autoconf check libpthread-stubs0-dev automake libtool libgtk2.0-dev libglib2.0-dev libcmocka* flex hwloc libhwloc* luajit libluajit-* pkg-config tcpdump libpcap* zlib1g -y | tee -a "$LOGFILE"
check_success "dependiences install success"

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

# Install pcre
log_message "Installing pcre..."
cd ~/snort_src
safe_wget "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz" "pcre2-10.44.tar.gz"
safe_extract "pcre2-10.44.tar.gz" "pcre2-10.44"
cd pcre2-10.44
./configure | tee -a "$LOGFILE"
check_success "pcre configured"
make | tee -a "$LOGFILE"
check_success "pcre compiled"
sudo make install | tee -a "$LOGFILE"
check_success "pcre installed"

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

# Install optional packages

# Install Asciidoc
log_message "Installing asciidoc ..."
sudo apt-get install ascii asciidoc -y | tee -a "$LOGFILE"
check_success "asciidoc installed"

# Install Cpputest
log_message "Installing cpputest ..."
sudo apt-get install cpputest -y | tee -a "$LOGFILE"
check_success "cpputest installed"

# Install Dblatex
log_message "Installing dblatex ..."
sudo apt-get install asciidoc-dblatex dblatex dblatex-doc -y | tee -a "$LOGFILE"
check_success "dblatex installed"

# Install Hyperscan
log_message "Installing Hyperscan ..."
sudo apt-get install debhelper libboost-dev libsqlite3-dev pkg-config po-debconf python ragel libhyperscan-dev libhyperscan4 -y | tee -a "$LOGFILE"
check_success "Hyperscan installed"

# Install Iconv
log_message "Installing Iconv ..."
cd ~/snort_src/
safe_wget "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz" "libiconv-1.17.tar.gz"
safe_extract "libiconv-1.17.tar.gz" "libiconv-1.17"
cd ~/snort_src/libiconv-1.17
./configure | tee -a "$LOGFILE"
check_success "libiconv configured"
make | tee -a "$LOGFILE"
check_success "libiconv compiled"
sudo make install | tee -a "$LOGFILE"
check_success "Iconv installed"

# Install Libml
log_message "Installing Libml ..."
sudo apt-get install libmlv3 libmlv3-dev -y | tee -a "$LOGFILE"
check_success "Libml installed"

# Install Libunwind
log_message "Installing Libunwind ..."
sudo apt-get install libunwind8 libunwind-dev -y | tee -a "$LOGFILE"
check_success "Libunwind installed"

# Install Lzma
log_message "Installing Lzma ..."
sudo apt-get install xz-utils liblzma* -y | tee -a "$LOGFILE"
check_success "Lzma installed"

# Install source-highlight w3m uuid
log_message "Installing source-highlight w3m uuid ..."
sudo apt-get install source-highlight w3m uuid-runtime -y | tee -a "$LOGFILE"
check_success "source-highlight w3m uuid installed"

# Install Snort
log_message "Installing Snort..."
cd ~/snort_src
safe_wget "https://github.com/snort3/snort3/archive/refs/tags/3.3.4.0.tar.gz" "3.3.4.0.tar.gz"
safe_extract "3.3.4.0.tar.gz" "snort3-3.3.4.0"
cd snort3-3.3.4.0/
./configure_cmake.sh | tee -a "$LOGFILE"
check_success "Snort configured"
cd build
make -j $(nproc) | tee -a "$LOGFILE"
check_success "Snort compiled"
sudo make install | tee -a "$LOGFILE"
check_success "Snort installed"

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
