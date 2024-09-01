@echo off
setlocal

cd /d "%~dp0"
net sess>nul 2>&1||(echo(CreateObject("Shell.Application"^).ShellExecute"%~0",,,"RunAs",1:CreateObject("Scripting.FileSystemObject"^).DeleteFile(wsh.ScriptFullName^)>"%temp%\%~nx0.vbs"&start wscript.exe "%temp%\%~nx0.vbs"&exit)

set "REQUIREMENTS_FILE=requirements.txt"
set "PYTHON_EXE=python"

if exist "%SystemRoot%\System32\python.exe" set "PYTHON_EXE=%SystemRoot%\System32\python.exe"
if exist "%SystemRoot%\System32\py.exe" set "PYTHON_EXE=%SystemRoot%\System32\py.exe"

%PYTHON_EXE% --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed. Installing Python %TARGET_VERSION%...
    goto Update
)

for /f "tokens=2 delims= " %%a in ('"%PYTHON_EXE% --version" 2^>nul') do set PY_VER=%%a
for /f "tokens=1,2,3 delims=." %%a in ("%PY_VER%") do (
    set MAJOR_VER=%%a
    set MINOR_VER=%%b
    set PATCH_VER=%%c
)

set "TARGET_VERSION=3.12.5"
for /f "tokens=1,2,3 delims=." %%a in ("%TARGET_VERSION%") do (
    set TARGET_MAJOR=%%a
    set TARGET_MINOR=%%b
    set TARGET_PATCH=%%c
)

if %MAJOR_VER% GTR %TARGET_MAJOR% (
    echo Python version is newer than the target. Installing packages...
    timeout /t 5 /nobreak >nul
    goto InstallPackages
) else if %MAJOR_VER% LSS %TARGET_MAJOR% (
    echo Python version is older than the target. Updating to %TARGET_VERSION%...
    goto Update
) else (
    if %MINOR_VER% GTR %TARGET_MINOR% (
        echo Python version is newer than the target. Installing packages...
        timeout /t 5 /nobreak >nul
        goto InstallPackages
    ) else if %MINOR_VER% LSS %TARGET_MINOR% (
        echo Python version is older than the target. Updating to %TARGET_VERSION%...
        goto Update
    ) else (
        if %PATCH_VER% GEQ %TARGET_PATCH% (
            echo Python version is already up-to-date. Installing packages...
            timeout /t 5 /nobreak >nul
            goto InstallPackages
        ) else (
            echo Python version is older than the target. Updating to %TARGET_VERSION%...
            goto Update
        )
    )
)

:Update
echo Downloading Python 3.12.5 installer...
powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.12.5/python-3.12.5-amd64.exe -OutFile \"%~dp0python_installer.exe\" -UseBasicParsing"
powershell -Command "while (!(Test-Path \"%~dp0python_installer.exe\")) { Start-Sleep -Milliseconds 100 }"

echo Installing Python 3.12.5...
"%~dp0python_installer.exe" /quiet PrependPath=1

if %errorlevel% neq 0 (
    echo Installation failed with error code %errorlevel%.
    pause
    exit /b %errorlevel%
)

del "%~dp0python_installer.exe"

echo Python has been installed. Installing packages...
timeout /t 5 /nobreak >nul
goto InstallPackages

:InstallPackages
set "VENV_DIR=%appdata%\Python\Python312\Atria"

if not exist "%VENV_DIR%" python -m venv "%VENV_DIR%"
call "%VENV_DIR%\Scripts\activate.bat"

python -m pip install --upgrade pip
pip install -r requirements.txt
call "%VENV_DIR%\Scripts\deactivate.bat"

endlocal
echo,
echo Finished installing packages.
timeout /t 2 /nobreak >nul
goto RunAtria

:RunAtria
set "LOGFILE=%temp%\output.log"

echo,
echo Running Atria.py...
timeout /t 2 /nobreak >nul

copy "%~dp0Atria.py" "%userprofile%\Desktop\Atria\"
echo Atria.py has been copied to %userprofile%\Downloads\Atria

timeout /t 2 /nobreak >nul
cd /d "%userprofile%\Desktop\Atria\"
if exist "Scripts\Activate" call "Scripts\Activate"

python Atria.py > "%LOGFILE%" 2>&1
echo,
echo Log output:
type "%LOGFILE%"

echo Press any key to delete the log file and exit...
pause >nul

del "%LOGFILE%"
exit /b