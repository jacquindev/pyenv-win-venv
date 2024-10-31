# Copyright 2022-2024 Arbaaz Laskar

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

param (
    [Parameter(Mandatory = $False)]
    [ValidateSet('init', 'activate', 'deactivate', 'install', 'uninstall', 'list', 'config', 'local', 'config', 'update', 'which', 'help')]
    [string]$subcommand1,
    [Parameter(Mandatory = $False)]
    [string]$subcommand2,
    [Parameter(Mandatory = $False)]
    [string]$subcommand3,
    [Parameter(Mandatory = $False, HelpMessage = "Export log message to a file")]
    [Alias('e')][switch]$log
)

# Auto-detect the shell
if ($PSVersionTable) {
    $invokedShell = "ps1"
}
else {
    $invokedShell = "bat"
}

$appDir = "$env:USERPROFILE\.pyenv-win-venv"
while (-not (Test-Path -LiteralPath $appDir)) {
    $appDir = (Resolve-Path -Path $PSScriptRoot).ProviderPath | Split-Path
}
$appEnvDir = "$appDir\envs"
$cliVersion = Get-Content "$appDir\.version"
$pyenvVersionsDir = "$Env:PYENV_ROOT\versions"
$pythonVersionFile = "$((Get-Location).Path)\.python-version"

function Main {
    # Initialize the app directories
    foreach ($dir in @($appDir, $appEnvDir)) {
        if (!(Test-Path -PathType Container $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    Export-LogError -m "App Dir: $appDir"
    Export-LogError -m "App Env Dir: $appEnvDir"
    Export-LogError -m "CLI Version: $cliVersion"
    Export-LogError -m "Pyenv Versions Dir: $pyenvVersionsDir"
    Export-LogError -m "Current Python Version File: $pythonVersionFile"

    if ($subcommand1 -eq "init") {
        # TODO:
        if ($subcommand2 -eq "root") {
            $cwd = $((Get-Location).Path)
            Export-LogError -m "Checking .python-version file: $cwd\.python-version"
            while ($cwd.length -ne 0) {
                if (Test-Path "$cwd\.python-version") {
                    Invoke-PyenvFileVersionActivate -PythonFileVersionPath "$cwd\.python-version"
                    exit
                }
                else { $cwd = Split-Path $cwd }
            }
        }
        if ($subcommand2 -eq "cwd") {
            $cwd = $((Get-Location).Path)
            $envName = (Get-Content "$cwd\.python-version")
            Export-LogError -m "Checking .python-version file: $cwd\.python-version"
            if ((Test-Path "$cwd\.python-version") -and (Test-Path -PathType Container "$cwd\$envName")) {
                Export-LogError -m "init: env: $envName"
                Export-LogError -m "Dir: $cwd\$envName exists: $(Test-Path -PathType Container "$cwd\$envName")"
                if ($invokedShell -eq "ps1") { &"$cwd\$envName\Scripts\Activate.ps1" }
                else { cmd /k "$cwd\$envName\Scripts\activate.bat" }
                exit 
            }
            else { Write-Warning "env: $envName not found in current working directory!" }
        }
        else {
            Export-LogError -m "Checking .python-version file: $pythonVersionFile"
            if (Test-Path $pythonVersionFile) {
                Invoke-PyenvFileVersionActivate -PythonFileVersionPath "$pythonVersionFile"
            }
            else {
                Write-Warning "$pythonVersionFile not found!"
            }
        }
    }

    if ($subcommand1 -eq "activate") {
        if (!$subcommand2) { 
            $activateFile = $(Get-ChildItem -Recurse -Filter "activate" -ErrorAction SilentlyContinue) 
            # Activate the virtual environment in current working directory if exists.
            if ($null -ne $activateFile) {
                $venvDir = Split-Path $activateFile | Split-Path
                if ($invokedShell -eq "ps1") {
                    $Env:PYENV_VENV_ACTIVE = $venvDir
                    &"$venvDir\Scripts\Activate.ps1"
                }
                elseif ($invokedShell -eq "bat") { cmd /k "$venvDir\Scripts\activate.bat" }
                Export-LogError "Virtualenv: $venvDir activated."
            }
            else {
                # Print help message.
                $activateFile = $activateFile | Out-Null
                Invoke-HelpActivate; exit 
            }
        }
        elseif (Test-Path -PathType Container "$appEnvDir\$subcommand2") {
            if ($invokedShell -eq "ps1") {
                $Env:PYENV_VENV_ACTIVE = $subcommand2
                &"$appEnvDir\$subcommand2\Scripts\Activate.ps1"
            }
            elseif ($invokedShell -eq "bat") { cmd /k "$appEnvDir\$subcommand2\Scripts\activate.bat" }
        }
        else { Write-Warning "Env: $subcommand2 is not installed. Please install by using `"pyenv-venv install <python_version> $subcommand2"`" }
    }

    if ($subcommand1 -eq "deactivate") {
        if ($env:VIRTUAL_ENV) {
            $env:PYENV_VENV_ACTIVE = ""
            if ($invokedShell -eq "ps1") { deactivate }
            elseif ($invokedShell -eq "bat") { cmd /k deactivate }
        }
        else { Write-Warning "No active virtualenv found to deactivate." }
    }

    if ($subcommand1 -eq "install") {
        if (!$subcommand2 -or !$subcommand3) { Invoke-HelpInstall; exit }
        if (Test-Path -PathType Container "$pyenvVersionsDir\$subcommand2") {
            if ($subcommand3 -ne "self") {
                if (!(Test-Path -PathType Container "$appEnvDir\$subcommand3")) {
                    Write-Host "Installing env:" -NoNewline
                    Write-Host " $subcommand3 " -NoNewline -ForegroundColor "Green"
                    Write-Host "using Python v$subcommand2..."
                    # Deactivate the active python env if any
                    if ($env:VIRTUAL_ENV) {
                        $PYENV_VENV_ACTIVE = $Env:PYENV_VENV_ACTIVE
                        deactivate
                    }
                    pyenv shell $subcommand2
                    python -m venv "$appEnvDir\$subcommand3"

                    # Reactivate the python env if any
                    if ($PYENV_VENV_ACTIVE) {
                        pyenv-venv activate $PYENV_VENV_ACTIVE
                    }
                }
                else { Write-Warning "`"$subcommand3`" already exists. Please choose another name for the env." }
            }
            else { Write-Warning "Cannot create an env called `"self`" since while uninstalling `pyenv-venv uninstall self` is already a pre-existing command." }
        }
        elseif ($subcommand2 -eq "cwd" -and $subcommand3 -ne "self") {
            $cwd = $((Get-Location).Path)
            if (!(Test-Path -PathType Container "$cwd\$subcommand3")) {
                $pythonVersion = $(Write-Host "Input the Python version to use for the current directory: " -NoNewline; Read-Host)
                if (Test-Path -PathType Container "$pyenvVersionsDir\$pythonVersion") {
                    Write-Host "Installing env:" -NoNewline
                    Write-Host " $subcommand3 " -NoNewline -ForegroundColor "Green"
                    Write-Host "using Python" -NoNewline
                    Write-Host " v$pythonVersion" -ForegroundColor "Yellow"

                    if ($env:VIRTUAL_ENV) { $PYENV_VENV_ACTIVE = $Env:PYENV_VENV_ACTIVE; deactivate }
                    pyenv shell $pythonVersion
                    python -m venv "$cwd\$subcommand3"
                    if ($PYENV_VENV_ACTIVE) { pyenv-venv activate $PYENV_VENV_ACTIVE }
                }
                else {
                    Write-Warning "Python v$pythonVersion is not installed. Please install it first by using `"pyenv install <python_version>"`"
                }
            }
            else { Write-Warning "`"$subcommand3`" already exists in current directory. Please choose another name for the env." }
        }
        else { Write-Warning "Python v$subcommand2 is not installed. Install using `"pyenv install $subcommand2"`" }
    }

    if ($subcommand1 -eq "uninstall") {
        if (!$subcommand2) { Invoke-HelpUninstall; exit }
        if ($subcommand2 -eq "self") {
            $title = "Uninstall pyenv-venv and all the installed envs!"
            $question = "Are you sure you want to procees?"
            $choices = '&Yes', '&No'
            $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
            if ($decision -eq 0) { Remove-PyEnvWinVenv }
        }
        elseif (Test-Path -PathType Container "$appEnvDir\$subcommand2") {
            Write-Host "Uninstalling env:" -NoNewline 
            Write-Host " $subcommand2 " -NoNewline -ForegroundColor "Yellow"
            Remove-Item -Recurse -Force "$appEnvDir\$subcommand2"
        }
        # Remove current python env in current working directory.
        elseif (Test-Path -PathType Container "$((Get-Location).Path)\$subcommand2") {
            Write-Host "Uninstalling env:" -NoNewline 
            Write-Host " $subcommand2 " -NoNewline -ForegroundColor "Yellow"
            Remove-Item -Recurse -Force "$((Get-Location).Path)\$subcommand2"
        }
        else { Write-Warning "$subcommand2 is not installed so it cannot be uninstalled." }
    }

    if ($subcommand1 -eq "list") {
        if (!$subcommand2) { Invoke-HelpList; exit }
        if ($subcommand2 -eq "envs") { FetchEnvs }
        if ($subcommand2 -eq "python") { FetchPythonVersions }
    }

    if ($subcommand1 -eq "config") { ConfigInfo }

    if ($subcommand1 -eq "update" -and $subcommand2 -eq "self") {
        # Check if the CLI was installed using Git
        git -C $appDir rev-parse
        if ($LASTEXITCODE -eq 0) {
            Write-Host "CLI installed using Git." -ForegroundColor "Yellow"
            git -C $appDir fetch origin | Out-Null
            $changeLog = $(git -C $appDir log ..origin/main --pretty=format:"%Cblue* %C(auto)%h: %Cgreen%s%n%b")
            if ($null -ne $changeLog) {
                Write-Host "Changelog:" -ForegroundColor "Blue"
                Write-Host "$changeLog"
            }
            Write-Host "$(git -C $appDir pull origin)" -Foreground "Green"
        }
        else {
            Write-Host "CLI installed using install script"
            # TODO: Update script for fork version of install-pyenv-win-venv.ps1 script
            Write-Host "Downloading & running install-pyenv-win-venv.ps1"
            $LastExitCode = 0 # reset the exit code after the git command
            # Download and run the installation script
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/jacquindev/pyenv-win-venv/refs/heads/main/bin/install-pyenv-win-venv.ps1" -OutFile "$HOME\install-pyenv-win-venv.ps1";
            &"$HOME\install-pyenv-win-venv.ps1"
        }
    }

    if ($subcommand1 -eq "which") {
        if (!$subcommand2) { Invoke-HelpWhich; exit }
        if (Test-Path "$Env:VIRTUAL_ENV\Scripts\$subcommand2.exe") { Write-Host "$Env:VIRTUAL_ENV\Scripts\$subcommand2.exe" }
        else { pyenv which $subcommand2 }
    }

    if ($subcommand1 -eq "help") {
        if (!$subcommand2) { Invoke-HelpMenu; exit }
        if ($subcommand2 -eq "init") { Invoke-HelpInit; exit }
        elseif ($subcommand2 -eq "activate") { Invoke-HelpActivate; exit }
        elseif ($subcommand2 -eq "install") { Invoke-HelpInstall; exit }
        elseif ($subcommand2 -eq "uninstall") { Invoke-HelpUninstall; exit }
        elseif ($subcommand2 -eq "list") { Invoke-HelpList; exit }
        elseif ($subcommand2 -eq "which") { Invoke-HelpWhich; exit }
        else { Write-Warning "Command is not valid! Run `"pyenv-win-venv help`" for the HelpMenu" }
    }

    if (!$subcommand1) { Invoke-HelpMenu; exit }
}

function Export-LogError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $False, HelpMessage = "Path to the log file")]
        [Alias('f')][string]
        $FilePath = "$env:USERPROFILE\pyenv_venv.log",
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Log message")]
        [Alias('m')][string]
        $Message
    )

    if (!(Test-Path -Path $FilePath -PathType Leaf)) {
        $FilePath = New-Item -ItemType File -Path $FilePath -Force -ErrorAction Stop
    }

    $FilePath = (Resolve-Path -Path $FilePath).ProviderPath
    $timeStamp = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")

    if ($log) { 
        Write-Output "$timeStamp  $Message" | Out-File -Path $FilePath -Append
    }
}

function Invoke-PyenvFileVersionActivate {
    param ([string]$PythonFileVersionPath)
    $envName = (Get-Content $PythonFileVersionPath)
    Export-LogError -m "init: env: $envName"
    Export-LogError -m "Dir: $appEnvDir\$envName exists: $(Test-Path -PathType Container "$appEnvDir\$envName")"
    if ($envName -and (Test-Path -PathType Container "$appEnvDir\$envName")) {
        if ($invokedShell -eq "ps1") { &"$appEnvDir\$envName\Scripts\Activate.ps1" }
        else { cmd /k "$appEnvDir\$envName\Scripts\activate.bat" }
    }
}

function Remove-PyEnvVenvVars() {
    $PathParts = [System.Environment]::GetEnvironmentVariable('PATH', "User") -Split ";"
    $NewPathParts = $PathParts.Where{ $_ -ne $BinPath }
    $NewPath = $NewPathParts -Join ";"
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, "User")
}

function Remove-PyEnvVenvProfile() {
    $CurrentProfile = Get-Content $Profile
    $UpdatedProfile = $CurrentProfile.Replace("pyenv-venv init", "")
    Set-Content -Path  $Profile -Value $UpdatedProfile
}

function Remove-PyEnvWinVenv() {
    Write-Host "Removing $appDir" -ForegroundColor "Blue"
    If (Test-Path $appDir) {
        Remove-Item -Path $appDir -Recurse -Force
    }
    Write-Host "Removing environment variables"
    Remove-PyEnvVenvVars
    Remove-PyEnvVenvProfile
}

function FetchPythonVersions {
    ''
    Write-Host "Python Versions installed:" -ForegroundColor "Green"
    Write-Host "--------------------------" -ForegroundColor "Green"
    pyenv versions
}

function FetchEnvs {
    ''
    Write-Host "Envs installed:" -ForegroundColor "Green"
    Write-Host "---------------" -ForegroundColor "Green"
    (Get-ChildItem -Directory $appEnvDir | Select-Object -Expand Name)
}

function ConfigInfo {
    Write-Host "App Directory: " -NoNewline
    Write-Host "$appDir" -ForegroundColor "Green"
    Write-Host "App Env Directory: " -NoNewline
    Write-Host "$appEnvDir" -ForegroundColor "Green"
}

# Help functions
function Invoke-HelpActivate {
    Write-Host "Usage: pyenv-venv activate <env_name>

Parameters:
env_name    name of the installed virtualenv

Example: `pyenv-venv activate test_env`
"
}

function Invoke-HelpInstall {
    Write-Host "Usage: pyenv-venv install <python_ver> <env_name>

Parameters:
python_ver    name of the installed python version
env_name      name of the installed virtualenv
    
Example: `
> pyenv-venv install 3.8.5 test_env 
=> install virtual env named 'test env' with python version '3.8.5' for all hosts

> pyenv-venv install cwd test_env 
=> install virtual env named 'test_env' for current directory with specified python version.`
"
}

function Invoke-HelpUninstall {
    Write-Host "Usage: pyenv-venv uninstall <env_name>

Parameters:
env_name    name of the installed virtualenv
self        uninstall the CLI itself

Example: `pyenv-venv uninstall test_env`
"
}

function Invoke-HelpList {
    Write-Host "Usage: pyenv-venv list <command>

Commands:
envs        list all installed envs
python      list all installed python versions

Example: `pyenv-venv list envs`
"
}

function Invoke-HelpInit {
    Write-Host "Usage: pyenv-venv init <command>

Search for .python-version file in the 
current directory and activate the env

Commands:
cwd     search for .python-version file and activate the env of current working directory 
root    search for .python-version file by traversing from
the current working directory to the root
    
Example: `pyenv-venv init root`
"
}

function Invoke-HelpWhich {
    Write-Host "Usage: pyenv-venv which <exec_name>

Shows the full path of the executable selected. 

Parameters:
exec_name   name of the executable

Example: `pyenv-venv which python`
"
}


function Invoke-HelpMenu {
    Write-Host "pyenv-win-venv v$cliVersion
Copyright (c) Arbaaz Laskar <arzkar.dev@gmail.com>

Usage: pyenv-win-venv <command> <args>

A CLI to manage virtual envs with pyenv-win

Commands:
init                search for .python-version file in the 
                    current directory and activate the env
activate            activate an env
deactivate          deactivate an env
install             install an env
uninstall           uninstall an env
uninstall self      uninstall the CLI and its envs
list <command>      list all installed envs/python versions
local               set the given env in .python-version file
config              show the app directory
update self         update the CLI to the latest version
which <command>     show the full path to an executable
help <command>      show the CLI/<command> menu

Flags:
log                 To show debug log
"
}
Main