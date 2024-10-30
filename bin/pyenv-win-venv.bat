@ECHO OFF
set currentdir=%~dp0
powershell -File "%currentdir%\pyenv-venv.ps1" %*