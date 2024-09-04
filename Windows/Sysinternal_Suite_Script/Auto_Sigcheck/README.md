# DLL Integrity Check Script

This script checks the integrity of `.dll` files using **Sigcheck** from the Sysinternals Suite. It reads a list of `.dll` file paths from a text file, checks their signatures, and logs the results.

## Prerequisites

- Windows operating system
- [Sysinternals Suite](https://docs.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite) (specifically `sigcheck.exe`)
- Basic knowledge of batch scripting

## How It Works

1. **Initialization**:
   - Deletes any existing log file.
   - Creates a new log file and adds a header.

2. **File Integrity Check**:
   - Iterates through a list of `.dll` file paths.
   - For each file:
     - If the file exists, runs `sigcheck.exe` to verify its integrity and logs the results.
     - If the file does not exist, logs an error message.

3. **Completion**:
   - Outputs a message indicating that the process has finished.

## Getting Started

### 1. Place the Required Files

- Place `sigcheck.exe` in the same directory as the script.
- Create a text file named `list_files.txt` in the same directory. This file should contain the full paths to the `.dll` files you wish to check, with each path on a new line.

### 2. Run the Script

- Open a command prompt with administrator privileges.
- Navigate to the directory containing the script.
- Run the script by typing:

  ```batch
  check_integrity.bat
  ```

### 3. View the Results

- After the script completes, check the `sigcheck_results.log` file in the same directory for the results.

## Example

Here’s an example of what your `list_files.txt` might look like:

```
C:\Windows\System32\example1.dll
C:\Program Files\Example\example2.dll
```

## Customization

You can edit the `check_integrity.bat` script if you need to adjust paths or add additional functionality.

## Troubleshooting

- **"No matching files were found"**: Ensure the file paths in `list_files.txt` are correct.
- **Permissions Issues**: Run the script as an administrator.
- **File Not Found Errors**: Verify that the `.dll` files listed in `list_files.txt` exist on your system.

## License

No license, just simple script so you can check that:)

## Acknowledgements

- This script uses `sigcheck.exe` from the [Sysinternals Suite](https://docs.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite) by Microsoft.
