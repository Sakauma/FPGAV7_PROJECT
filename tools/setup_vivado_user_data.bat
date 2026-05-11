@echo off
setlocal

call "%~dp0vivado_env.bat"

setx XILINX_LOCAL_USER_DATA "%XILINX_LOCAL_USER_DATA%"
if errorlevel 1 (
    echo Failed to persist XILINX_LOCAL_USER_DATA.
    exit /b 1
)

echo.
echo XILINX_LOCAL_USER_DATA has been saved for future terminals and Vivado sessions.
echo Close and reopen Vivado before launching synthesis again.
exit /b 0
