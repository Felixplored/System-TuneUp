# Load assemblies for GUI and message boxes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Windows API to force foreground focus, control system menu, enable window dragging and dark title bar
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnableMenuItem(IntPtr hMenu, uint uIDEnableItem, uint uEnable);

    [DllImport("user32.dll")]
    public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ReleaseCapture();

    [DllImport("dwmapi.dll", PreserveSig = true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@

# Resolve script folder and log file path (SystemTuneUp.log next to SystemTuneUp.ps1)
$script:ScriptDir = if (-not [string]::IsNullOrEmpty($PSScriptRoot)) {
    $PSScriptRoot
} elseif (-not [string]::IsNullOrEmpty($MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}
$script:LogFilePath = Join-Path -Path $script:ScriptDir -ChildPath "SystemTuneUp.log"
$script:Utf8NoBom   = New-Object System.Text.UTF8Encoding($false)

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    try {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $line = "[$timestamp] [$Level] $Message" + [Environment]::NewLine
        [System.IO.File]::AppendAllText($script:LogFilePath, $line, $script:Utf8NoBom)
    } catch { }
}

# Create/initialize SystemTuneUp.log immediately on first run
Write-Log -Message "=== System TuneUp v3.1.0 started ===" -Level "INFO"

# Invisible helper window for perfectly forced foreground dialogs
$script:TopMostHelper = New-Object System.Windows.Forms.Form
$script:TopMostHelper.TopMost = $true

# Global execution guard to prevent re-clicking active buttons or closing while busy
$script:IsBusy = $false

# Progress bar state variables for custom centered percentage rendering
$script:ProgressValue = 0
$script:ProgressText  = ""
$script:IsMarquee     = $false
$script:MarqueePos    = 0

# Central function for foreground message boxes
function Show-ForegroundMessage {
    param(
        [string]$Message,
        [string]$Title = "System TuneUp by Felixplored",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information,
        [System.Windows.Forms.MessageBoxDefaultButton]$DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button1
    )
    $cleanMsg = $Message -replace "(\r?\n)+", " | "
    $buttonLabel = if ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::YesNo) { "Yes/No" } else { "$Buttons" }
    Write-Log -Message "Dialog shown [$Icon | $buttonLabel]: $cleanMsg" -Level "INFO"
    $res = [System.Windows.Forms.MessageBox]::Show($script:TopMostHelper, $Message, $Title, $Buttons, $Icon, $DefaultButton)
    Write-Log -Message "Dialog result: $res" -Level "INFO"
    return $res
}

function Enable-DarkTitleBar {
    param([System.Windows.Forms.Form]$TargetForm)

    if (-not $TargetForm -or $TargetForm.Handle -eq [IntPtr]::Zero) { return }

    $darkMode = 1
    $intSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][int])
    # 20 = DWMWA_USE_IMMERSIVE_DARK_MODE (Windows 10 20H1+ / Windows 11), 19 = older Windows 10 fallback
    $result = [Win32]::DwmSetWindowAttribute($TargetForm.Handle, 20, [ref]$darkMode, $intSize)
    if ($result -ne 0) {
        [void][Win32]::DwmSetWindowAttribute($TargetForm.Handle, 19, [ref]$darkMode, $intSize)
    }
}

# ==========================================
# 1. Admin Check
# ==========================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log -Message "Administrator privileges missing. Exiting." -Level "WARN"
    Show-ForegroundMessage -Message "Please run as administrator!" -Icon Error
    exit
}
Write-Log -Message "Administrator privileges verified." -Level "INFO"

# ==========================================
# 2. Helper Functions & Invisible Task Engine
# ==========================================
function Clear-FolderContents {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Write-Log -Message "Clearing folder contents: $Path" -Level "INFO"
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Log -Message "Folder not found (skipped): $Path" -Level "INFO"
    }
}

function Invoke-HiddenCommand {
    param(
        [string]$FilePath,
        [string]$ArgumentList
    )
    Write-Log -Message "Executing command: $FilePath $ArgumentList" -Level "INFO"
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $ArgumentList
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $p = [System.Diagnostics.Process]::Start($psi)
        
        while (-not $p.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        Write-Log -Message "Command finished (ExitCode=$($p.ExitCode)): $FilePath $ArgumentList" -Level "INFO"
    } catch {
        Write-Log -Message "Command failed ($FilePath $ArgumentList): $($_.Exception.Message)" -Level "ERROR"
    }
}

function Update-ProgressDisplay {
    param(
        [int]$Value = 0,
        [string]$Text = "",
        [bool]$Marquee = $false
    )
    $script:ProgressValue = $Value
    $script:ProgressText  = $Text
    $script:IsMarquee     = $Marquee
    if ($marqueeTimer) {
        $marqueeTimer.Enabled = $Marquee
    }
    if ($pnlProgress) {
        $pnlProgress.Invalidate()
    }
}

# Manages lock state, colors, dynamic active borders, click protection & window close (X) state centrally
function Set-MenuState {
    param(
        [bool]$IsRunning,
        [System.Windows.Forms.Button]$ActiveButton = $null
    )

    $script:IsBusy = $IsRunning

    $normalBg      = [System.Drawing.Color]::FromArgb(45, 45, 52)
    $disabledColor = [System.Drawing.Color]::FromArgb(35, 35, 40)
    $defaultBorder = [System.Drawing.Color]::FromArgb(70, 70, 80)

    $allButtons = @($btnSetup, $btnRepair, $btnClean, $btnReadme, $btnLog)

    # Move focus away from buttons so Windows never draws a thick focus border
    if ($form) { $form.ActiveControl = $lblTitle }

    # Dynamically disable or enable the window's close (X) button via Win32 API
    if ($form -and $form.Handle -ne [IntPtr]::Zero) {
        $hMenu = [Win32]::GetSystemMenu($form.Handle, $false)
        if ($hMenu -ne [IntPtr]::Zero) {
            if ($IsRunning) {
                [void][Win32]::EnableMenuItem($hMenu, 0xF060, 0x0001) # Gray out / disable X button
            } else {
                [void][Win32]::EnableMenuItem($hMenu, 0xF060, 0x0000) # Enable X button
            }
        }
    }

    foreach ($b in $allButtons) {
        if (-not $IsRunning) {
            # Normal state: All active, standard color, uniform thin border, hand cursor
            $b.Enabled = $true
            $b.BackColor = $normalBg
            $b.FlatAppearance.BorderSize = 1
            $b.FlatAppearance.BorderColor = $defaultBorder
            $b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::Empty
            $b.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Empty
            $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        } else {
            # Execution state: Active button gets prominent white border, rest dims & locks
            if ($b -eq $ActiveButton) {
                $b.Enabled = $true
                $b.BackColor = $normalBg
                $b.FlatAppearance.BorderSize = 2
                $b.FlatAppearance.BorderColor = [System.Drawing.Color]::White
                # Prevent hover/click visual reaction while locked
                $b.FlatAppearance.MouseOverBackColor = $normalBg
                $b.FlatAppearance.MouseDownBackColor = $normalBg
                $b.Cursor = [System.Windows.Forms.Cursors]::Default
            } else {
                $b.Enabled = $false
                $b.BackColor = $disabledColor
                $b.FlatAppearance.BorderSize = 1
                $b.FlatAppearance.BorderColor = $defaultBorder
                $b.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Invoke-TaskQueue {
    param(
        [array]$Tasks,
        [string]$CompletionMessage,
        [System.Windows.Forms.Button]$ActiveButton,
        [string]$QueueName = "Task Queue"
    )

    Write-Log -Message "Starting $QueueName ($($Tasks.Count) tasks)." -Level "INFO"
    Set-MenuState -IsRunning $true -ActiveButton $ActiveButton
    $total = $Tasks.Count
    $current = 0

    Update-ProgressDisplay -Value 0 -Text "0%" -Marquee $false

    foreach ($task in $Tasks) {
        $percentBefore = [math]::Round(($current / $total) * 100)
        $lblStatus.Text = "[$($current + 1)/$total] $($task.Name)"
        Write-Log -Message "Task [$($current + 1)/$total] started: $($task.Name)" -Level "INFO"
        
        if ($task.Indeterminate) {
            Update-ProgressDisplay -Value 0 -Text "" -Marquee $true
        } else {
            Update-ProgressDisplay -Value $percentBefore -Text "$percentBefore%" -Marquee $false
        }
        [System.Windows.Forms.Application]::DoEvents()

        & $task.Action

        $current++
        $percentAfter = [math]::Round(($current / $total) * 100)
        Update-ProgressDisplay -Value $percentAfter -Text "$percentAfter%" -Marquee $false
        $lblStatus.Text = "[$current/$total] $($task.Name)"
        Write-Log -Message "Task [$current/$total] completed ($percentAfter%): $($task.Name)" -Level "INFO"
        [System.Windows.Forms.Application]::DoEvents()
    }

    if ($CompletionMessage) {
        Show-ForegroundMessage -Message $CompletionMessage -Icon Information
    }

    Update-ProgressDisplay -Value 0 -Text "" -Marquee $false
    $lblStatus.Text = "Ready"
    Set-MenuState -IsRunning $false
    Write-Log -Message "Completed $QueueName." -Level "INFO"
}

# ==========================================
# 3. Main Functions
# ==========================================
function Start-InitialSetup {
    if ($script:IsBusy) { return }
    $tasks = @(
        @{
            Name = "Configure Disk Cleanup (cleanmgr)"
            Indeterminate = $true
            Action = {
                Show-ForegroundMessage -Message "Check ALL boxes and click OK." -Icon Warning
                Write-Log -Message "Launching cleanmgr.exe /sageset:1" -Level "INFO"
                Start-Process "cleanmgr.exe" -ArgumentList "/sageset:1" -Wait
            }
        }
    )
    Invoke-TaskQueue -Tasks $tasks -ActiveButton $btnSetup -QueueName "Initial Setup"
}

function Start-RepairPC {
    if ($script:IsBusy) { return }
    $tasks = @(
        @{
            Name = "Repairing Component Store (DISM)"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "dism.exe" "/Online /Cleanup-Image /RestoreHealth" }
        },
        @{
            Name = "Running System File Checker (SFC)"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "sfc.exe" "/scannow" }
        },
        @{
            Name = "Windows Defender Quick Scan"
            Indeterminate = $false
            Action = {
                $defenderPath = "C:\Program Files\Windows Defender\MpCmdRun.exe"
                if (Test-Path $defenderPath) {
                    Invoke-HiddenCommand $defenderPath "-Scan -ScanType 1"
                } else {
                    Write-Log -Message "MpCmdRun.exe not found (skipped)." -Level "WARN"
                }
            }
        },
        @{
            Name = "Windows MRT Quick Scan"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "mrt.exe" "/q" }
        },
        @{
            Name = "Running Check Disk (chkdsk)"
            Indeterminate = $false
            Action = { 
                Invoke-HiddenCommand "cmd.exe" "/c (echo J & echo Y) | chkdsk.exe C: /f" 
            }
        }
    )
    Invoke-TaskQueue -Tasks $tasks -CompletionMessage "Repair complete! A restart is recommended." -ActiveButton $btnRepair -QueueName "Repair PC"
}

function Start-CleanupPC {
    if ($script:IsBusy) { return }
    $tasks = @(
        @{
            Name = "Running Disk Cleanup"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "cleanmgr.exe" "/sagerun:1" }
        },
        @{
            Name = "Windows Storage Sense"
            Indeterminate = $false
            Action = {
                Write-Log -Message "Opening Storage Sense settings (ms-settings:storagesense)." -Level "INFO"
                Start-Process "ms-settings:storagesense"
                Show-ForegroundMessage -Message "Click on: Temporary files -> Cleanup system files -> Confirm by selecting Yes -> Check ALL boxes -> Remove files -> Next.`n`nWhen finished, close the window and confirm with OK." -Icon Warning
            }
        },
        @{
            Name = "Defragmenting / Optimizing C:"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "defrag.exe" "C: /h /u" }
        },
        @{
            Name = "Cleaning Component Store (DISM)"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "dism.exe" "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" }
        },
        @{
            Name = "Disabling feature: Recall"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "dism.exe" "/Online /Disable-Feature /Featurename:Recall /NoRestart" }
        },
        @{
            Name = "Removing System Restore points"
            Indeterminate = $false
            Action = {
                Invoke-HiddenCommand "vssadmin.exe" "delete shadows /all /quiet"
                Write-Log -Message "Disabling System Restore on C:\." -Level "INFO"
                Disable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            }
        },
        @{
            Name = "Disabling Quick Start & Hibernation"
            Indeterminate = $false
            Action = { Invoke-HiddenCommand "powercfg.exe" "-h off" }
        },
        @{
            Name = "Clearing DNS Cache"
            Indeterminate = $false
            Action = {
                Write-Log -Message "Clearing DNS client cache." -Level "INFO"
                Clear-DnsClientCache -ErrorAction SilentlyContinue
            }
        },
        @{
            Name = "Clearing Microsoft Store Cache"
            Indeterminate = $false
            Action = {
                Write-Log -Message "Running wsreset.exe to clear Microsoft Store cache." -Level "INFO"
                Start-Process "wsreset.exe" -WindowStyle Hidden
                Start-Sleep -Seconds 2
                Stop-Process -Name "WinStore.App" -Force -ErrorAction SilentlyContinue
            }
        },
        @{
            Name = "Clearing Windows Event Logs"
            Indeterminate = $false
            Action = {
                Write-Log -Message "Clearing all Windows Event Logs via wevtutil.exe." -Level "INFO"
                & wevtutil.exe el | ForEach-Object {
                    & wevtutil.exe cl "$_" 2>$null
                }
            }
        },
        @{
            Name = "Stopping & disabling Windows Search"
            Indeterminate = $false
            Action = {
                Write-Log -Message "Stopping and disabling Windows Search (WSearch) service." -Level "INFO"
                Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
            }
        },
        @{
            Name = "Deleting hidden Windows folders"
            Indeterminate = $false
            Action = {
                $hiddenFolders = @(
                    "C:\`$GetCurrent", "C:\`$SysReset", "C:\`$Windows.~BT", "C:\`$Windows.~WS",
                    "C:\`$WinREAgent", "C:\Config.Msi", "C:\Recovery", "C:\Windows.old"
                )
                foreach ($folder in $hiddenFolders) {
                    if (Test-Path -LiteralPath $folder) {
                        Write-Log -Message "Deleting hidden Windows folder: $folder" -Level "INFO"
                        Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        },
        @{
            Name = "Clearing AMD Shader Cache"
            Indeterminate = $false
            Action = {
                $localAppData    = $env:LOCALAPPDATA
                $localAppDataLow = "$env:USERPROFILE\AppData\LocalLow"
                $amdPaths = @(
                    "C:\.cache\AMD\DX9Cache", "C:\.cache\AMD\DxCache", "C:\.cache\AMD\DxcCache",
                    "$localAppData\AMD\DX9Cache", "$localAppData\AMD\DxCache", "$localAppData\AMD\DxcCache",
                    "$localAppData\AMD\OglCache", "$localAppData\AMD\VkCache",
                    "$localAppDataLow\AMD\DxCache", "$localAppDataLow\AMD\DxcCache"
                )
                foreach ($p in $amdPaths) { Clear-FolderContents $p }
            }
        },
        @{
            Name = "Clearing NVIDIA Shader Cache"
            Indeterminate = $false
            Action = {
                $localAppData    = $env:LOCALAPPDATA
                $localAppDataLow = "$env:USERPROFILE\AppData\LocalLow"
                $appData         = $env:APPDATA
                $nvidiaPaths = @(
                    "$localAppData\NVIDIA\DXCache",
                    "C:\Windows\System32\config\systemprofile\AppData\Local\NVIDIA\DXCache",
                    "$localAppData\NVIDIA\GLCache", "$localAppData\NVIDIA\OptixCache",
                    "$localAppDataLow\NVIDIA\DXCache",
                    "C:\Windows\System32\config\systemprofile\AppData\LocalLow\NVIDIA\DXCache",
                    "$localAppDataLow\NVIDIA\PerDriverVersion\DXCache",
                    "$appData\NVIDIA\ComputeCache",
                    "C:\Windows\System32\config\systemprofile\AppData\Roaming\NVIDIA\ComputeCache"
                )
                foreach ($p in $nvidiaPaths) { Clear-FolderContents $p }
            }
        },
        @{
            Name = "Clearing D3DS Cache"
            Indeterminate = $false
            Action = {
                Clear-FolderContents "$env:LOCALAPPDATA\D3DSCache"
                Clear-FolderContents "C:\Windows\System32\config\systemprofile\AppData\Local\D3DSCache"
            }
        },
        @{
            Name = "Clearing Qt Shader & Fontconfig Cache"
            Indeterminate = $false
            Action = {
                Clear-FolderContents "$env:LOCALAPPDATA\cache"
                Clear-FolderContents "$env:LOCALAPPDATA\fontconfig"
            }
        },
        @{
            Name = "Clearing Task Scheduler Cache"
            Indeterminate = $false
            Action = { Clear-FolderContents "C:\Windows\SchCache" }
        },
        @{
            Name = "Clearing Windows Temp files"
            Indeterminate = $false
            Action = {
                $localAppData    = $env:LOCALAPPDATA
                $localAppDataLow = "$env:USERPROFILE\AppData\LocalLow"
                $tempPaths = @(
                    $env:TEMP,
                    "C:\Windows\System32\config\systemprofile\AppData\Local\Temp",
                    "$localAppData\SquirrelTemp",
                    "$localAppDataLow\Temp",
                    "C:\Windows\Temp",
                    "C:\Windows\SystemTemp",
                    "C:\Windows\CbsTemp",
                    "C:\Windows\SoftwareDistribution\Download"
                )
                foreach ($p in $tempPaths) { Clear-FolderContents $p }
            }
        },
        @{
            Name = "Clearing Windows CrashDumps"
            Indeterminate = $false
            Action = {
                $crashPaths = @(
                    "$env:LOCALAPPDATA\CrashDumps",
                    "C:\Windows\System32\config\systemprofile\AppData\Local\CrashDumps",
                    "C:\ProgramData\Microsoft\Windows\WER",
                    "C:\Windows\LiveKernelReports",
                    "C:\Windows\Minidump"
                )
                foreach ($p in $crashPaths) { Clear-FolderContents $p }
            }
        },
        @{
            Name = "Clearing Windows Logs"
            Indeterminate = $false
            Action = {
                $logPaths = @("C:\PerfLogs", "C:\Windows\Logs", "C:\Windows\debug")
                foreach ($p in $logPaths) { Clear-FolderContents $p }
            }
        },
        @{
            Name = "Clearing Windows Prefetch"
            Indeterminate = $false
            Action = { Clear-FolderContents "C:\Windows\Prefetch" }
        },
        @{
            Name = "Stopping Explorer & clearing Icon/Thumbnail Cache"
            Indeterminate = $false
            Action = {
                Invoke-HiddenCommand "taskkill.exe" "/f /im explorer.exe"
                Start-Sleep -Milliseconds 800

                $localAppData = $env:LOCALAPPDATA
                $iconCache = "$localAppData\IconCache.db"
                if (Test-Path -LiteralPath $iconCache) {
                    Write-Log -Message "Deleting IconCache.db: $iconCache" -Level "INFO"
                    Remove-Item -LiteralPath $iconCache -Force -ErrorAction SilentlyContinue
                }
                Clear-FolderContents "$localAppData\Microsoft\Windows\Explorer"
            }
        },
        @{
            Name = "Clearing remaining caches & starting Explorer"
            Indeterminate = $false
            Action = {
                $otherCaches = @(
                    "C:\Windows\System32\config\systemprofile\AppData\LocalLow\Microsoft\CryptnetUrlCache",
                    "$env:LOCALAPPDATA\Microsoft\Windows\Caches",
                    "C:\ProgramData\Microsoft\Windows\Caches",
                    "C:\ProgramData\Microsoft\Search"
                )
                foreach ($p in $otherCaches) { Clear-FolderContents $p }
                Write-Log -Message "Starting explorer.exe." -Level "INFO"
                Start-Process "explorer.exe"
            }
        }
    )
    Invoke-TaskQueue -Tasks $tasks -CompletionMessage "Cleanup complete! A restart is recommended." -ActiveButton $btnClean -QueueName "Cleanup PC"
}

# --- Open Text File Viewer (Fullscreen) ---
function Show-TextViewer {
    param(
        [string]$FileName,
        [string]$WindowTitle,
        [System.Windows.Forms.Button]$ActiveButton,
        [string]$LogLabel
    )
    if ($script:IsBusy) { return }
    Write-Log -Message "Opening $LogLabel viewer." -Level "INFO"
    Set-MenuState -IsRunning $true -ActiveButton $ActiveButton

    $filePath = Join-Path -Path $script:ScriptDir -ChildPath $FileName
    $content = if (Test-Path -LiteralPath $filePath) {
        Write-Log -Message "Loaded $LogLabel from: $filePath" -Level "INFO"
        Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
    } else {
        Write-Log -Message "$FileName not found in: $($script:ScriptDir)" -Level "WARN"
        "$FileName not found in:`r`n$($script:ScriptDir)"
    }

    $viewerForm = New-Object System.Windows.Forms.Form
    $viewerForm.Text = $WindowTitle
    $viewerForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $viewerForm.StartPosition = "CenterParent"
    $viewerForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

    [void]$viewerForm.Handle
    Enable-DarkTitleBar -TargetForm $viewerForm

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ReadOnly = $true
    $textBox.ScrollBars = "Both"
    $textBox.WordWrap = $false
    $textBox.Dock = "Fill"
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 24)
    $textBox.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $textBox.Text = $content

    $viewerForm.Controls.Add($textBox)

    $viewerForm.Add_Shown({
        $textBox.Select(0, 0)
        [void]$viewerForm.Focus()
    })

    [void]$viewerForm.ShowDialog()
    Set-MenuState -IsRunning $false
    Write-Log -Message "Closed $LogLabel viewer." -Level "INFO"
}

function Show-Readme {
    Show-TextViewer -FileName "README.txt" -WindowTitle "README - System TuneUp by Felixplored" -ActiveButton $btnReadme -LogLabel "README"
}

function Show-Log {
    Show-TextViewer -FileName "SystemTuneUp.log" -WindowTitle "LOG - System TuneUp by Felixplored" -ActiveButton $btnLog -LogLabel "LOG"
}

# ==========================================
# 4. Create User Interface (GUI)
# ==========================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "System TuneUp by Felixplored"
$form.Size = New-Object System.Drawing.Size(440, 425)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 32)
$form.ForeColor = [System.Drawing.Color]::White

[void]$form.Handle
Enable-DarkTitleBar -TargetForm $form

$form.Add_Shown({
    $form.TopMost = $true
    [Win32]::SetForegroundWindow($form.Handle)
    $form.TopMost = $false
    # Prevent default focus border on the first button at startup
    $form.ActiveControl = $lblTitle
    Write-Log -Message "Main GUI displayed." -Level "INFO"
})

# Handle window close (X button): block completely while tasks are running, otherwise prompt and always close
$form.Add_FormClosing({
    param($sender, $e)
    if ($script:IsBusy) {
        Write-Log -Message "Window close blocked while task is running." -Level "WARN"
        $e.Cancel = $true
        return
    }

    Set-MenuState -IsRunning $true
    $result = Show-ForegroundMessage -Message "Would you like to restart the system?" -Buttons YesNo -Icon Question -DefaultButton Button2

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Write-Log -Message "User confirmed restart (shutdown.exe /r /t 60)." -Level "INFO"
        Start-Process "shutdown.exe" -ArgumentList "/r /t 60"
    } else {
        Write-Log -Message "User declined restart." -Level "INFO"
    }
    Write-Log -Message "=== System TuneUp v3.1.0 closed ===" -Level "INFO"
    # Leaving $e.Cancel untouched allows Windows Forms to close the window cleanly for both Yes and No
})

# Universal window dragging handler (allows moving the form by clicking anywhere on background/labels/progress bar)
$enableDrag = {
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        [Win32]::ReleaseCapture()
        [void][Win32]::SendMessage($form.Handle, 0xA1, 2, 0) # WM_NCLBUTTONDOWN, HTCAPTION
    }
}
$form.Add_MouseDown($enableDrag)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "System TuneUp"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 255)
$lblTitle.AutoSize = $false
$lblTitle.Size = New-Object System.Drawing.Size(400, 35)
$lblTitle.Location = New-Object System.Drawing.Point(12, 18)
$lblTitle.TextAlign = "MiddleCenter"
$lblTitle.Add_MouseDown($enableDrag)
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "by Felixplored | v3.1.0"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSub.ForeColor = [System.Drawing.Color]::Silver
$lblSub.AutoSize = $false
$lblSub.Size = New-Object System.Drawing.Size(400, 22)
$lblSub.Location = New-Object System.Drawing.Point(12, 53)
$lblSub.TextAlign = "MiddleCenter"
$lblSub.Add_MouseDown($enableDrag)
$form.Controls.Add($lblSub)

function New-MenuButton {
    param(
        [string]$Text,
        [int]$X = 45,
        [int]$Y,
        [int]$Width = 335,
        [System.Drawing.Color]$BgColor
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($Width, 42)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
    $btn.BackColor = $BgColor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.TabStop = $false
    return $btn
}

$btnBg = [System.Drawing.Color]::FromArgb(45, 45, 52)

$btnSetup  = New-MenuButton -Text "Initial Setup" -Y 95  -BgColor $btnBg
$btnRepair = New-MenuButton -Text "Repair PC"     -Y 147 -BgColor $btnBg
$btnClean  = New-MenuButton -Text "Cleanup PC"    -Y 199 -BgColor $btnBg
$btnReadme = New-MenuButton -Text "README"        -X 45  -Y 251 -Width 162 -BgColor $btnBg
$btnLog    = New-MenuButton -Text "LOG"           -X 218 -Y 251 -Width 162 -BgColor $btnBg

$btnSetup.Add_Click({ Start-InitialSetup })
$btnRepair.Add_Click({ Start-RepairPC })
$btnClean.Add_Click({ Start-CleanupPC })
$btnReadme.Add_Click({ Show-Readme })
$btnLog.Add_Click({ Show-Log })

$form.Controls.AddRange(@($btnSetup, $btnRepair, $btnClean, $btnReadme, $btnLog))

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblStatus.ForeColor = [System.Drawing.Color]::LightGray
$lblStatus.Location = New-Object System.Drawing.Point(45, 308)
$lblStatus.Size = New-Object System.Drawing.Size(335, 18)
$lblStatus.Add_MouseDown($enableDrag)
$form.Controls.Add($lblStatus)

# Custom double-buffered progress bar with centered percentage text
$pnlProgress = New-Object System.Windows.Forms.Panel
$pnlProgress.Location = New-Object System.Drawing.Point(45, 330)
$pnlProgress.Size = New-Object System.Drawing.Size(335, 18)
$pnlProgress.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 40)
$pnlProgress.Add_MouseDown($enableDrag)

# Enable DoubleBuffered on Panel to prevent any flickering
$propDoubleBuffered = [System.Windows.Forms.Control].GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
$propDoubleBuffered.SetValue($pnlProgress, $true, $null)

$marqueeTimer = New-Object System.Windows.Forms.Timer
$marqueeTimer.Interval = 30
$marqueeTimer.Add_Tick({
    $script:MarqueePos += 5
    if ($script:MarqueePos -gt $pnlProgress.Width) { $script:MarqueePos = -80 }
    $pnlProgress.Invalidate()
})

$pnlProgress.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $w = $sender.Width
    $h = $sender.Height

    $bgBrush     = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 35, 40))
    $fillBrush   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 174, 255))
    $borderPen   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 70, 80), 1)

    $g.FillRectangle($bgBrush, 0, 0, $w, $h)

    if ($script:IsMarquee) {
        $g.FillRectangle($fillBrush, $script:MarqueePos, 1, 80, $h - 2)
    } else {
        $fillWidth = [int](($w - 2) * ($script:ProgressValue / 100.0))
        if ($fillWidth -gt 0) {
            $g.FillRectangle($fillBrush, 1, 1, $fillWidth, $h - 2)
        }
    }

    $g.DrawRectangle($borderPen, 0, 0, $w - 1, $h - 1)

    if (-not [string]::IsNullOrEmpty($script:ProgressText)) {
        $font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF(0, 0, $w, $h)

        # Draw subtle dark shadow/outline so text stays crisp over both background and blue fill
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(18, 18, 22))
        $textBrush   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString($script:ProgressText, $font, $shadowBrush, (New-Object System.Drawing.RectangleF(1, 1, $w, $h)), $sf)
        $g.DrawString($script:ProgressText, $font, $textBrush, $rect, $sf)

        $font.Dispose()
        $sf.Dispose()
        $shadowBrush.Dispose()
        $textBrush.Dispose()
    }

    $bgBrush.Dispose()
    $fillBrush.Dispose()
    $borderPen.Dispose()
})

$form.Controls.Add($pnlProgress)

$lblCopyright = New-Object System.Windows.Forms.Label
$lblCopyright.Text = "$([char]0x00A9) SystemTuneUp by Felixplored. All rights reserved."
$lblCopyright.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$lblCopyright.ForeColor = [System.Drawing.Color]::Gray
$lblCopyright.Location = New-Object System.Drawing.Point(45, 356)
$lblCopyright.Size = New-Object System.Drawing.Size(335, 18)
$lblCopyright.TextAlign = "MiddleCenter"
$lblCopyright.Add_MouseDown($enableDrag)
$form.Controls.Add($lblCopyright)

[void]$form.ShowDialog()