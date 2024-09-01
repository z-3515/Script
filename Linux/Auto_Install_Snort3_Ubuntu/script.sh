# Install cmake
sudo snap install cmake --classic

# Install git
sudo apt install git -y

# Install g++
sudo apt update
sudo apt install g++ -y

# Install dependiences
sudo apt install  openssl* libssl-dev build-essential autoconf check libpthread-stubs0-dev automake libtool libgtk2.0-dev libglib2.0-dev libcmocka* flex hwloc libhwloc* luajit libluajit-* pkg-config tcpdump libpcap* zlib1g -y

mkdir ~/snort_src
cd ~/snort_src

# Install Tcmalloc - gperftools
cd ~/snort_src
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.15/gperftools-2.15.tar.gz
tar -xzf gperftools-2.15.tar.gz
cd ~/snort_src/gperftools-2.15/
./configure
make
sudo make install

# Install dnet
cd ~/snort_src
wget https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-1.18.0.tar.gz
tar -xzf libdnet-1.18.0.tar.gz 
cd ~/snort_src/libdnet-libdnet-1.18.0/
./configure
make
sudo make install

# pcre
cd ~/snort_src
wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz
tar -xzf pcre2-10.44.tar.gz
cd ~/snort_src/pcre2-10.44
./configure
make
sudo make install

# Install libdaq
cd ~/snort_src
git clone https://github.com/snort3/libdaq.git
cd ~/snort_src/libdaq/
./bootstrap
./configure
make
sudo make install
sudo ldconfig

# Install optional packages

# Asciidoc
sudo apt install ascii asciidoc -y

# Cpputest
sudo apt-get install cpputest -y

# dblatex
sudo apt install asciidoc-dblatex dblatex dblatex-doc -y

# hyperscan
sudo apt install debhelper libboost-dev libsqlite3-dev pkg-config po-debconf python ragel libhyperscan-dev libhyperscan4 -y

# iconv
cd ~/snort_src/
wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz
tar -xzf libiconv-1.17.tar.gz
cd ~/snort_src/libiconv-1.17
./configure
make
sudo make install

# libml
sudo apt install libmlv3 libmlv3-dev -y

# libunwind
sudo apt install libunwind8 libunwind-dev -y

# lzma
sudo apt install xz-utils liblzma* -y

# source-highlight w3m uuid
sudo apt install source-highlight w3m uuid-runtime -y

# SNORT
cd ~/snort_src/
wget https://github.com/snort3/snort3/archive/refs/tags/3.3.4.0.tar.gz
tar -xzf 3.3.4.0.tar.gz 
cd ~/snort_src/snort3-3.3.4.0/
./configure_cmake.sh
cd ~/snort_src/snort3-3.3.4.0/build
make -j $(nproc)
sudo make install

#!/bin/bash

# Define the path to the Snort binary
SNORT_BIN="/usr/local/snort/bin/snort"

# Function to print messages
print_message() {
    echo -e "\033[1;34m$1\033[0m" # Blue color for messages
}

# Check if Snort binary exists
if [ -f "$SNORT_BIN" ]; then
    print_message "Snort binary found at $SNORT_BIN"
    
    # Check if the binary is executable
    if [ -x "$SNORT_BIN" ]; then
        print_message "Snort binary is executable."
    else
        print_message "Snort binary is not executable. Setting executable permissions."
        chmod +x "$SNORT_BIN"
        print_message "Permissions updated."
    fi

    # Run Snort to check the version
    print_message "Running Snort to check version:"
    "$SNORT_BIN" -V

    # Optionally, add Snort to the PATH
    read -p "Do you want to add Snort to your PATH? (y/n) " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        # Add Snort to PATH in .bashrc
        if ! grep -q "/usr/local/snort/bin" ~/.bashrc; then
            echo 'export PATH=/usr/local/snort/bin:$PATH' >> ~/.bashrc
            source ~/.bashrc
            print_message "Snort added to PATH. You may need to restart your terminal."
        else
            print_message "Snort is already in your PATH."
        fi
    else
        print_message "Snort was not added to PATH."
    fi

else
    print_message "Snort binary not found at $SNORT_BIN. Please check the installation."
    exit 1
fi

