@echo off
mode con cols=80 lines=10
color 3f
title Compilador Aut2Exe

set "_Aut2Exe_=NULL"
set "_fileName_=myLogin"

echo.
echo.  Archivo a compilar:
echo.
echo.      %_fileName_%.au3
echo.
echo.
echo.  ** Verifique que el archivo este en el mismo directorio **
echo.

pause

if exist "%PROGRAMFILES(X86)%" (
    set "_Aut2Exe_=%PROGRAMFILES(X86)%\AutoIt3\Aut2Exe\Aut2Exe.exe"
) else (
    set "_Aut2Exe_=%PROGRAMFILES%\AutoIt3\Aut2Exe\Aut2Exe.exe"
)

if not exist "%_Aut2Exe_%" (
    msg * ERROR: No se encuentra la ruta del Aut2Exe.exe
    exit /b 1
)

if not exist "%_fileName_%.au3" (
    msg * ERROR: No se encuentra el archivo %_fileName_%.au3
    exit /b 1
)

cls
mode con cols=50 lines=4
color 2f

echo.
echo.  Compilando...
echo.

start /wait "" "%_Aut2Exe_%" /in "%_fileName_%.au3" /out "%_fileName_%.exe" /comp 4 /pack

if exist "%_fileName_%.exe" (
    msg * Listo! Archivo compilado correctamente.
) else (
    msg * ERROR: No se ha compilado.
)

exit /b 0
