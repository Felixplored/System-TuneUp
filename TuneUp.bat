@echo off
title System TuneUp by Felixplored v. 1.0
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
defrag C:
chkdsk
wsreset
taskkill /IM WinStore.App.exe /f /t
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
rem Bereinigung beendet!
@echo off
pause

