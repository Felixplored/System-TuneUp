@echo off
title System TuneUp by Felixplored v. 1.1
echo on
rem Bitte ALLE Haken setzen und mit: "OK" bestaetigen.
@echo off
cleanmgr /sageset
cleanmgr /sagerun
dism /Online /Cleanup-Image /AnalyzeComponentStore
echo on
rem Bereinigung fortsetzen?
@echo off
pause
dism /Online /Cleanup-Image /StartComponentCleanup
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /Online /Cleanup-Image /spsuperseded
ipconfig /flushdns
defrag C: /u
chkdsk
wsreset
taskkill /IM WinStore.App.exe /f /t
vssadmin delete shadows /all /quiet
wmic /namespace:\\root\default path SystemRestore call Disable C:\
del %localappdata%\NVIDIA\GLCache /f /q /s
for /d %%a in ("%localappdata%\NVIDIA\GLCache\*.*") do rd /q /s "%%a"
del %localappdata%\NVIDIA\OptixCache /f /q /s
for /d %%a in ("%localappdata%\NVIDIA\OptixCache\*.*") do rd /q /s "%%a"
del %localappdata%low\NVIDIA\PerDriverVersion\DXCache /f /q /s
for /d %%a in ("%localappdata%low\NVIDIA\PerDriverVersion\DXCache\*.*") do rd /q /s "%%a"
del %appdata%\NVIDIA\ComputeCache /f /q /s
for /d %%a in ("%appdata%\NVIDIA\ComputeCache\*.*") do rd /q /s "%%a"
del %temp% /f /q /s
for /d %%a in ("%temp%\*.*") do rd /q /s "%%a"
del C:\Windows\Temp /f /q /s
for /d %%a in ("C:\Windows\Temp\*.*") do rd /q /s "%%a"
del C:\Windows\SystemTemp /f /q /s
for /d %%a in ("C:\Windows\SystemTemp\*.*") do rd /q /s "%%a"
del C:\Windows\Prefetch /f /q /s
for /d %%a in ("C:\Windows\Prefetch\*.*") do rd /q /s "%%a"
del C:\Windows\SoftwareDistribution\Download /f /q /s
for /d %%a in ("C:\Windows\SoftwareDistribution\Download\*.*") do rd /q /s "%%a"
echo on
rem Bereinigung beendet! Ein Neustart wird zwingend Empfohlen.
@echo off
set auswahl=
set /p auswahl="Moechten Sie das System Neustarten? (y/n)"
if "%auswahl%" == "y" goto ja
if "%auswahl%" == "n" goto nein
:ja
shutdown /r
:nein
exit


