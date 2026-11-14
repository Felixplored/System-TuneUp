# Load assemblies for GUI and message boxes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Windows API to genuinely force foreground window focus
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

# Invisible helper window for perfectly forced foreground dialogs
$script:TopMostHelper = New-Object System.Windows.Forms.Form
$script:TopMostHelper.TopMost = $true

# Central function for foreground message boxes
function Show-ForegroundMessage {
    param(
        [string]$Message,
        [string]$Title = "System TuneUp by Felixplored",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information,
        [System.Windows.Forms.MessageBoxDefaultButton]$DefaultButton = [System.Windows.Forms.MessageBoxDefaultButton]::Button1
    )
    return [System.Windows.Forms.MessageBox]::Show($script:TopMostHelper, $Message, $Title, $Buttons, $Icon, $DefaultButton)
}

# ==========================================
# 1. Admin Check
# ==========================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Show-ForegroundMessage -Message "Please run as administrator!" -Icon Error
    exit
}

# ==========================================
# 2. Helper Functions & Invisible Task Engine
# ==========================================
function Clear-FolderContents {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-HiddenCommand {
    param(
        [string]$FilePath,
        [string]$ArgumentList
    )
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
    } catch { }
}

# Manages lock state, colors & borders for all buttons centrally
function Set-MenuState {
    param(
        [bool]$IsRunning,
        [System.Windows.Forms.Button]$ActiveButton = $null
    )

    $normalBg      = [System.Drawing.Color]::FromArgb(45, 45, 52)
    $exitBg        = [System.Drawing.Color]::FromArgb(140, 45, 45)
    $disabledColor = [System.Drawing.Color]::FromArgb(35, 35, 40)
    $defaultBorder = [System.Drawing.Color]::FromArgb(70, 70, 80)

    $allButtons = @($btnSetup, $btnRepair, $btnClean, $btnReadme, $btnExit)

    foreach ($b in $allButtons) {
        if (-not $IsRunning) {
            # Normal state: All active, standard color, standard border
            $b.Enabled = $true
            $b.BackColor = if ($b -eq $btnExit) { $exitBg } else { $normalBg }
            $b.FlatAppearance.BorderSize = 1
            $b.FlatAppearance.BorderColor = $defaultBorder
        } else {
            # Execution state: Active button stays bright & white-bordered, rest turns gray
            if ($b -eq $ActiveButton) {
                $b.Enabled = $true
                $b.BackColor = if ($b -eq $btnExit) { $exitBg } else { $normalBg }
                $b.FlatAppearance.BorderSize = 2
                $b.FlatAppearance.BorderColor = [System.Drawing.Color]::White
            } else {
                $b.Enabled = $false
                $b.BackColor = $disabledColor
                $b.FlatAppearance.BorderSize = 1
                $b.FlatAppearance.BorderColor = $defaultBorder
            }
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Invoke-TaskQueue {
    param(
        [array]$Tasks,
        [string]$CompletionMessage,
        [System.Windows.Forms.Button]$ActiveButton
    )

    Set-MenuState -IsRunning $true -ActiveButton $ActiveButton
    $total = $Tasks.Count
    $current = 0

    $progressBar.Style = "Blocks"
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0

    foreach ($task in $Tasks) {
        $percentBefore = [math]::Round(($current / $total) * 100)
        $lblStatus.Text = "[$($current + 1)/$total] $($task.Name) ($percentBefore%)"
        
        if ($task.Indeterminate) {
            $progressBar.Style = "Marquee"
        } else {
            $progressBar.Style = "Blocks"
            $progressBar.Value = $percentBefore
        }
        [System.Windows.Forms.Application]::DoEvents()

        & $task.Action

        $current++
        $percentAfter = [math]::Round(($current / $total) * 100)
        $progressBar.Style = "Blocks"
        $progressBar.Value = $percentAfter
        $lblStatus.Text = "[$current/$total] $($task.Name) ($percentAfter%)"
        [System.Windows.Forms.Application]::DoEvents()
    }

    if ($CompletionMessage) {
        Show-ForegroundMessage -Message $CompletionMessage -Icon Information
    }

    $progressBar.Value = 0
    $lblStatus.Text = "Ready."
    Set-MenuState -IsRunning $false
}

# ==========================================
# 3. Main Functions
# ==========================================
function Start-InitialSetup {
    $tasks = @(
        @{
            Name = "Configure Disk Cleanup (cleanmgr)"
            Indeterminate = $true
            Action = {
                Show-ForegroundMessage -Message "Check ALL boxes and click OK." -Icon Information
                Start-Process "cleanmgr.exe" -ArgumentList "/sageset:1" -Wait
            }
        }
    )
    Invoke-TaskQueue -Tasks $tasks -ActiveButton $btnSetup
}

function Start-RepairPC {
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
    Invoke-TaskQueue -Tasks $tasks -CompletionMessage "Repair complete! A restart is recommended." -ActiveButton $btnRepair
}

function Start-CleanupPC {
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
                Start-Process "ms-settings:storagesense"
                Show-ForegroundMessage -Message "Click on: Temporary files -> Cleanup system files -> Confirm by selecting Yes -> Check ALL boxes -> Remove files -> Next. When finished, close the window." -Icon Information
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
            Action = { Clear-DnsClientCache -ErrorAction SilentlyContinue }
        },
        @{
            Name = "Clearing Microsoft Store Cache"
            Indeterminate = $false
            Action = {
                Start-Process "wsreset.exe" -WindowStyle Hidden
                Start-Sleep -Seconds 2
                Stop-Process -Name "WinStore.App" -Force -ErrorAction SilentlyContinue
            }
        },
        @{
            Name = "Clearing Windows Event Logs"
            Indeterminate = $false
            Action = {
                & wevtutil.exe el | ForEach-Object {
                    & wevtutil.exe cl "$_" 2>$null
                }
            }
        },
        @{
            Name = "Stopping & disabling Windows Search"
            Indeterminate = $false
            Action = {
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
                Start-Process "explorer.exe"
            }
        }
    )
    Invoke-TaskQueue -Tasks $tasks -CompletionMessage "Cleanup complete! A restart is recommended." -ActiveButton $btnClean
}

# --- Open README (Fullscreen) ---
function Show-Readme {
    Set-MenuState -IsRunning $true -ActiveButton $btnReadme

    $readmePath = Join-Path -Path $PSScriptRoot -ChildPath "README.txt"
    $content = if (Test-Path -LiteralPath $readmePath) {
        Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
    } else {
        "README.txt not found in:`r`n$PSScriptRoot"
    }

    $readmeForm = New-Object System.Windows.Forms.Form
    $readmeForm.Text = "README - System TuneUp by Felixplored"
    $readmeForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $readmeForm.StartPosition = "CenterParent"
    $readmeForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

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

    $readmeForm.Controls.Add($textBox)

    $readmeForm.Add_Shown({
        $textBox.Select(0, 0)
        [void]$readmeForm.Focus()
    })

    [void]$readmeForm.ShowDialog()
    Set-MenuState -IsRunning $false
}

# --- Exit ---
function Invoke-ExitPrompt {
    Set-MenuState -IsRunning $true -ActiveButton $btnExit

    $result = Show-ForegroundMessage -Message "Would you like to restart the system?" -Buttons YesNo -Icon Question -DefaultButton Button2

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process "shutdown.exe" -ArgumentList "/r /t 60"
    }
    
    # Closes the application in any case (whether Yes or No was clicked)
    $form.Close()
}

# ==========================================
# 4. Create User Interface (GUI)
# ==========================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "System TuneUp by Felixplored"
$form.Size = New-Object System.Drawing.Size(440, 485)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 32)
$form.ForeColor = [System.Drawing.Color]::White

$form.Add_Shown({
    $form.TopMost = $true
    [Win32]::SetForegroundWindow($form.Handle)
    $form.TopMost = $false
})

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "System TuneUp"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 255)
$lblTitle.AutoSize = $false
$lblTitle.Size = New-Object System.Drawing.Size(400, 35)
$lblTitle.Location = New-Object System.Drawing.Point(12, 18)
$lblTitle.TextAlign = "MiddleCenter"
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "by Felixplored | Ver.: v3.0.0"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSub.ForeColor = [System.Drawing.Color]::Silver
$lblSub.AutoSize = $false
$lblSub.Size = New-Object System.Drawing.Size(400, 22)
$lblSub.Location = New-Object System.Drawing.Point(12, 53)
$lblSub.TextAlign = "MiddleCenter"
$form.Controls.Add($lblSub)

function New-MenuButton {
    param([string]$Text, [int]$Y, [System.Drawing.Color]$BgColor)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point(45, $Y)
    $btn.Size = New-Object System.Drawing.Size(335, 42)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
    $btn.BackColor = $BgColor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

$btnBg     = [System.Drawing.Color]::FromArgb(45, 45, 52)
$btnExitBg = [System.Drawing.Color]::FromArgb(140, 45, 45)

$btnSetup  = New-MenuButton -Text "Initial Setup" -Y 95  -BgColor $btnBg
$btnRepair = New-MenuButton -Text "Repair PC"     -Y 147 -BgColor $btnBg
$btnClean  = New-MenuButton -Text "Cleanup PC"    -Y 199 -BgColor $btnBg
$btnReadme = New-MenuButton -Text "Open README"   -Y 251 -BgColor $btnBg
$btnExit   = New-MenuButton -Text "Exit"          -Y 303 -BgColor $btnExitBg

$btnSetup.Add_Click({ Start-InitialSetup })
$btnRepair.Add_Click({ Start-RepairPC })
$btnClean.Add_Click({ Start-CleanupPC })
$btnReadme.Add_Click({ Show-Readme })
$btnExit.Add_Click({ Invoke-ExitPrompt })

$form.Controls.AddRange(@($btnSetup, $btnRepair, $btnClean, $btnReadme, $btnExit))

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblStatus.ForeColor = [System.Drawing.Color]::LightGray
$lblStatus.Location = New-Object System.Drawing.Point(45, 360)
$lblStatus.Size = New-Object System.Drawing.Size(335, 18)
$form.Controls.Add($lblStatus)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(45, 382)
$progressBar.Size = New-Object System.Drawing.Size(335, 18)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

$lblCopyright = New-Object System.Windows.Forms.Label
$lblCopyright.Text = "$([char]0x00A9) SystemTuneUp by Felixplored. All rights reserved."
$lblCopyright.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$lblCopyright.ForeColor = [System.Drawing.Color]::Gray
$lblCopyright.Location = New-Object System.Drawing.Point(45, 408)
$lblCopyright.Size = New-Object System.Drawing.Size(335, 18)
$lblCopyright.TextAlign = "MiddleCenter"
$form.Controls.Add($lblCopyright)

[void]$form.ShowDialog()