@echo off
setlocal

REM Đường dẫn tới Sigcheck (Sử dụng đường dẫn tương đối)
set sigcheck_path=%~dp0sigcheck.exe

REM Đường dẫn tới tệp chứa danh sách các tệp .dll cần kiểm tra
set file_list_path=%~dp0list_files.txt

REM Đường dẫn tới tệp log kết quả
set log_file=%~dp0sigcheck_results.log

REM Xóa tệp log cũ nếu có
if exist "%log_file%" del "%log_file%"

REM Thêm tiêu đề vào tệp log
echo Checking integrity of DLL files > "%log_file%"
echo ==================================== >> "%log_file%"

REM Kiểm tra từng tệp trong danh sách
for /f "tokens=*" %%i in (%file_list_path%) do (
    if exist "%%i" (
        echo Checking %%i... >> "%log_file%"
        "%sigcheck_path%" -vt "%%i" >> "%log_file%"
        echo ------------------------------------------------ >> "%log_file%"
    ) else (
        echo ERROR: File not found - %%i >> "%log_file%"
        echo ------------------------------------------------ >> "%log_file%"
    )
)

echo Finished checking. Results are saved in %log_file%.
endlocal
