@echo off
REM Admin-Check
net session >nul 2>&1
if %errorlevel% neq 0 (
   echo Bitte als Administrator starten!
   pause
   exit
)

title System TuneUp by Felixplored v. 1.14

REM Windows Datenträgerbereinigung
echo Ersteinrichtung: Bitte ALLE Haken setzen und mit: "OK" bestaetigen.
set auswahl=
set /p auswahl="Moechten Sie die Ersteinrichtung ausfuehren? (y/n)"
if "%auswahl%" == "y" goto ja
if "%auswahl%" == "n" goto nein
:ja
cleanmgr /sageset:1
:nein
cleanmgr /sagerun:1

REM Speicheroptimierung (Storage Sense) & Analyse des Component Store
cls
echo Bestaetige mit: "Ja", Klicke auf: Temporaere Dateien -^> ALLE Haken setzen -^> Dateien entfernen -^> Weiter
pause
start ms-settings:storagesense
dism /Online /Cleanup-Image /AnalyzeComponentStore
echo Bereinigung fortsetzen^?
pause

REM Bereinigung des Component Store
dism /Online /Cleanup-Image /StartComponentCleanup
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /Online /Cleanup-Image /SPSuperseded

REM Deaktivierung des Features: "Recall"
dism /Online /Disable-Feature /Featurename:Recall

REM DNS Cache leeren
ipconfig /flushdns

REM Dateisystemfehler prüfen & Defragmentierung von Laufwerk C: durchführen
chkdsk C: /f
defrag C: /h /u

REM Microsoft Store Cache leeren & Programm schließen
wsreset
taskkill /IM WinStore.App.exe /f /t

REM Systemwiederherstellungspunkte Löschen & Systemwiederherstellung Deaktivieren für Laufwerk C:
vssadmin delete shadows /all /quiet
wmic /namespace:\\root\default path SystemRestore call Disable C:\

REM Versteckte Windows Ordner Löschen
rd C:\$GetCurrent /q /s
rd C:\$SysReset /q /s
rd C:\$Windows.~BT /q /s
rd C:\$Windows.~WS /q /s
rd C:\$WinREAgent /q /s
rd C:\Config.Msi /q /s
rd C:\Recovery /q /s
rd C:\Windows.old /q /s

REM Perflogs Ordner leeren
del C:\PerfLogs /f /q /s
for /d %%a in ("C:\PerfLogs\*.*") do rd /q /s "%%a"

REM AMD Cache leeren
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

REM NVIDIA Cache leeren
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

REM D3DS Cache leeren
del %localappdata%\D3DSCache /f /q /s
for /d %%a in ("%localappdata%\D3DSCache\*.*") do rd /q /s "%%a"

REM Thumbnail Cache leeren
del %localappdata%\Microsoft\Windows\Explorer /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Explorer\*.*") do rd /q /s "%%a"

REM Weitere Windows Caches leeren
del %localappdata%\Microsoft\Windows\Caches /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Caches\*.*") do rd /q /s "%%a"

REM Windows Temp, Logs & Prefetch leeren
del %temp% /f /q /s
for /d %%a in ("%temp%\*.*") do rd /q /s "%%a"
del %localappdata%\SquirrelTemp /f /q /s
for /d %%a in ("%localappdata%\SquirrelTemp\*.*") do rd /q /s "%%a"
del %localappdata%low\Temp /f /q /s
for /d %%a in ("%localappdata%low\Temp\*.*") do rd /q /s "%%a"
del C:\Windows\Logs /f /q /s
for /d %%a in ("C:\Windows\Logs\*.*") do rd /q /s "%%a"
del C:\Windows\Temp /f /q /s
for /d %%a in ("C:\Windows\Temp\*.*") do rd /q /s "%%a"
del C:\Windows\SystemTemp /f /q /s
for /d %%a in ("C:\Windows\SystemTemp\*.*") do rd /q /s "%%a"
del C:\Windows\Prefetch /f /q /s
for /d %%a in ("C:\Windows\Prefetch\*.*") do rd /q /s "%%a"
del C:\Windows\SoftwareDistribution\Download /f /q /s
for /d %%a in ("C:\Windows\SoftwareDistribution\Download\*.*") do rd /q /s "%%a"

REM Neustart Abfrage
cls
echo Bereinigung beendet! Ein Neustart wird zwingend empfohlen.
set auswahl=
set /p auswahl="Moechten Sie das System Neustarten? (y/n)"
if "%auswahl%" == "y" goto ja
if "%auswahl%" == "n" goto nein
:ja
shutdown /r /t 60
:nein
exit