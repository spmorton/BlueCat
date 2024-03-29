

#$cred = Get-Credential



$jb = {
	param($creds)
	function test()
	{
		write "test"
		$script:test1 = "testing"
	}
	$creds.UserName.split('\')[1]
	$creds.GetNetworkCredential().password
	test
	$script:test1
	#$wsdlP.login($creds.username.split('\')[1], $creds.GetNetworkCredential().password)
	#$wsdlP.searchByCategory("10.5.4", "all", 0, 50)
}

#Start-Job -Name myJob -ScriptBlock $jb -Arg $cred
#Start-Job -Name myJob -FilePath 'c:\scripts\Proteus Suite\test2.ps1' -ArgumentList $cred
#Receive-Job myJob -Wait
#Remove-Job myJob
#$TotalTime = 60 #in seconds
<#
$buttonStart_Click={
	$buttonStart.Enabled = $false
	#Add TotalTime to current time
	$script:StartTime = (Get-Date).AddSeconds($TotalTime)
	#Start the timer
	$timerUpdate.Start()
}

$timerUpdate_Tick={
	#Use Get-Date for Time Accuracy
	[TimeSpan]$span = $script:StartTime - (Get-Date)
	
	#Update the display
	$formSampleTimer.Text = $labelTime.Text = "{0:N0}" -f $span.TotalSeconds
	
	if($span.TotalSeconds -le 0)
	{
		$timerUpdate.Stop()
	}
}
#>
# BEGIN view

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Job testing"
$objForm.MinimumSize = New-Object System.Drawing.Size(440,600)
$objForm.MaximumSize = New-Object System.Drawing.Size(440,600)
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {runit}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(20,545)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(100,545)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)


$GoButton = New-Object System.Windows.Forms.Button
$GoButton.Location = New-Object System.Drawing.Size(10,345)
$GoButton.Size = New-Object System.Drawing.Size(75,23)
$GoButton.Text = "Go"
$GoButton.Add_Click({runit})
$objForm.Controls.Add($GoButton)

$outPut = New-Object system.Windows.Forms.TextBox
$outPut.Location = New-Object System.Drawing.Size(20, 100)
$outPut.Size = New-Object System.Drawing.Size(400,3000)
$outPut.Multiline = $true
$outPut.Height = 240
$outPut.Text = "Process Output"
$outPut.HorizontalScrollbar = $true
$objForm.Controls.Add($outPut)


$objForm.Top = $True

$timer = new-object timers.timer 

$objForm.Add_Shown({$objForm.Activate()})
Form_Controls "DNS"
$prts = $objForm.ShowDialog()





$parameters = @{
	Name = "nuget"
	SourceLocation = "https://onegetcdn.azureedge.net/providers/nuget-2.8.5.208.package.swidtag"
	PublishLocation = "https://onegetcdn.azureedge.net/providers/nuget-2.8.5.208.package.swidtag/Packages"
	InstallationPolicy = 'Trusted'
  }
  Register-PSRepository @parameters
  Get-PSRepository