# Installation Script for Snort with Dependencies

This repository contains a bash script for installing Snort along with its required and optional dependencies from source. The script ensures all necessary packages are installed, handles common errors, and logs installation steps for review.

## Features

-   Install essential packages and dependencies for Snort
-   Download and extract required source files
-   Clone and build additional components from GitHub
-   Add Snort to PATH based on shell type (bash, zsh, or other)
-   Log all installation steps and errors

## Prerequisites

Before running the script, make sure you have:

-   A Unix-like environment (e.g., Ubuntu)
-   `sudo` privileges
-   Basic development tools (e.g., `build-essential`, `wget`, `git`)

## Installation

1. **Clone the repository or download the script:**

2. **Make the script executable:**

    ```bash
    chmod +x install_snort.sh
    ```

3. **Run the script:**

    ```bash
    ./install_snort.sh
    ```

    The script will:

    - Update package lists and install required packages
    - Download and extract source files for Tcmalloc, dnet, pcre, libdaq, and Snort
    - Build and install each component
    - Optionally add Snort to your PATH
    - Log all actions and errors to `install_log.txt`

## Log File

The script logs all actions and errors to `install_log.txt` located in the same directory. Check this file for details if something goes wrong during the installation.

## Troubleshooting

-   **File Already Exists:** If a file or directory already exists, the script will skip downloading or extracting that file to avoid conflicts.
-   **Permission Errors:** Ensure you have `sudo` privileges and correct permissions for installation directories.
-   **Network Issues:** If downloading fails, verify your network connection and try running the script again.

## Contributing

If you find any issues or want to contribute improvements, feel free to submit an issue or a pull request to the repository.

## License

No license, just simple script and you can check it:)
All packet and link download form official website.

## Contact

For any questions or support, please contact [Lunox](nguyenle2k3.cs@gmail.com).

---

Thank you for using my script!
