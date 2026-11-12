@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Instalacni wizard — prepis videa

REM ============================================================
REM  install_wizard.bat — pruvodce instalaci projektu
REM  1) zkontroluje Python a necha uzivatele chybejici nastroje
REM     doinstalovat (pocka na Enter a znovu overi)
REM  2) zepta se na slozku pro Whisper modely
REM  3) spusti setup_env.py — .venv, balicky, CUDA DLL, model
REM ============================================================

echo.
echo ============================================
echo   INSTALACNI WIZARD — prepis videa
echo ============================================
echo.

REM ---------- 1) kontrola Pythonu ----------
:check_python
echo Kontroluji Python ...
set "PYEXE="
python --version >nul 2>&1 && set "PYEXE=python"
if not defined PYEXE (
    py --version >nul 2>&1 && set "PYEXE=py"
)
if not defined PYEXE (
    py -3 --version >nul 2>&1 && set "PYEXE=py -3"
)

if defined PYEXE (
    for /f "tokens=*" %%v in ('%PYEXE% --version 2^>^&1') do set "PYVER=%%v"
    echo   Nalezen: %PYVER%  (%PYEXE%)
    echo.
    goto python_ok
)

echo.
echo *** CHYBI: Python neni na tomto pocitaci (nebo neni v PATH) ***
echo.
echo Co mas udelat:
echo   1. Nainstaluj Python 3.10 az 3.13 — stahnout na
echo      https://www.python.org/downloads/
echo      (nebo pres Winget:  winget install Python.Python.3.12 )
echo   2. Pri instalaci ZATRHNISTE "Add python.exe to PATH".
echo   3. Zavri a znovu otevri toto okno (cmd), at se PATH promene.
echo.
echo Podrobny navod je v souboru INSTALLSTEPS.md
echo (ve slozce projektu).
echo.
pause
cls
goto check_python

:python_ok
REM Python musi byt aspoň 3.10 — overime
echo %PYVER% | findstr "3.1" >nul
if errorlevel 1 (
    echo.
    echo *** POZOR: verze %PYVER% muze byt moc stara. ***
    echo   Potrebujeme Python 3.10 az 3.13.
    echo   Nainstaluj novejsi verzi — viz INSTALLSTEPS.md
echo.
    pause
    cls
    goto check_python
)

REM ---------- 2) Whisper modely (projektova cache) ----------
echo.
echo Whisper modely se budou ukladat do projektove slozky:
echo   %~dp0.whisper\.cache\huggingface
echo (prepise se to promennou HF_HOME — staci prepsat v prepis.py)
echo.

REM ---------- 3) instalace projektu ----------
echo Spoustim instalaci (setup_env.py) ...
echo.
call %PYEXE% setup_env.py
set "VYSLEDEK=%errorlevel%"

echo.
if %VYSLEDEK%==0 (
    echo ============================================
    echo   INSTALACE DOBEHLA — HOTOVO
    echo ============================================
    echo.
    echo Projekt je pripraven. Spusteni:
    echo   start.bat        ^(dvojklik — pyta se na prepis^)
    echo.
) else (
    echo ============================================
    echo   INSTALACE SKONCILA CHYBOU (kod %VYSLEDEK%)
    echo ============================================
    echo.
    echo Zkontroluj vyse uvedenou chybu, oprav ji a
echo   spust install_wizard.bat znovu — vse je
echo   opakovatelne.
echo.
)
pause
