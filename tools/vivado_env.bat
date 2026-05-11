@echo off
rem Configure Vivado child processes to use a local-data path without spaces.
rem This avoids Common 17-1257: Failed to create directory 'C' on OOC IP runs.

set "XILINX_LOCAL_USER_DATA=%SystemDrive%\XilinxLocalUserData"
2>nul mkdir "%XILINX_LOCAL_USER_DATA%"
if exist "%XILINX_LOCAL_USER_DATA%\" goto :done

for %%I in ("%TEMP%") do set "TEMP_SHORT=%%~sI"
if defined TEMP_SHORT (
    set "XILINX_LOCAL_USER_DATA=%TEMP_SHORT%\XilinxLocalUserData"
) else (
    set "XILINX_LOCAL_USER_DATA=%TEMP%\XilinxLocalUserData"
)
2>nul mkdir "%XILINX_LOCAL_USER_DATA%"

:done
echo XILINX_LOCAL_USER_DATA=%XILINX_LOCAL_USER_DATA%
