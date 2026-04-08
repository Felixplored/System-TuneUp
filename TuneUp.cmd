@echo off
title System TuneUp by Felixplored v. 2.0
color 06
chcp 1252 >nul

REM Admin-Check
net session >nul 2>&1
if %errorlevel% neq 0 (
   echo Bitte als Administrator starten!
   pause
   exit
)

REM Auswahl-Menü
:menu
cls
echo ======================================
echo ^|    System TuneUp by Felixplored    ^|          
echo ======================================
echo  1 - Ersteinrichtung                 =
echo  2 - PC Reparieren                   =
echo  3 - PC Bereinigen                   =
echo  4 - PC Neustarten (empfohlen)       =
echo  5 - README öffnen                   =
echo  0 - Programm schließen              =
echo ======================================
set auswahl=
set /p auswahl="Auswahl:"
if "%auswahl%" == "1" goto config
if "%auswahl%" == "2" goto repair
if "%auswahl%" == "3" goto clean
if "%auswahl%" == "4" goto restart
if "%auswahl%" == "5" goto readme
if "%auswahl%" == "0" goto exit
goto menu

REM Readme öffnen
:readme
cls
mode con: cols=160 lines=60
more "%~dp0README.txt"
pause
mode con: cols=120 lines=30
goto menu

REM Neustart durchführen
:restart
:: Der Computer wird in einer Minute neu gestartet
shutdown /r /t 60
exit

REM Reparatur durchführen
:repair
:: Reparatur des Component Store
cls
dism /Online /Cleanup-Image /RestoreHealth
:: System File Checker ausführen
cls
sfc /scannow
:: Dateisystemfehler überprüfen
cls
chkdsk C: /f
echo msgbox "Reparatur beendet! Ein Neustart wird empfohlen.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
goto menu

REM Windows Datenträgerbereinigung
:config
:: Setzen der Bereinigungspunkte
echo msgbox "Bitte ALLE Haken setzen und mit OK bestätigen.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
cleanmgr /sageset:1
goto menu
:clean
:: Start der Bereinigunspunkte
cleanmgr /sagerun:1

REM Speicheroptimierung (Storage Sense)
echo msgbox "Bestätige im Anschluss mit Ja",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
start ms-settings:storagesense
echo msgbox "Klicke auf Temporäre Dateien -> ALLE Haken setzen -> Dateien entfernen -> Weiter. Schließe im Anschluss das Fenster.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs

REM Defragmentierung durchführen für Laufwerk C:
cls
defrag C: /h /u

REM Bereinigung des Component Store
cls
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

REM Deaktivierung des Features: "Recall"
cls
dism /Online /Disable-Feature /Featurename:Recall

REM Systemwiederherstellungspunkte löschen & Systemwiederherstellung deaktivieren für Laufwerk C:
cls
echo [==                        5.0%%                            ]
(
vssadmin delete shadows /all /quiet
wmic /namespace:\\root\default path SystemRestore call Disable C:\
) >nul 2>&1

REM Schnellstart & Ruhezustand deaktivieren
cls
echo [=====                     10.0%%                           ]
(
powercfg -h off
) >nul 2>&1

REM DNS Cache leeren
cls
echo [========                  15.0%%                           ]
(
ipconfig /flushdns
) >nul 2>&1

REM Microsoft Store Cache leeren & Programm schließen
cls
echo [==========                20.0%%                           ]
(
wsreset
taskkill /IM WinStore.App.exe /f /t
) >nul 2>&1

REM Windows Event Logs leeren
cls
echo [=============             25.0%%                           ]
(
for /F "tokens=*" %%1 in ('wevtutil.exe el') DO wevtutil.exe cl "%%1"
) >nul 2>&1

REM Versteckte Windows Ordner löschen
cls
echo [================          30.0%%                           ]
(
rd C:\$GetCurrent /q /s
rd C:\$SysReset /q /s
rd C:\$Windows.~BT /q /s
rd C:\$Windows.~WS /q /s
rd C:\$WinREAgent /q /s
rd C:\Config.Msi /q /s
rd C:\Recovery /q /s
rd C:\Windows.old /q /s
) >nul 2>&1

REM Perflogs Ordner leeren
cls
echo [==================        35.0%%                           ]
(
del C:\PerfLogs /f /q /s
for /d %%a in ("C:\PerfLogs\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM AMD Cache leeren
cls
echo [=====================     40.0%%                           ]
(
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
) >nul 2>&1

REM NVIDIA Cache leeren
cls
echo [=======================   45.0%%                           ]
(
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
) >nul 2>&1

REM D3DS Cache leeren
cls
echo [==========================50.0%%                           ]
(
del %localappdata%\D3DSCache /f /q /s
for /d %%a in ("%localappdata%\D3DSCache\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Qt Shader Cache leeren
cls
echo [==========================55.0%%==                         ]
(
del %localappdata%\cache /f /q /s
for /d %%a in ("%localappdata%\cache\*.*") do rd /q /s "%%a"
del %localappdata%\fontconfig /f /q /s
for /d %%a in ("%localappdata%\fontconfig\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Task Scheduler Cache leeren
cls
echo [==========================60.0%%=====                      ]
(
del C:\Windows\SchCache /f /q /s
for /d %%a in ("C:\Windows\SchCache\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Windows Temps leeren
cls
echo [==========================65.0%%========                   ]
(
del %temp% /f /q /s
for /d %%a in ("%temp%\*.*") do rd /q /s "%%a"
del %localappdata%\SquirrelTemp /f /q /s
for /d %%a in ("%localappdata%\SquirrelTemp\*.*") do rd /q /s "%%a"
del %localappdata%low\Temp /f /q /s
for /d %%a in ("%localappdata%low\Temp\*.*") do rd /q /s "%%a"
del C:\Windows\Temp /f /q /s
for /d %%a in ("C:\Windows\Temp\*.*") do rd /q /s "%%a"
del C:\Windows\SystemTemp /f /q /s
for /d %%a in ("C:\Windows\SystemTemp\*.*") do rd /q /s "%%a"
del C:\Windows\CbsTemp /f /q /s
for /d %%a in ("C:\Windows\CbsTemp\*.*") do rd /q /s "%%a"
del C:\Windows\SoftwareDistribution\Download /f /q /s
for /d %%a in ("C:\Windows\SoftwareDistribution\Download\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Windows CrashDumps leeren
cls
echo [==========================70.0%%==========                 ]
(
del %localappdata%\CrashDumps /f /q /s
for /d %%a in ("%localappdata%\CrashDumps\*.*") do rd /q /s "%%a"
del C:\ProgramData\Microsoft\Windows\WER /f /q /s
for /d %%a in ("C:\ProgramData\Microsoft\Windows\WER\*.*") do rd /q /s "%%a"
del C:\Windows\LiveKernelReports /f /q /s
for /d %%a in ("C:\Windows\LiveKernelReports\*.*") do rd /q /s "%%a"
del C:\Windows\Minidump /f /q /s
for /d %%a in ("C:\Windows\Minidump\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Windows Logs leeren
cls
echo [==========================75.0%%=============              ]
(
del C:\Windows\Logs /f /q /s
for /d %%a in ("C:\Windows\Logs\*.*") do rd /q /s "%%a"
del C:\Windows\debug /f /q /s
for /d %%a in ("C:\Windows\debug\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Windows Prefetch leeren
cls
echo [==========================80.0%%================           ]
(
del C:\Windows\Prefetch /f /q /s
for /d %%a in ("C:\Windows\Prefetch\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Explorer beenden
taskkill /f /im explorer.exe >nul 2>&1
:check
:: Prüfen ob beendet
tasklist | find /i "explorer.exe" >nul
if not errorlevel 1 (
   timeout /t 1 >nul
   goto check
)

REM Icon Cache leeren
cls
echo [==========================85.0%%==================         ]
(
del %localappdata%\IconCache.db /a /f /q
) >nul 2>&1

REM Thumbnail Cache leeren
cls
echo [==========================90.0%%=====================      ]
(
del %localappdata%\Microsoft\Windows\Explorer /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Explorer\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Weitere Windows Caches leeren
cls
echo [==========================95.0%%=======================    ]
(
del %localappdata%\Microsoft\Windows\Caches /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Caches\*.*") do rd /q /s "%%a"
del C:\ProgramData\Microsoft\Windows\Caches /f /q /s
for /d %%a in ("C:\ProgramData\Microsoft\Windows\Caches\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Explorer starten
cls
echo [==========================100.0%%==========================]
start explorer.exe
echo msgbox "Bereinigung beendet! Ein Neustart wird empfohlen.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
goto menu