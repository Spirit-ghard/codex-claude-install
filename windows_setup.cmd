@echo off
setlocal

where winget >nul 2>nul
if errorlevel 1 (
  echo winget is required. Install Git Bash and Node.js 22 or later, then run the four .sh files.
  exit /b 1
)

if not exist "%ProgramFiles%\Git\bin\bash.exe" (
  winget install --id Git.Git --exact --accept-package-agreements --accept-source-agreements --silent
  if errorlevel 1 exit /b 1
)
if not exist "%ProgramFiles%\nodejs\node.exe" (
  winget install --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements --silent
  if errorlevel 1 exit /b 1
)

set "PATH=%ProgramFiles%\Git\cmd;%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%BASH_EXE%" (
  echo Git Bash was not found at "%BASH_EXE%". Reopen this window and try again.
  exit /b 1
)

pushd "%~dp0"
"%BASH_EXE%" ./install_codex.sh
if errorlevel 1 goto :failed
"%BASH_EXE%" ./install_claude.sh
if errorlevel 1 goto :failed
"%BASH_EXE%" ./configure_codex.sh
if errorlevel 1 goto :failed
"%BASH_EXE%" ./configure_claude.sh
if errorlevel 1 goto :failed
popd
echo Codex and Claude Code are installed and configured.
exit /b 0

:failed
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
