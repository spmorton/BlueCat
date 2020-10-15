[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.drawing

. ($PSScriptRoot + "User-Object-Tool.ps1")

$ADTVersion = 1.1

# form objects
$Form1 = New-Object System.Windows.Forms.Form 
$Tabcontrol1 =  New-Object System.Windows.Forms.TabControl
$userObjTab = New-Object System.Windows.Forms.TabPage
$computerObjTab = New-Object System.Windows.Forms.TabPage
$Server = New-Object System.Windows.Forms.TextBox
$Server_Label = New-Object System.Windows.Forms.Label
$CredsButton = New-Object System.Windows.Forms.Button
$CurrentCreds_Check = New-Object System.Windows.Forms.CheckBox

$ModifyButton = New-Object System.Windows.Forms.Button

$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

# form specs
$Form1.Text = "AD Tools - " + $ADTVersion
$Form1.Name = "adtools"
$Form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 725
$System_Drawing_Size.Height = 750
$Form1.ClientSize = $System_Drawing_Size

# tab control specs
$Tabcontrol1.Name = "tabControl"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 75
$System_Drawing_Point.Y = 85
$Tabcontrol1.Location = $System_Drawing_Point
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 600
$System_Drawing_Size.Width = 575
$Tabcontrol1.Size = $System_Drawing_Size
$Form1.Controls.Add($Tabcontrol1)


$userObjTab.AutoSize = $true
$userObjTab.TabIndex = 0
$userObjTab.Text = "User Objects"
$userObjTab.Enabled = $true
$Tabcontrol1.Controls.Add($userObjTab)

$computerObjTab.AutoSize = $true
$computerObjTab.TabIndex = 1
$computerObjTab.Text = "Computer Objects"
$computerObjTab.Enabled = $false
$Tabcontrol1.Controls.Add($computerObjTab)

$Server.Location = New-Object System.Drawing.Size(80,35)
$Server.Size = New-Object System.Drawing.Size(270,25)
$Server.Text = ""
$Form1.Controls.Add($Server)

$Server_Label.Location = New-Object System.Drawing.Size(80,16) 
$Server_Label.Size = New-Object System.Drawing.Size(270,20) 
$Server_Label.Text = "Server Name or IP address to query"
$Form1.Controls.Add($Server_Label) 

$CredsButton.Location = New-Object System.Drawing.Size(360,35)
$CredsButton.Size = New-Object System.Drawing.Size(100,20)
$CredsButton.Text = "Get Credentials"
$CredsButton.Enabled = $true
$CredsButton.Add_Click({
    $script:creds = Get-Credential
    $ScanButton.Enabled = $true
    })
$Form1.Controls.Add($CredsButton)

$CurrentCreds_Check.Location = New-Object System.Drawing.Size(470,35)
$CurrentCreds_Check.Size = New-Object System.Drawing.Size(120,20)
$CurrentCreds_Check.Text = "Use Current Creds"
$CurrentCreds_Check.Add_CheckStateChanged({
    
    if ($CurrentCreds_Check.Checked)
    {
        $CredsButton.Enabled = $false
        $ScanButton.Enabled = $true
    }
    else
    {
        $CredsButton.Enabled = $true
        $ScanButton.Enabled = $false
    }
})
$Form1.Controls.Add($CurrentCreds_Check)







$ModifyButton.Location = New-Object System.Drawing.Size(10,475)
$ModifyButton.Size = New-Object System.Drawing.Size(140,25)
$ModifyButton.Text = "Perform Operation"
$ModifyButton.Enabled = $true
$ModifyButton.Add_Click({Perform_Operation})
$userObjTab.Controls.Add($ModifyButton)

[void]$Form1.ShowDialog()