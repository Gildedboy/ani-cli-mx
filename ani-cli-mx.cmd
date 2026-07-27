@echo off
setlocal

set "BASH_EXE="

if defined GIT_INSTALL_ROOT if exist "%GIT_INSTALL_ROOT%\bin\bash.exe" set "BASH_EXE=%GIT_INSTALL_ROOT%\bin\bash.exe"
if not defined BASH_EXE if defined SCOOP if exist "%SCOOP%\apps\git\current\bin\bash.exe" set "BASH_EXE=%SCOOP%\apps\git\current\bin\bash.exe"
if not defined BASH_EXE if exist "%USERPROFILE%\scoop\apps\git\current\bin\bash.exe" set "BASH_EXE=%USERPROFILE%\scoop\apps\git\current\bin\bash.exe"
if not defined BASH_EXE if defined SCOOP_GLOBAL if exist "%SCOOP_GLOBAL%\apps\git\current\bin\bash.exe" set "BASH_EXE=%SCOOP_GLOBAL%\apps\git\current\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramData%\scoop\apps\git\current\bin\bash.exe" set "BASH_EXE=%ProgramData%\scoop\apps\git\current\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LocalAppData%\Programs\Git\bin\bash.exe"

if not defined BASH_EXE (
    >&2 echo ani-cli-mx necesita Git for Windows. Instalalo con: scoop install git
    exit /b 1
)

if not exist "%~dp0ani-cli-mx-core" (
    >&2 echo No se encontro ani-cli-mx-core junto al launcher de Windows.
    exit /b 1
)

set "ANI_CLI_WINDOWS=1"
set "ANI_CLI_PACKAGE_MANAGER=scoop"
set "ANI_CLI_NAME=ani-cli-mx"
set "ANI_CLI_LOG_TAG=ani-cli-mx"
set "ANI_CLI_STATE_NAME=ani-cli-mx"
"%BASH_EXE%" "%~dp0ani-cli-mx-core" %*
exit /b %ERRORLEVEL%
