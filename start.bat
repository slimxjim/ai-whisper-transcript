@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Prepis videa na text

if not exist ".venv\Scripts\python.exe" (
    echo.
    echo Chyba: neni pripravene prostredi .venv
    echo Nejdřív spust "bash setup.sh"
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Prepis videa na text (Whisper, cesky)
echo ============================================
echo.
echo Co chces prepsat?
echo   1 = jeden video soubor
echo   2 = slozka se vsemi videi (vcetne podadresaru)
echo.
set /p VYBER="Zadej 1 nebo 2 a stiskni Enter: "
echo.

if "%VYBER%"=="1" goto jeden
if "%VYBER%"=="2" goto slozka
echo Neplatna volba, koncim.
pause
exit /b 1

:jeden
set /p CESTA="Cesta k video souboru: "
if not exist "%CESTA%" (
    echo.
    echo Chyba: soubor "%CESTA%" neexistuje.
    pause
    exit /b 1
)
echo.
echo Spoustim prepis "%CESTA%" ...
echo.
".venv\Scripts\python.exe" prepis.py "%CESTA%" "%CESTA%.prepis.txt"
set VYSLEDEK=%errorlevel%
goto konec

:slozka
set /p CESTA="Cesta k adresari s videi: "
if not exist "%CESTA%" (
    echo.
    echo Chyba: adresar "%CESTA%" neexistuje.
    pause
    exit /b 1
)
echo.
echo Spoustim davkove prepsani "%CESTA%" ...
echo.
".venv\Scripts\python.exe" prepis_batch.py "%CESTA%"
set VYSLEDEK=%errorlevel%
goto konec

:konec
echo.
if %VYSLEDEK%==0 (
    echo ============================================
    echo   HOTOVO
    echo ============================================
) else (
    echo ============================================
    echo   Skoncilo s chybou (kod %VYSLEDEK%)
    echo ============================================
)
echo.
pause
