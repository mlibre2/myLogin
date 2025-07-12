@echo off

mode con cols=80 lines=10

color 0b

set "_file_=myLogin"

title Compilador Aut2Exe

echo.
echo. Se compilara el archivo:
echo.
echo.   %_file_%.au3
echo.
echo.

pause

cls

echo.
echo. Compilando...
echo.

cd /d "C:\Program Files (x86)\AutoIt3\Aut2Exe"

@echo on

start /wait Aut2Exe.exe /in "%_file_%.au3" /out "%_file_%.exe" /comp 4 /pack

@echo off

echo.
echo. Listo!
echo.
echo.

pause
