<h1 align="center">pyenv-win-venv</h1>

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/arzkar)

A CLI to manage virtual envs with pyenv-win<br>
To report issues for the CLI, open an issue at <https://github.com/pyenv-win/pyenv-win-venv/issues>

# Installation

## Dependencies

This script depends on the [pyenv-win](https://github.com/pyenv-win/pyenv-win) so it needs to be installed system to run this script.

## Power Shell

```pwsh
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/jacquindev/pyenv-win-venv/refs/heads/main/bin/install-pyenv-win-venv.ps1" -OutFile "$HOME\install-pyenv-win-venv.ps1";
& "$HOME\install-pyenv-win-venv.ps1"
```

**Note:** Skip the [Add System Settings](#add-system-settings) Section

## Git

```bash
git clone https://github.com/jacquindev/pyenv-win-venv.git "$HOME\.pyenv-win-venv"

# Or using SSH
git clone git@github.com:jacquindev/pyenv-win-venv.git "$HOME\.pyenv-win-venv"
```

You need to add the `\bin` path to your environment variables using the following steps.

### Add System Settings

Adding the following paths to your USER PATH variable in order to access the pyenv-win-venv command

```pwsh
[System.Environment]::SetEnvironmentVariable('path', $env:USERPROFILE + "\.pyenv-win-venv\bin;"  + [System.Environment]::GetEnvironmentVariable('path', "User"),"User")
```

# Update

Automatically using `pyenv-venv update self` (Recommended)

## Git (If the CLI was installed using Git)

Using `git pull`:

Go to `%USERPROFILE%\.pyenv-win-venv` (which is your installed path) and run `git pull`

## Power Shell (If the CLI was installed using the PowerScript Installation Script)

```pwsh
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/jacquindev/pyenv-win-venv/refs/heads/main/bin/install-pyenv-win-venv.ps1" -OutFile "$HOME\install-pyenv-win-venv.ps1";
& "$HOME\install-pyenv-win-venv.ps1"
```

# Uninstallation

## CLI

```cmd
pyenv-venv uninstall self
```

## PowerShell

```pwsh
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/jacquindev/pyenv-win-venv/refs/heads/main/bin/install-pyenv-win-venv.ps1" -OutFile "$HOME\install-pyenv-win-venv.ps1";
&"$HOME\install-pyenv-win-venv.ps1" -Uninstall
```

# Usage

```cmd
> pyenv-win-venv
    pyenv-win-venv v0.6
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
```

**Note:** `pyenv-venv` is an alias for `pyenv-win-venv` so either one can be used to call the CLI.

# Example

- To install an env using Python v3.8.5 (should be already installed in the system using `pyenv install 3.8.5`)

```cmd
pyenv-venv install 3.8.5 env_name
```

- To uninstall an env

```cmd
pyenv-venv uninstall env_name
```

- To activate an env

```cmd
pyenv-venv activate env_name
```

- To deactivate an env

```cmd
pyenv-venv deactivate
```

- To list all installed envs

```cmd
pyenv-venv list envs
```

- To list all installed python versions

```cmd
pyenv-venv list python
```

- To set an env to the `.python-version` file

```cmd
pyenv-venv local env_name
```

- To show the app directory

```cmd
pyenv-venv config
```

- To update the CLI to the latest version

```cmd
pyenv-venv update self
```

- To show the full path to the executable

```cmd
pyenv-venv which <exec_name>
```

- To get help for each command

```cmd
pyenv-venv help install
```

# Note

## Env automatic activation using `.python-version` file

- You can set the env for a directory using a `.python-version`
  file and the CLI can automatically activate the env if a shell is
  opened in that directory.

- `.python-version` file: It should only contain the name of the env and can be created by manually or by using the command: `pyenv-venv local env_name`

- You can manually activate the env if the directory has a `.python-version` file by calling `pyenv-venv init`

- To enable the automatic feature, you need to add `pyenv-venv init` to your the PowerShell Profile.
  Steps to do this:

  - First check if you already have a powershell profile.

    ```pwsh
    Test-Path $profile
    ```

    If its `False`, then you need to create a new profile.

  - Create a new profile using:

    ```pwsh
    New-Item -path $profile -type file –force
    ```

    The location to the profile will be shown on the shell.

  - Open the `profile.ps1` file and append the following line.

    ```cmd
    pyenv-venv init
    ```

    Save and restart the shell.

**Note:** If you want the CLI to search for a `.python-version` file by traversing from the current working directory to the root till it finds the file, use `pyenv-venv init root`
