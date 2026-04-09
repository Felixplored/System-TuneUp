System TuneUp by Felixplored v. 2.2

Version-History:
v. 2.2  (2026-04-10) · Set the encoding for the program and README back to “UTF-8”, switched the program and README to English,
                       The drop-down menu is minimized.
v. 2.1  (2026-04-09) · Added a “Restart” dialog box.
v. 2.0  (2026-04-08) · Program encoding changed to: “ANSI” & “Windows Command Script”,
                       README: Encoding changed to “ANSI”; drop-down menu expanded.
=======================================================================================================================================================================================
v. 1.19 (2026-04-08) · The selection menu has been expanded, and an information dialog box has been added.  
v. 1.18 (2026-04-07) · Added to the drop-down menu.
v. 1.17 (2026-04-06) · Removed unnecessary DISM commands & added a new DISM command to repair the Component Store,
                       Added System File Checker; inserted a repair prompt at the beginning of the command script.
v. 1.16 (2026-04-05) · Progress bar added.
v. 1.15 (2026-04-04) · Quick Start & Hibernate will now be disabled. Explorer will now be closed and restarted before the Windows caches are cleared,
                       The icon cache in Local AppData is now being cleaned up. The folder “Microsoft\Windows\Caches” in ProgramData is now being cleaned up,
                       The Qt Shader Cache is now being cleaned up, Windows crash dumps are now being cleaned up, and other logs, caches, and temporary files are now being cleaned up.
v. 1.14 (2026-04-03) · Added an admin check feature so that the batch always runs as an administrator,
                       The command “chkdsk” is now run with the parameter C: /f.
v. 1.13 (2026-04-01) · Storage Sense is now being queried.
v. 1.12 (2026-03-30) · The D3DS cache in Local AppData is now being cleaned up. The Logs folder: “C:\Windows\Logs” is now being cleaned up,
                       The “Microsoft\Windows\Caches” folder in Local AppData is now being cleaned up.
v. 1.11 (2026-03-28) · The “SquirrelTemp” folder in LocalAppData and the “Temp” folder in LocalLowAppData are now being cleaned up,
                       The thumbnail cache: “Microsoft\Windows\Explorer” in Local AppData is now being cleared.
v. 1.10 (2026-03-26) · Added initial setup to prevent the command script from hanging.
v. 1.9  (2025-11-28) · Additional AMD caches have been added.
v. 1.8  (2025-07-17) · The restart timer has been set to 1 minute.
v. 1.7  (2025-06-27) · Defragmentation is now being performed with the process priority set to “Normal”.
v. 1.6  (2025-02-01) · The “Recall” feature is disabled; additional NVIDIA caches are added.
v. 1.5  (2024-12-04) · The hidden folders “Config.Msi” and “Recovery” in C: will be deleted.
v. 1.4  (2024-11-27) · The hidden folders “$GetCurrent”, “$Windows.~BT”, and “$Windows.~WS” in C: will be removed,
                       The “Windows.old” folder in C: will be deleted.
v. 1.3  (2024-11-26) · The hidden folders “$SysReset” and “$WinREAgent” in C: will be removed,
                       The “PerfLogs” folder in C: is being cleaned up.
v. 1.2  (2024-11-25) · The “chkdsk” command is now executed before the “defrag C: /u” command,
                       The AMD caches are being cleared.
v. 1.1  (2024-11-24) · The defragmentation progress is now displayed,
                       System Restore will be cleaned up and disabled,
                       The NVIDIA caches are being cleared,
                       Restart feature added.
v. 1.0  (2024-11-22) · Version-History created.

This CMD file performs a repair or cleanup of your computer using built-in Windows tools via a command-line script.

1. Close all running programs before starting.
2. Extract the “TuneUp.cmd” file from the WinRAR archive.
3. Run “TuneUp.cmd” as an administrator.
4. Follow the instructions in the command line and the dialog windows.
 
Caution: 
· The cleanup may take longer depending on your computer.
· Pressing any key will continue the program.
· To cancel, close the window or press Ctrl + C.

Known issues:
· If the command script gets stuck during the first step, restart “TuneUp.cmd”.
· When running the defragmentation, the progress bar may occasionally not display correctly.
· At the end of the command script, the taskbar may occasionally appear with a delay.