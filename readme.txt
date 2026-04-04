System TuneUp by Felixplored v. 1.16

Versionshistorie:
v. 1.16 (05.04.2026) ・ Fortschrittsanzeige hinzugefügt.
v. 1.15 (04.04.2026) ・ Der Ruhezustand wird nun deaktiviert, Der Explorer wird nun vor dem leeren der Windows Caches beendet und erneut ausgeführt,
                       Der Icon Cache in Local AppData wird nun Bereinigt, Der Ordner: "Microsoft\Windows\Caches" in ProgrammData wird nun Bereinigt,
		               Der Qt Shader Cache wird nun Bereinigt, Windows CrashDumps werden nun Bereinigt, Weitere Logs, Caches & Temps werden nun Bereinigt.			   
v. 1.14 (03.04.2026) ・ Admin-Check Funktion hinzugefügt damit das Batch immer als Administrator ausgeführt wird,
                       Der Befehl: "chkdsk" wird nun mit dem Parameter C: /f ausgeführt.
v. 1.13 (01.04.2026) ・ Speicheroptimierung (Storage Sense) wird nun abgefragt.
v. 1.12 (30.03.2026) ・ Der D3DS Cache in Local AppData wird nun Bereinigt, Der Logs Ordner: "C:\Windows\Logs" wird nun Bereinigt,
                       Der Caches Ordner: "Microsoft\Windows\Caches" in Local AppData wird nun Bereinigt.
v. 1.11 (28.03.2026) ・ Die Ordner: "SquirrelTemp" in Local AppData & "Temp" in LocalLow AppData werden nun Bereinigt,
                       Der Thumbnail Cache: "Microsoft\Windows\Explorer" in Local AppData wird nun Bereinigt.
v. 1.10 (26.03.2026) ・ Ersteinrichtung hinzugefügt um ein aufhängen des Befehls-Skript zu mindern.
v. 1.9  (28.11.2025) ・ Weitere AMD Caches hinzugefügt.
v. 1.8  (17.07.2025) ・ Der Timer für den Neustart wurde auf 1 Minute gesetzt.
v. 1.7  (27.06.2025) ・ Die Defragmentierung wird nun mit der Prozess Priorität: "Normal" ausgeführt.
v. 1.6  (01.02.2025) ・ Das Feature: "Recall" wird Deaktiviert, Weitere NVIDIA Caches hinzugefügt.
v. 1.5  (04.12.2024) ・ Die ausgeblendeten Ordner: "Config.Msi" & "Recovery" in C: werden entfernt.
v. 1.4  (27.11.2024) ・ Die ausgeblendeten Ordner: "$GetCurrent" & "$Windows.~BT" & "$Windows.~WS" in C: werden entfernt,
                       Der Ordner: "Windows.old" in C: wird entfernt.
v. 1.3  (26.11.2024) ・ Die ausgeblendeten Ordner: "$SysReset" & "$WinREAgent" in C: werden entfernt,
                       Der Ordner: "PerfLogs" in C: wird Bereinigt.
v. 1.2  (25.11.2024) ・ Der Befehl: "chkdsk" wird nun vor dem Befehl: "defrag C: /u" ausgeführt,
                       Die AMD Caches werden Bereinigt.
v. 1.1  (24.11.2024) ・ Fortschritt für die Defragmentierung wird jetzt angezeigt,
                       Die Systemwiederherstellung wird Bereinigt und Deaktiviert, 
                       Die NVIDIA Caches werden Bereinigt,
                       Neustart Funktion hinzugefügt.
v. 1.0  (22.11.2024) ・ Versionshistorie erstellt.

Diese Batch Datei führt eine Bereinigung des Computers durch mit Hauseigenen Windows Tools per Befehls-Skript.

1. Beende alle laufenden Programme vor dem Start.
2. Entpacke die: "TuneUp.bat" aus dem WinRAR-Archiv.
3. Führe die: "TuneUp.bat" als Administrator aus.
4. Folge den Anweisungen in der Kommandozeile.
 
Vorsicht: 
・ Durch Drücken einer beliebigen Taste wird das Programm weiter ausgeführt.
・ Abbrechen erfolgt, wenn das Fenster geschlossen wird.
・ Die Bereinigung kann je nach Computer länger andauern. 
・ Die Bereinigung ist Abgeschlossen, wenn in der Kommandozeile: "Bereinigung beendet! Ein Neustart wird zwingend empfohlen." steht.
・ Es muss am Ende eine Wahl zwecks Neustart getroffen werden. (y/n) - ENTER führt ebenfalls einen Neustart durch.

Bekannte Fehler:
・ Sollte das Befehls-Skript beim ersten Schritt hängen bleiben starte die: "TuneUp.bat" neu.
・ Am Ende des Befehls-Skript kann es vereinzelt vorkommen, dass die Taskleiste erst später erscheint.