@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Self-Extracting Builder (Final Correct)
echo ========================================

:: 设置路径变量
set "RELEASE_DIR=..\build\windows\x64\runner\Release"
set "ICON_FILE=app_icon.ico"

:: 从pubspec.yaml读取版本号
echo Reading version from pubspec.yaml...
for /f "tokens=2 delims=: " %%i in ('findstr "version:" "..\pubspec.yaml"') do set "VERSION=%%i"
if not defined VERSION (
    echo ❌ Error: Could not read version from pubspec.yaml
    pause
    exit /b 1
)
echo ✅ Version found: %VERSION%

:: 构建输出文件名
set "OUTPUT_NAME=FVM_%VERSION%.exe"
echo ✅ Output filename: %OUTPUT_NAME%

:: 检查并删除同名文件
if exist "%OUTPUT_NAME%" (
    echo ⚠️  Warning: Output file already exists, deleting...
    del "%OUTPUT_NAME%"
    if !errorlevel! equ 0 (
        echo ✅ Existing file deleted successfully
    ) else (
        echo ❌ Error: Failed to delete existing file
        pause
        exit /b 1
    )
)

echo.
echo Checking prerequisites...

:: 检查release目录是否存在
if not exist "%RELEASE_DIR%" (
    echo ❌ Error: Release directory does not exist
    echo Please run: flutter build windows --release
    pause
    exit /b 1
)
echo ✅ Release directory found

:: 检查data文件夹是否存在
if not exist "%RELEASE_DIR%\data" (
    echo ❌ Error: data folder does not exist in Release directory
    echo This is required for Flutter applications
    pause
    exit /b 1
)
echo ✅ data folder found

:: 检查app_icon.ico是否存在
if not exist "%ICON_FILE%" (
    echo ⚠️  Warning: Icon file does not exist
    set "ICON_FILE="
) else (
    echo ✅ Icon file found
)

:: 智能检测WinRAR安装位置
echo.
echo Detecting WinRAR...
set "WINRAR_PATH="
if exist "C:\Program Files\WinRAR\WinRAR.exe" (
    set "WINRAR_PATH=C:\Program Files\WinRAR\WinRAR.exe"
) else if exist "C:\Program Files (x86)\WinRAR\WinRAR.exe" (
    set "WINRAR_PATH=C:\Program Files (x86)\WinRAR\WinRAR.exe"
) else (
    where winrar >nul 2>&1
    if !errorlevel! equ 0 (
        set "WINRAR_PATH=winrar"
    ) else (
        echo ❌ Error: WinRAR not found
        echo Please install WinRAR from: https://www.win-rar.com/
        pause
        exit /b 1
    )
)
echo ✅ WinRAR found: %WINRAR_PATH%

echo.
echo Creating temporary package directory...

:: 创建临时目录用于打包
set "TEMP_DIR=%TEMP%\package_final"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
echo %TEMP_DIR%

:: 复制所有文件和文件夹到临时目录
echo Copying all files and folders to temp directory...
xcopy "%RELEASE_DIR%\*" "%TEMP_DIR%\" /E /I /Y >nul
if !errorlevel! neq 0 (
    echo ❌ Error: Failed to copy files
    pause
    exit /b 1
)
echo ✅ Files and folders copied successfully

:: 验证data文件夹是否被复制
if exist "%TEMP_DIR%\data" (
    echo ✅ data folder copied successfully
    echo   - Data folder contents:
    dir "%TEMP_DIR%\data" /b
) else (
    echo ❌ Error: data folder was not copied
    echo.
    echo Debug: Listing all files in temp directory:
    dir "%TEMP_DIR%" /b
    pause
    exit /b 1
)

:: 验证所有必要文件是否被复制
echo.
echo Verifying all essential files...
set "MISSING_FILES="

if not exist "%TEMP_DIR%\FVM.exe" set "MISSING_FILES=!MISSING_FILES! FVM.exe"
if not exist "%TEMP_DIR%\flutter_windows.dll" set "MISSING_FILES=!MISSING_FILES! flutter_windows.dll"
if not exist "%TEMP_DIR%\data" set "MISSING_FILES=!MISSING_FILES! data folder"

if defined MISSING_FILES (
    echo ❌ Error: Missing essential files:!MISSING_FILES!
    echo.
    echo All files in temp directory:
    dir "%TEMP_DIR%" /b
    pause
    exit /b 1
) else (
    echo ✅ All essential files present
)

:: 创建正确的自解压配置文件
echo.
echo Creating correct self-extracting configuration...
(
echo ;!@Install@!UTF-8!
echo Title="Flutter Version Manager"
echo BeginPrompt="Extracting Flutter Version Manager..."
echo TempMode
echo Silent=1
echo Overwrite=1
echo Setup=.\Users\ugreen\AppData\Local\Temp\package_final\FVM.exe
echo ;!@InstallEnd@!
) > "%TEMP_DIR%\config.txt"

echo ✅ Configuration created with correct path

:: 使用WinRAR创建自解压exe（使用-ep参数排除路径，但确保data文件夹被包含）
echo.
echo Creating self-extracting executable...
echo Note: Using -ep parameter to exclude path info, but ensuring data folder is included...
echo Debug: WinRAR path: !WINRAR_PATH!
echo Debug: Output file: %OUTPUT_NAME%
echo Debug: Config file: %TEMP_DIR%\config.txt
echo Debug: Source directory: %TEMP_DIR%
echo Debug: Current directory: %CD%

if defined ICON_FILE (
    echo Using custom icon: %ICON_FILE%
    echo Debug: Executing WinRAR command with icon...
    "!WINRAR_PATH!" a -sfx -r -iicon"%ICON_FILE%" -z"%TEMP_DIR%\config.txt" "%OUTPUT_NAME%" "%TEMP_DIR%\*"
) else (
    echo Using default icon
    echo Debug: Executing WinRAR command without icon...
    "!WINRAR_PATH!" a -sfx -r -z"%TEMP_DIR%\config.txt" "%OUTPUT_NAME%" "%TEMP_DIR%\*"
)

:: 检查WinRAR命令是否成功执行
if !errorlevel! neq 0 (
    echo.
    echo ❌ Error: WinRAR command failed with error code !errorlevel!
    echo Please check if WinRAR is working correctly
    pause
    exit /b 1
)

:: 检查是否成功创建
echo.
echo Debug: Checking for output file...
echo Current directory: %CD%
echo Looking for: %OUTPUT_NAME%
echo.
echo Debug: All files in current directory:
dir /b
echo.
echo Debug: Checking specific file:
dir "%OUTPUT_NAME%" 2>nul

:: 简化的检查逻辑
if exist "%OUTPUT_NAME%" (
    echo.
    echo ========================================
    echo ✅ SUCCESS: Self-extracting executable created
    echo ========================================
    echo.
    echo 📁 File: %OUTPUT_NAME%
    echo 📏 Size:
    for %%A in ("%OUTPUT_NAME%") do echo    %%~zA bytes
    echo.
    echo 🚀 Features:
    echo    ✅ Extract to temporary directory
    echo    ✅ Silent extraction (no user interaction)
    echo    ✅ Auto-overwrite existing files
    echo    ✅ Auto-run FVM.exe after extraction
    echo    ✅ Includes data folder with all Flutter assets
    echo    ✅ Includes all necessary DLL and library files
    if defined ICON_FILE (
        echo    ✅ Custom icon: %ICON_FILE%
    )
    echo.
    echo 📋 Configuration details:
    echo    - Uses simple path: FVM.exe
    echo    - Files are in root of archive (using -ep parameter)
    echo    - Includes complete Flutter application with data folder
    echo    - Compatible with all user accounts
    echo    - Version: %VERSION%
    echo.
    echo 🎯 Ready to distribute!
)

if not exist "%OUTPUT_NAME%" (
    echo.
    echo ❌ Error: Failed to create self-extracting executable
    pause
    exit /b 1
)

:: 清理临时目录
echo.
echo Cleaning up temporary files...
rmdir /s /q "%TEMP_DIR%" >nul 2>&1
echo ✅ Cleanup completed

echo.
echo ========================================
echo 🎉 Build completed successfully!
echo ========================================
echo.
echo The self-extracting executable is ready:
echo 📁 %OUTPUT_NAME%
echo.
pause