@echo off
chcp 65001 >nul
color 06
title System TuneUp by Felixplored v2.3.0

REM Admin-Check
net session >nul 2>&1
if %errorlevel% neq 0 (
   echo Please run as administrator!
   pause
   exit
)

REM Menu-Selection
:menu
cls
echo ======================================
echo ^|    System TuneUp by Felixplored    ^|          
echo ======================================
echo  1 - Initial Setup                   =
echo  2 - Repair PC                       =
echo  3 - Cleanup PC                      =
echo  4 - Open README                     =
echo  0 - Exit                            =
echo ======================================
set choice=
set /p choice="Choice:"
if "%choice%" == "1" goto config
if "%choice%" == "2" goto repair
if "%choice%" == "3" goto clean
if "%choice%" == "4" goto readme
if "%choice%" == "0" goto end
goto menu

REM Exit
:end
:: Yes ~ PC restarts in one minute | No ~ Exit
echo wscript.quit msgbox("Would you like to restart the system?",4388,"System TuneUp by Felixplored") >%temp%\i.vbs
start /wait wscript %temp%\i.vbs
set res=%errorlevel%
del %temp%\i.vbs
if %res% equ 6 (shutdown /r /t 60 & exit) else (exit)

REM Open README
:readme
cls
mode con: cols=185 lines=62
more "%~dp0README.txt"
pause
mode con: cols=120 lines=30
goto menu

REM Repair PC
:repair
:: Repair Component Store
cls
dism /Online /Cleanup-Image /RestoreHealth
:: Run System File Checker
cls
sfc /scannow
:: Run Check Disk
cls
chkdsk C: /f
echo msgbox "Repair complete! A restart is recommended.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
goto menu

REM Windows Disk Cleanup
:config
:: Initial Setup: Set adjustment points
echo msgbox "Please check ALL the boxes and click OK.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
cleanmgr /sageset:1
goto menu
:clean
:: Cleanup PC: Start adjustment points
cleanmgr /sagerun:1

REM Windows Storage Sense
echo msgbox "Then confirm by selecting Yes.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
start ms-settings:storagesense
echo msgbox "Click on Temporary Files -> Check ALL boxes -> Remove Files -> Next. Then close the window.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs

REM Run Defragmentation on C:
cls
defrag C: /h /u

REM Clean Component Store
cls
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

REM Disable feature: "Recall"
cls
dism /Online /Disable-Feature /Featurename:Recall

REM Remove System Restore points & Disable System Restore on C:
cls
echo [==                        5.0%%                            ]
(
vssadmin delete shadows /all /quiet
wmic /namespace:\\root\default path SystemRestore call Disable C:\
) >nul 2>&1

REM Disable Quick Start & Hibernation
cls
echo [=====                     10.0%%                           ]
(
powercfg -h off
) >nul 2>&1

REM Clear DNS Cache
cls
echo [========                  15.0%%                           ]
(
ipconfig /flushdns
) >nul 2>&1

REM Clear Microsoft Store Cache & Exit App
cls
echo [==========                20.0%%                           ]
(
wsreset
taskkill /IM WinStore.App.exe /f /t
) >nul 2>&1

REM Clear Windows Event Logs
cls
echo [=============             25.0%%                           ]
(
for /F "tokens=*" %%1 in ('wevtutil.exe el') DO wevtutil.exe cl "%%1"
) >nul 2>&1

REM Delete hidden Windows folders
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

REM Clear Perflogs folder
cls
echo [==================        35.0%%                           ]
(
del C:\PerfLogs /f /q /s
for /d %%a in ("C:\PerfLogs\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear AMD Cache
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

REM Clear NVIDIA Cache
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

REM Clear D3DS Cache
cls
echo [==========================50.0%%                           ]
(
del %localappdata%\D3DSCache /f /q /s
for /d %%a in ("%localappdata%\D3DSCache\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear Qt Shader Cache
cls
echo [==========================55.0%%==                         ]
(
del %localappdata%\cache /f /q /s
for /d %%a in ("%localappdata%\cache\*.*") do rd /q /s "%%a"
del %localappdata%\fontconfig /f /q /s
for /d %%a in ("%localappdata%\fontconfig\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear Task Scheduler Cache
cls
echo [==========================60.0%%=====                      ]
(
del C:\Windows\SchCache /f /q /s
for /d %%a in ("C:\Windows\SchCache\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear Windows Temps
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

REM Clear Windows CrashDumps
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

REM Clear Windows Logs
cls
echo [==========================75.0%%=============              ]
(
del C:\Windows\Logs /f /q /s
for /d %%a in ("C:\Windows\Logs\*.*") do rd /q /s "%%a"
del C:\Windows\debug /f /q /s
for /d %%a in ("C:\Windows\debug\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear Windows Prefetch & Stop and disable Windows Search service
cls
echo [==========================80.0%%================           ]
(
del C:\Windows\Prefetch /f /q /s
for /d %%a in ("C:\Windows\Prefetch\*.*") do rd /q /s "%%a"
net stop WSearch
sc config WSearch start= disabled
) >nul 2>&1

REM Close Explorer
taskkill /f /im explorer.exe >nul 2>&1
:check
:: Check if finished
tasklist | find /i "explorer.exe" >nul
if not errorlevel 1 (
   timeout /t 1 >nul
   goto check
)

REM Clear Icon Cache
cls
echo [==========================85.0%%==================         ]
(
del %localappdata%\IconCache.db /a /f /q
) >nul 2>&1

REM Clear Thumbnail Cache
cls
echo [==========================90.0%%=====================      ]
(
del %localappdata%\Microsoft\Windows\Explorer /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Explorer\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Clear other Windows caches & Windows Search database
cls
echo [==========================95.0%%=======================    ]
(
del %localappdata%\Microsoft\Windows\Caches /f /q /s
for /d %%a in ("%localappdata%\Microsoft\Windows\Caches\*.*") do rd /q /s "%%a"
del C:\ProgramData\Microsoft\Windows\Caches /f /q /s
for /d %%a in ("C:\ProgramData\Microsoft\Windows\Caches\*.*") do rd /q /s "%%a"
del C:\ProgramData\Microsoft\Search /f /q /s
for /d %%a in ("C:\ProgramData\Microsoft\Search\*.*") do rd /q /s "%%a"
) >nul 2>&1

REM Open Explorer
cls
echo [==========================100.0%%==========================]
start explorer.exe
echo msgbox "Cleanup complete! A restart is recommended.",4160,"System TuneUp by Felixplored">%temp%\i.vbs & wscript %temp%\i.vbs & del %temp%\i.vbs
goto menu