@echo off
title System TuneUp by Felixplored v. 1.10
echo on
rem Ersteinrichtung: Bitte ALLE Haken setzen und mit: "OK" bestaetigen.
@echo off
set auswahl=
set /p auswahl="Moechten Sie die Ersteinrichtung ausfuehren? (y/n)"
if "%auswahl%" == "y" goto ja
if "%auswahl%" == "n" goto nein
:ja
cleanmgr /sageset:1
:nein
cleanmgr /sagerun:1
dism /Online /Cleanup-Image /AnalyzeComponentStore
echo on
rem Bereinigung fortsetzen?
@echo off
pause
dism /Online /Cleanup-Image /StartComponentCleanup
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /Online /Cleanup-Image /SPSuperseded
dism /Online /Disable-Feature /Featurename:Recall
ipconfig /flushdns
chkdsk
defrag C: /h /u
wsreset
taskkill /IM WinStore.App.exe /f /t
vssadmin delete shadows /all /quiet
wmic /namespace:\\root\default path SystemRestore call Disable C:\
rd C:\$GetCurrent /q /s
rd C:\$SysReset /q /s
rd C:\$Windows.~BT /q /s
rd C:\$Windows.~WS /q /s
rd C:\$WinREAgent /q /s
rd C:\Config.Msi /q /s
rd C:\Recovery /q /s
rd C:\Windows.old /q /s
del C:\PerfLogs /f /q /s
for /d %%a in ("C:\PerfLogs\*.*") do rd /q /s "%%a"
del C:\.cache\AMD\DX9Cache /f /q /s
for /d %%a in ("C:\.cache\AMD\DX9Cache\*.*") do rd /q /s "%%a"
del %localappdata%\AMD\DX9Cache /f /q /s
for /d %%a in ("%localappdata%\AMD\DX9Cache\*.*") do rd /q /s "%%a"
del %localappdata%\AMD\DxCache /f /q /s
for /d %%a in ("%localappdata%\AMD\DxCache\*.*") do rd /q /s "%%a"
del %localappdata%\AMD\DxcCache /f /q /s
for /d %%a in ("%localappdata%\AMD\DxcCache\*.*") do rd /q /s "%%a"
del %localappdata%\AMD\OglCache /f /q /s
for /d %%a in ("%localappdata%\AMD\OglCache\*.*") do rd /q /s "%%a"
del %localappdata%\AMD\VkCache /f /q /s
for /d %%a in ("%localappdata%\AMD\VkCache\*.*") do rd /q /s "%%a"
del %localappdata%low\AMD\DxCache /f /q /s
for /d %%a in ("%localappdata%low\AMD\DxCache\*.*") do rd /q /s "%%a"
del %localappdata%low\AMD\DxcCache /f /q /s
for /d %%a in ("%localappdata%low\AMD\DxcCache\*.*") do rd /q /s "%%a"
del %localappdata%\NVIDIA\DXCache /f /q /s
for /d %%a in ("%localappdata%\NVIDIA\DXCache\*.*") do rd /q /s "%%a"
del %localappdata%\NVIDIA\GLCache /f /q /s
for /d %%a in ("%localappdata%\NVIDIA\GLCache\*.*") do rd /q /s "%%a"
del %localappdata%\NVIDIA\OptixCache /f /q /s
for /d %%a in ("%localappdata%\NVIDIA\OptixCache\*.*") do rd /q /s "%%a"
del %localappdata%low\NVIDIA\DXCache /f /q /s
for /d %%a in ("%localappdata%low\NVIDIA\DXCache\*.*") do rd /q /s "%%a"
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
rem Bereinigung beendet! Ein Neustart wird zwingend empfohlen.
@echo off
set auswahl=
set /p auswahl="Moechten Sie das System Neustarten? (y/n)"
if "%auswahl%" == "y" goto ja
if "%auswahl%" == "n" goto nein
:ja
shutdown /r /t 60
:nein
exit