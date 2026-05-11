@echo off
setlocal

call "%~dp0vivado_env.bat"

set "REPO_ROOT=%~dp0.."
set "PROJECT_FILE=%REPO_ROOT%\LPVX30_0040\LPVX30_0040.xpr"

if not defined VIVADO_2025_BAT (
    set "VIVADO_2025_BAT=D:\AMD\2025.2\Vivado\bin\vivado.bat"
)

if not exist "%VIVADO_2025_BAT%" (
    echo Vivado 2025.2 was not found: %VIVADO_2025_BAT%
    echo Set VIVADO_2025_BAT to your vivado.bat path and run this script again.
    exit /b 1
)

call "%VIVADO_2025_BAT%" "%PROJECT_FILE%"
exit /b %ERRORLEVEL%
