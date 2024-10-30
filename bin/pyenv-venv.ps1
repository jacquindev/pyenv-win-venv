# Alias for pyenv-win-venv.ps1
Set-Location $PSScriptRoot
[System.Environment]::CurrentDirectory = $PSScriptRoot

& "$PSScriptRoot\pyenv-win-venv.ps1" @args