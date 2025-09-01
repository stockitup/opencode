@echo off
setlocal EnableDelayedExpansion

:: Colors (using ANSI escape codes - requires Windows 10+)
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "NC=[0m"

:: Function-like macros for output
set "print_info=echo %GREEN%[INFO]%NC%"
set "print_warn=echo %YELLOW%[WARN]%NC%"
set "print_error=echo %RED%[ERROR]%NC%"

%print_info% Building opencode for Windows

:: Detect architecture
set "ARCH=x64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"
if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "ARCH=arm64"

set "OS_TARGET=windows"
set "BUILD_NAME=%OS_TARGET%-%ARCH%"

%print_info% Target: %BUILD_NAME%

:: Check for required tools
%print_info% Checking prerequisites...

where bun >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    %print_error% bun is not installed. Please install bun first.
    %print_error% Visit: https://bun.sh/docs/installation
    exit /b 1
)

where go >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    %print_error% go is not installed. Please install Go first.
    %print_error% Visit: https://go.dev/dl/
    exit /b 1
)

:: Show versions
for /f "tokens=*" %%i in ('bun --version') do set "BUN_VERSION=%%i"
for /f "tokens=3" %%i in ('go version') do set "GO_VERSION=%%i"

%print_info% Found Bun version: %BUN_VERSION%
%print_info% Found Go version: %GO_VERSION%

:: Install dependencies
%print_info% Installing dependencies...
call bun install
if %ERRORLEVEL% NEQ 0 (
    %print_error% Failed to install dependencies
    exit /b 1
)

:: Get version from package.json (using PowerShell for JSON parsing)
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty version"`) do set "VERSION=%%i"
if "%VERSION%"=="" set "VERSION=dev"

%print_info% Building version: %VERSION%

:: Build directory setup
set "BUILD_DIR=packages\opencode\dist\%BUILD_NAME%"
if not exist "%BUILD_DIR%\bin" mkdir "%BUILD_DIR%\bin"

:: Build Go TUI component
%print_info% Building TUI component...
cd packages\tui

set CGO_ENABLED=0
set GOOS=%OS_TARGET%
set GOARCH=%ARCH%

go build -ldflags="-s -w -X main.Version=%VERSION%" -o "..\opencode\dist\%BUILD_NAME%\bin\tui.exe" .\cmd\opencode\main.go
if %ERRORLEVEL% NEQ 0 (
    %print_error% Failed to build TUI component
    cd ..\..
    exit /b 1
)

cd ..\..

:: Build Bun CLI component
%print_info% Building CLI component...
cd packages\opencode

:: Determine Bun target
set "BUN_TARGET=bun-%OS_TARGET%-%ARCH%"
if "%ARCH%"=="x64" (
    :: Use baseline for better compatibility
    set "BUN_TARGET=bun-%OS_TARGET%-%ARCH%-baseline"
)

:: Build with Bun
call bun build ^
    --define "OPENCODE_TUI_PATH='../../../dist/%BUILD_NAME%/bin/tui.exe'" ^
    --define "OPENCODE_VERSION='%VERSION%'" ^
    --compile ^
    --target="%BUN_TARGET%" ^
    --outfile="dist\%BUILD_NAME%\bin\opencode.exe" ^
    .\src\index.ts

if %ERRORLEVEL% NEQ 0 (
    %print_error% Failed to build CLI component
    cd ..\..
    exit /b 1
)

cd ..\..

:: Installation
set "INSTALL_DIR=%USERPROFILE%\.local\bin"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

%print_info% Installing to %INSTALL_DIR%...

:: Remove old installations if they exist
if exist "%INSTALL_DIR%\opencode.exe" del "%INSTALL_DIR%\opencode.exe"
if exist "%INSTALL_DIR%\o.exe" del "%INSTALL_DIR%\o.exe"
if exist "%INSTALL_DIR%\opencode-tui.exe" del "%INSTALL_DIR%\opencode-tui.exe"

:: Copy binaries
copy "%BUILD_DIR%\bin\opencode.exe" "%INSTALL_DIR%\opencode.exe" >nul
copy "%BUILD_DIR%\bin\tui.exe" "%INSTALL_DIR%\opencode-tui.exe" >nul

:: Create copy for 'o' command (Windows doesn't have symlinks by default)
copy "%INSTALL_DIR%\opencode.exe" "%INSTALL_DIR%\o.exe" >nul

%print_info% Installation complete!

:: Check if install directory is in PATH
echo %PATH% | findstr /C:"%INSTALL_DIR%" >nul
if %ERRORLEVEL% NEQ 0 (
    %print_warn% %INSTALL_DIR% is not in your PATH
    %print_warn% To add it to your PATH:
    echo.
    echo    1. Open System Properties
    echo    2. Click on Environment Variables
    echo    3. Edit the PATH variable
    echo    4. Add: %INSTALL_DIR%
    echo.
    echo    Or run this PowerShell command as Administrator:
    echo    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";%INSTALL_DIR%", [EnvironmentVariableTarget]::User)
)

%print_info% You can now use 'opencode' or 'o' commands
%print_info% Try running: opencode --version

endlocal