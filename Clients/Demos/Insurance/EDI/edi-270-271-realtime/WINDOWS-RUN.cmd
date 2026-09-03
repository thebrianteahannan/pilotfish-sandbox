@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set ARCH=
for /f %%i in ('docker image inspect pilotfish-eip:23R1 --format "{{.Architecture}}" 2^>nul') do set ARCH=%%i
if /i "!ARCH!"=="amd64" goto have_image

echo Loading linux/amd64 EIP image (replaces an Apple Silicon 23R1 if present)...
docker rmi -f pilotfish-eip:23R1 >nul 2>&1

if exist "pilotfish-eip-23R1-amd64.tar.gz" (
  docker load -i "pilotfish-eip-23R1-amd64.tar.gz"
  if not errorlevel 1 goto after_load
)

if not exist "edi-270-271-realtime-windows.zip" (
  echo Missing edi-270-271-realtime-windows.zip in this folder.
  pause
  exit /b 1
)

echo Reading image from edi-270-271-realtime-windows.zip ...
copy /y "edi-270-271-realtime-windows.zip" "%TEMP%\pf-eip-23R1-amd64.tar.gz" >nul
docker load -i "%TEMP%\pf-eip-23R1-amd64.tar.gz" >nul 2>&1
if not errorlevel 1 goto after_load

set UNPACK=%TEMP%\pf-edi270-unpack
rmdir /s /q "%UNPACK%" 2>nul
mkdir "%UNPACK%"
tar -xf "edi-270-271-realtime-windows.zip" -C "%UNPACK%"
if errorlevel 1 (
  echo Could not open edi-270-271-realtime-windows.zip
  pause
  exit /b 1
)

for /r "%UNPACK%" %%F in (*.tar.gz) do (
  docker load -i "%%F"
  if not errorlevel 1 goto after_load
)
for /r "%UNPACK%" %%F in (*.zip) do (
  copy /y "%%F" "%TEMP%\pf-eip-23R1-amd64.tar.gz" >nul
  docker load -i "%TEMP%\pf-eip-23R1-amd64.tar.gz"
  if not errorlevel 1 goto after_load
)

echo Load failed. Is Docker Desktop running in Linux-container mode?
pause
exit /b 1

:after_load
docker tag pilotfish-eip:23R1-amd64 pilotfish-eip:23R1

:have_image
echo Using the local pilotfish-eip:23R1 image (BuildKit off so Docker Hub is not queried).
set DOCKER_BUILDKIT=0
set COMPOSE_DOCKER_CLI_BUILD=0
docker compose --profile full up -d --build
if errorlevel 1 (
  echo Compose failed.
  pause
  exit /b 1
)
echo Open http://127.0.0.1:8121/
echo Status: docker compose --profile full ps
pause
