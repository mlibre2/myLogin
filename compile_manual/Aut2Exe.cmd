@echo off
setlocal enabledelayedexpansion

:: --- check operating system version
for /f "tokens=3 delims=." %%b in ('ver') do set /a "win_build=%%b" 2>nul

:: --- Open old console in Windows 11
if !win_build! geq 22000 (
	if not exist "%~dp0conhost.lock" (
		echo. > "%~dp0conhost.lock" && start /b conhost "%~f0" & exit
	) else (
		del /q "%~dp0conhost.lock" 2>nul
	)
)

mode con cols=80 lines=10
color 3f
title Auto2Exe Compiler

set "_Aut2Exe_=NULL"
set "_fileName_=myLogin"

echo.
echo.  File to compile:
echo.
echo.      %_fileName_%.au3
echo.
echo.
echo.  ** Make sure the file is in the same directory **
echo.

pause

if exist "%PROGRAMFILES(X86)%" (
    set "_Aut2Exe_=%PROGRAMFILES(X86)%\AutoIt3\Aut2Exe\Aut2Exe.exe"
) else (
    set "_Aut2Exe_=%PROGRAMFILES%\AutoIt3\Aut2Exe\Aut2Exe.exe"
)

if not exist "%_Aut2Exe_%" (
    msg * ERROR: Could not find the path to Aut2Exe.exe
    exit /b 1
)

if not exist "%_fileName_%.au3" (
    msg * ERROR: Could not find the file %_fileName_%.au3
    exit /b 1
)

cls
mode con cols=50 lines=4
color 2f

echo.
echo.  Compiling...
echo.

start /wait "" "%_Aut2Exe_%" /in "%_fileName_%.au3" /out "%_fileName_%.exe" /icon "Threat.contrast-white.ico" /comp 0 /nopack

if exist "%_fileName_%.exe" (
    msg * Done! File compiled successfully.
) else (
    msg * ERROR: Compilation failed.
)

exit /b 0
