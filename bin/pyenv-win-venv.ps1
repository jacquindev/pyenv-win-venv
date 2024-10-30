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

[CmdletBinding()]
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
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $invokedShell = "bat"
}
else {
    $invokedShell = "ps1"
}

$appDir = "$env:USERPROFILE\.pyenv-win-venv"
while (-not (Test-Path -LiteralPath $appDir)) {
    Set-Location $PSScriptRoot
    [System.Environment]::CurrentDirectory = $PSScriptRoot
    $appDir = (Resolve-Path -Path $PSScriptRoot).ProviderPath | Split-Path
}
$appEnvDir = "$appDir\envs"
$cliVersion = Get-Content "$appDir\.version"
$pyenvVersionsDir = "$Env:PYENV_ROOT\versions"
$cwd = $((Get-Location).Path)
$pythonVersionFile = "$cwd\.python-version"

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
        Export-LogError "Checking .python-version file: $pythonVersionFile"
        if (Test-Path $pythonVersionFile) {
            $envName = (Get-Content $pythonVersionFile)
            Export-LogError -m "init: env: $envName"
            Export-LogError -m "Dir: $appEnvDir\$envName exists: $(Test-Path -PathType Container $appEnvDir\$envName)"
            if ($envName -and (Test-Path -PathType Container "$appEnvDir\$envName")) {
                if ($invokeShell -eq "ps1") { & "$appEnvDir\$envName\Scripts\Activate.ps1" }
                else { cmd /k "$appEnvDir\$envName\Scripts\activate.bat" }
            }
        }
        else {
            Write-Error "$pythonVersionFile not found!"
        }
    }

    if ($subcommand1 -eq "activate") {
        if (!$subcommand2) { Invoke-HelpActivate; exit }
        if (Test-Path -PathType Container "$appEnvDir\$subcommand2") {
            if ($invokedShell -eq "ps1") {
                $Env:PYENV_VENV_ACTIVE = $subcommand2
                & "$appEnvDir\$subcommand2\Scripts\Activate.ps1"
            }
            else {
                cmd /k "$appEnvDir\$subcommand2\Scripts\activate.bat"
            }
        }
        else { Write-Warning "Env: $subcommand2 is not installed. Please install by using `"pyenv-venv install <python_version> $subcommand2"`" }
    }

    if ($subcommand1 -eq "deactivate") {
        if ($env:VIRTUAL_ENV) {
            $env:PYENV_VENV_ACTIVE = ""
            if ($invokedShell -eq "ps1") { deactivate }
            else { cmd /k deactivate }
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
                    & pyenv shell $subcommand2
                    & python -m venv "$appEnvDir\$subcommand3"

                    # Reactivate the python env if any
                    if ($PYENV_VENV_ACTIVE) {
                        pyenv-venv activate $PYENV_VENV_ACTIVE
                    }
                }
                else { Write-Warning "`"$subcommand3`" already exists. Please choose another name for the env." }
            }
            else { Write-Warning "Cannot create an env called `"self`" since while uninstalling `pyenv-venv uninstall self` is already a pre-existing command." }
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
            elseif (Test-Path -PathType Container "$appEnvDir\$subcommand2") {
                Write-Host "Uninstalling env:" -NoNewline 
                Write-Host " $subcommand2 " -NoNewline -ForegroundColor "Yellow"
                Remove-Item -Recurse -Force "$appEnvDir\$subcommand2"
            }
            else { Write-Warning "$subcommand2 is not installed so it cannot be uninstalled." }
        }
    }

    if ($subcommand1 -eq "list") {
        if (!$subcommand2) { Invoke-HelpList; exit }
        if ($subcommand2 -eq "envs") { FetchEnvs }
        if ($subcommand2 -eq "python") { FetchPythonVersions }
    }

    if ($subcommand1 -eq "config") { ConfigInfo }

    if ($subcommand1 -eq "update") {
        if ($subcommand2 -eq "self") {
            # Check if the CLI was installed using Git
        (git -C $appDir rev-parse) *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "CLI installed using Git"
            (git -C  $appDir fetch origin) *> $null
                Write-Host "Changelog:" -ForegroundColor Blue
                git -C $appDir log ..origin/main --pretty=format:"%Cblue* %C(auto)%h: %Cgreen%s%n%b"
                git -C $appDir pull origin
            }
            else {
                Write-Host "CLI installed using install script"
                # TODO: Update script for fork version of install-pyenv-win-venv.ps1 script
                # Write-Host "Downloading & running install-pyenv-win-venv.ps1"
                # $LastExitCode = 0 # reset the exit code after the git command
                # # Download and run the installation script
                # Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win-venv/main/bin/install-pyenv-win-venv.ps1" -OutFile "$HOME\install-pyenv-win-venv.ps1";
                # &"$HOME\install-pyenv-win-venv.ps1"
            }
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
        Write-Output = "$timeStamp  $Message" | Out-File -Path $FilePath -Append
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
    Write-Host "Python Versions installed:" -ForegroundColor "Green"
    Write-Host "--------------------------" -ForegroundColor "Green"
    pyenv versions
}

function FetchEnvs {
    Write-Host "Envs installed:" -ForegroundColor "Green"
    Write-Host "---------------" -ForegroundColor "Green"
    (Get-ChildItem -Directory $app_env_dir | Select-Object -Expand Name)
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
    
Example: `pyenv-venv install 3.8.5 test_env`
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
debug               To show debug log
"
}
Main