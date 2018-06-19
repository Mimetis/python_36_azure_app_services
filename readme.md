# Deploying Web App, last Python Version (3.6.4) with Azure App Services Extensions

## TL;DR;

- Add a web app in AZURE
- Clone this repository (it contains everything you need)
- Add python 3.6.4 through the extensions
- Deploy

## Explanations

Replacing the default **kudu** deployment model, using `web.config` `python.cmd` and `.deployment`:

- `web.config` points to correct python version to handle every http requests.
- `.deployment` points to the correct cmd
- `python.cmd` replace default `kudu` commands. this script use the correct version of python, installed through app services extensions

To handle complex packages, who require compilation, since app services can't do it, we are using the wheel packages.

- The `requirements.txt` points to a `wheelhouse` folder.
- The `wheelhouse` folder is populated with correct wheel packages.
- The `python.cmd` will download the packages, then will install them

```cmd
echo Python install Wheels
%PYTHON_EXE% -m pip install --upgrade pip
%PYTHON_EXE% -m pip install wheel

echo Python  Wheels install wheelhouse repository
%PYTHON_EXE% -m pip wheel -r %DEPLOYMENT_TARGET%\requirements.txt -w wheelhouse

echo Python install requirements.
%PYTHON_EXE% -m pip install --upgrade -r %DEPLOYMENT_TARGET%\requirements.txt
```

