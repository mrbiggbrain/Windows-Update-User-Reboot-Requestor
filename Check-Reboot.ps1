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
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($null -ne $status) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
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
# SIG # Begin signature block
# MIIFwwYJKoZIhvcNAQcCoIIFtDCCBbACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD4EAOpiu3pEPnf
# 1SlXy3J49bzCN+sQAcOa3XZUSbjFa6CCAzMwggMvMIICF6ADAgECAhBkZclq7tAC
# lU0E/Xxpc6rbMA0GCSqGSIb3DQEBBQUAMCAxHjAcBgNVBAMMFU5ETSBDb2RlIFNp
# Z25pbmcgQ2VydDAeFw0yMzA3MjMxNjQ0MzBaFw0zMzA3MjMxNjU0MzBaMCAxHjAc
# BgNVBAMMFU5ETSBDb2RlIFNpZ25pbmcgQ2VydDCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAL9Hwyt8JhRaR9CqpOOdMJ6pSJnoEV0G4NvjA8PcEqhu7I8H
# Qg/hrw8bmha9sIv69SVeXi2vLWX/ofiw7aBujncUFvfuWqn4ZChwaEfGUXYU7m2B
# KBR2dcQiN2RuMBLgg/cGd3yxFRMIvirGeIfW2rWpR1g9ZeIOMF7YUP2VSJavb87b
# l/+f1p/aiCuXeCMkAV58xj10XaxWINgGNNNG0bZXVUuSxBMZCGq9oLVIrR4Lc3sO
# we0FQtI9XuZOgKtNJXrmCMkiHEkJyWdpOm34FQMr080Ic0R0+CXHgN8uY31YvxoD
# 7uiUO9WHiDOiqHhhjDTw5e+zFofW2LKHOxIPouUCAwEAAaNlMGMwDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdEQQWMBSCEm5kbWhvc3Bp
# dGFsaXR5LmNvbTAdBgNVHQ4EFgQUcocAPXMvpG3T/ifKpF/8CCZbTNwwDQYJKoZI
# hvcNAQEFBQADggEBALz/mRjKZ7mrlhSR6wnrZ38gCzMLQeXrg2wGMoy1Cc4R81oR
# OG6y60eUBVKkRkhXIEi4dgkLRW4+G5qUBRm9eDSES5aFjrjo8HlPxx+EtCXBy5kg
# uBjE87TqEHsVi2221j0LLqZOZcqaRXk+lYQAmaPPxKiRfnPdYpG1YQaFrOOXyjMH
# 5vcK6PXvtLSa39LO2sez3reQ9daRZkiknSHiZmXZLvl5wVWOQ6If0okb1X5kmZ1X
# LhKEKOijH2ucHmKroTO3wq8/PjOH7G9VVVylh+Q8Bw3vHnKMNL5vfLyffBR4gJJ3
# dQa3miqhLDKvr3Wy3NZEuM0Jav2T48guGSdrkPYxggHmMIIB4gIBATA0MCAxHjAc
# BgNVBAMMFU5ETSBDb2RlIFNpZ25pbmcgQ2VydAIQZGXJau7QApVNBP18aXOq2zAN
# BglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMC8GCSqGSIb3DQEJBDEiBCBoFArjqVMmzbm48Pe836xfuN2ztmLtcV/vSZPg
# Z8Dg5DANBgkqhkiG9w0BAQEFAASCAQCUAe492o83dH3N3gSa5ysoX6gYCnD/eLWV
# OV9/XlQlaQQ4VxYPqhr+hFVUyH/v/OFvJdeU0SwsEhMPHmDtNyzCcNJacO2fikrM
# RAS/eomZ4TsBgRwgYJngtajiUMpsoR/U2G4F3Big+2y88DT2KyVya4c+54nRDnk8
# 6YXUJWrzEINUw0uUC+fvuaBd4qI7WIKsoyAlizHvRnLSrWmA8qfWcwyCipEtf7ge
# CDgVrF6/CebVqmC4FB+BIQymc5ZZ+hpGRDJx4cF33403eEkJ6BUbj+95pekCmWgu
# 6avpObJQ8AFr0g4IyVt8rVYUViHTMU56Ns+hgc4k3B04F173V+gh
# SIG # End signature block
