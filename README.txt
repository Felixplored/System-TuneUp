System TuneUp by Felixplored v2.4.0

Version-History:
v2.4.0  (2026-04-16) - Windows Defender Quick Scan and Windows MRT Quick Scan have been added to the repair options.
v2.3.1  (2026-04-12) - CHCP has been removed to fix display errors involving umlauts and to improve global compatibility.
v2.3.0  (2026-04-11) - Versioning changed; The "Windows Search" service is stopped, disabled and database is cleared;
                       Fixed "Restart" dialog box.
v2.2.0  (2026-04-10) - Set the encoding for the program and README back to "UTF-8"; Switched the program and README to English;
                       The drop-down menu is minimized.
v2.1.0  (2026-04-09) - Added a "Restart" dialog box.
v2.0.0  (2026-04-08) - Program encoding changed to: "ANSI" & "Windows Command Script";
                       README encoding changed to: "ANSI"; Drop-down menu expanded.
======================================================================================================================================================================================
v1.19.0 (2026-04-08) - The selection menu has been expanded; Information dialog boxes added.  
v1.18.0 (2026-04-07) - Added to the drop-down menu.
v1.17.0 (2026-04-06) - Removed unnecessary DISM commands & added a new DISM command to repair the Component Store;
                       Added System File Checker; Inserted a repair prompt at the beginning of the command script.
v1.16.0 (2026-04-05) - Progress bar added.
v1.15.0 (2026-04-04) - Quick Start & Hibernation will now be disabled; Explorer will now be closed and restarted before the Windows caches are cleared;
                       The icon cache in Local AppData is now being cleaned up; The folder: "Microsoft\Windows\Caches" in ProgramData is now being cleaned up;
                       The Qt Shader Cache is now being cleaned up; Windows crash dumps are now being cleaned up and other logs, caches, and temporary files are now being cleaned up.
v1.14.0 (2026-04-03) - Added an admin check feature so that the batch always runs as an administrator;
                       The command: "chkdsk" is now run with the parameter C: /f.
v1.13.0 (2026-04-01) - Storage Sense is now being queried.
v1.12.0 (2026-03-30) - The D3DS cache in Local AppData is now being cleaned up; The Logs folder: "C:\Windows\Logs" is now being cleaned up;
                       The "Microsoft\Windows\Caches" folder in Local AppData is now being cleaned up.
v1.11.0 (2026-03-28) - The "SquirrelTemp" folder in LocalAppData and the "Temp" folder in LocalLowAppData are now being cleaned up;
                       The thumbnail cache: "Microsoft\Windows\Explorer" in Local AppData is now being cleared.
v1.10.0 (2026-03-26) - Added initial setup to prevent the command script from hanging.
v1.9.0  (2025-11-28) - Additional AMD caches have been added.
v1.8.0  (2025-07-17) - The restart timer has been set to 1 minute.
v1.7.0  (2025-06-27) - Defragmentation is now being performed with the process priority set to: "Normal".
v1.6.0  (2025-02-01) - The "Recall" feature is disabled; Additional NVIDIA caches are added.
v1.5.0  (2024-12-04) - The hidden folders: "Config.Msi" and "Recovery" in C: will be deleted.
v1.4.0  (2024-11-27) - The hidden folders: "$GetCurrent", "$Windows.~BT", and "$Windows.~WS" in C: will be removed;
                       The "Windows.old" folder in C: will be deleted.
v1.3.0  (2024-11-26) - The hidden folders: "$SysReset" and "$WinREAgent" in C: will be removed;
                       The "PerfLogs" folder in C: is being cleaned up.
v1.2.0  (2024-11-25) - The "chkdsk" command is now executed before the: "defrag C: /u" command;
                       The AMD caches are being cleared.
v1.1.0  (2024-11-24) - The defragmentation progress is now displayed;
                       System Restore will be cleaned up and disabled;
                       The NVIDIA caches are being cleared;
                       Restart feature added.
v1.0.0  (2024-11-22) - Version-History created.

This CMD file performs a repair or cleanup of your computer using built-in Windows tools via a command-line script.

1. Close all running programs before starting.
2. Extract the "TuneUp.cmd" file from the ZIP archive.
3. Run "TuneUp.cmd" as an administrator.
4. Follow the instructions in the command line and the dialog windows.
 
Caution: 
- The cleanup may take longer depending on your computer.
- Pressing any key will continue the program.
- To cancel, close the window or press Ctrl + C.

Known issues:
- If the command script gets stuck during the first step, restart "TuneUp.cmd".
- When running the defragmentation, the progress bar may occasionally not display correctly.
- At the end of the command script, the taskbar may occasionally appear with a delay.