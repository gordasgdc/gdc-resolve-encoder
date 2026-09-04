@echo off
REM GDC Resolve Encoder — dublu-click aici sa instalezi plugin-ul automat.
REM Doar cheama install.ps1 cu politica de executie corecta, ca userul sa
REM nu trebuiasca sa dea click-dreapta -> "Run with PowerShell" manual.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
