@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.17
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

echo HERE WE GO INSTALLING WITH MY OWN PYTHON VERSION !!

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)
goto Deployment

:: Utility Functions
:: -----------------

:SelectPythonVersion

  SET PYTHON_RUNTIME=python-3.6
  SET PYTHON_VER=3.6
  SET PYTHON_EXE=%SYSTEMDRIVE%\home\python364x64\python.exe
  SET PYTHON_ENV_MODULE=venv
goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

:Deployment
echo Handling python deployment.

:: 1. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

IF NOT EXIST "%DEPLOYMENT_TARGET%\requirements.txt" goto postPython
IF EXIST "%DEPLOYMENT_TARGET%\.skipPythonDeployment" goto postPython

echo Detected requirements.txt.  You can skip Python specific steps with a .skipPythonDeployment file.

:: 2. Select Python version
call :SelectPythonVersion

pushd "%DEPLOYMENT_TARGET%"

echo Python install Wheels
%PYTHON_EXE% -m pip install --upgrade pip
%PYTHON_EXE% -m pip install wheel

echo Python  Wheels install wheelhouse repository
%PYTHON_EXE% -m pip wheel -r %DEPLOYMENT_TARGET%\requirements.txt -w wheelhouse

echo Python install requirements.
%PYTHON_EXE% -m pip install --upgrade -r %DEPLOYMENT_TARGET%\requirements.txt

IF !ERRORLEVEL! NEQ 0 goto error

REM Add additional package installation here
REM -- Example --
REM env\scripts\easy_install pytz
REM IF !ERRORLEVEL! NEQ 0 goto error

:: 5. Copy web.config
IF EXIST "%DEPLOYMENT_SOURCE%\web.%PYTHON_VER%.config" (
  echo Overwriting web.config with web.%PYTHON_VER%.config
  copy /y "%DEPLOYMENT_SOURCE%\web.%PYTHON_VER%.config" "%DEPLOYMENT_TARGET%\web.config"
)

:: 6. Django collectstatic
IF EXIST "%DEPLOYMENT_TARGET%\manage.py" (
  IF EXIST "%DEPLOYMENT_TARGET%\env\lib\site-packages\django" (
    IF NOT EXIST "%DEPLOYMENT_TARGET%\.skipDjango" (
      echo Collecting Django static files. You can skip Django specific steps with a .skipDjango file.
      IF NOT EXIST "%DEPLOYMENT_TARGET%\static" (
        MKDIR "%DEPLOYMENT_TARGET%\static"
      )
      env\scripts\python manage.py collectstatic --noinput --clear
    )
  )
)

popd

:postPython

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
