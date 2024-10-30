@ECHO OFF
set currentdir=%cd%
powershell -File "%currentdir%\pyenv-venv.ps1" %*