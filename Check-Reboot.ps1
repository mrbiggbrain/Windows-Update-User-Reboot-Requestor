# ----------------------------------------------------------------------------------------
# Copyright (c) 2024 Nicholas Young
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 if (Get-Item C:\REBOOT-ME.txt -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($null -ne $status) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}

$Running = Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%check-reboot.ps1%'"
if($Running.count -gt 1)
{
  Write-host "Already Running"
  exit
}

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
$monitor = [System.Windows.Forms.Screen]::PrimaryScreen
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Restart Required"
$Form.Width = 450
$Form.Height = 200
$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$Form.Left = $monitor.WorkingArea.Width - $Form.Width
$Form.Top = $monitor.WorkingArea.Height - $Form.Height
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
$Form.ShowInTaskbar = $false
# $Form.BackColor = [System.Drawing.Color]::Red
$Form.TopMost = $true
$Form.ControlBox = $false

# Create Label
$Header = New-Object System.Windows.Forms.Label
$Header.AutoSize = $true 
$Header.Text = "Restart Required"
$Header.Font = New-Object System.Drawing.Font("Times New Roman",18)
$Header.AutoSize = $false
$Header.TextAlign = "MiddleCenter"
#$Header.Dock = "Fill"
$Header.Height = 30
$Header.Width = 420
$Header.Top = 10

# Create Line
$Line = New-Object System.Windows.Forms.Label
$Line.Text = ""
$Line.BorderStyle = "Fixed3D"
$Line.AutoSize = $false
$Line.Height = 2
$Line.Width = 450
$Line.Top = 40

# Create Message
$Message = New-Object System.Windows.Forms.Label
$Message.Text = "Your Computer needs to be restarted to install updates.`n`nPlease Click 'Restart Now' to restart, or use the 'Pause' button to hide this window for a set period of time"
$Message.AutoSize = $false
$Message.Font = New-Object System.Drawing.Font("Times New Roman",10)
$Message.Height = 100
$Message.Width = 430
$Message.Top = 50
$Message.Left = 10

# Create Button
$RestartButton = New-Object System.Windows.Forms.Button
$RestartButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
$RestartButton.Text = "Restart Now"
$RestartButton.AutoSize = $true
$RestartButton.Left = 20
$RestartButton.Top = 120
$RestartButton.Height = 30
$RestartButton.Width = 195

# Create Button
$DelayButton = New-Object System.Windows.Forms.Button
$DelayButton.DialogResult = [System.Windows.Forms.DialogResult]::Ignore
$DelayButton.Text = "Pause 60 Minutes"
$DelayButton.AutoSize = $true
$DelayButton.Left = 225
$DelayButton.Top = 120
$DelayButton.Height = 30
$DelayButton.Width = 195

# Add Elements
$Form.Controls.Add($Header)
$Form.Controls.Add($RestartButton)
$Form.Controls.Add($DelayButton)
$Form.Controls.Add($Message)
$Form.Controls.Add($Line)

$RebootTime = 60
while($true)
{
  $Pending = Test-PendingReboot

  while ($Pending)
  {
    $Results = $Form.ShowDialog()

    if($Results -eq "Yes")
    {
      Remove-Item -Path C:\REBOOT-ME.txt
      shutdown /f /r /t 0
    }
    elseif($Results -eq "Ignore")
    {
      Start-Sleep -Seconds ($RebootTime * 60)

      if($RebootTime -gt 15)
      {
        $RebootTime = $RebootTime / 2
      }
      elseif($RebootTime -eq 15)
      {
        $RebootTime = 5
      }

      $DelayButton.Text = "Pause $($RebootTime) Minutes"
    }
  }

  Start-Sleep -Seconds 3600

}

$Form.Close() 