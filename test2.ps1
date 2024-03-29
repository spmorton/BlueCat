param($cred1)

$cred1.UserName.split('\')[1]
$cred1.GetNetworkCredential().password
	
function DoWork
{
  $event = Register-EngineEvent -SourceIdentifier NewMessage -Action {
      global:DisplayMessage $event.MessageData
  }

  $scriptBlock =  {

    Register-EngineEvent -SourceIdentifier NewMessage -Forward

    $message = "Starting work $args"
    $null = New-Event -SourceIdentifier NewMessage -MessageData $message

    ### DO SOME WORK HERE ###

    $message = "Ending work $args"
    $null = New-Event -SourceIdentifier NewMessage -MessageData $message

    Unregister-Event -SourceIdentifier NewMessage
  }

  DisplayMessage("Processing Starts")

  $array = @(1,2,3)
  foreach ($a in $array)
  {
      Start-Job -Name "DoActualWork" $ScriptBlock -ArgumentList $a | Out-Null
  }

  #$jobs = Get-Job -Name "DoActualWork"
  While (Get-Job -Name "DoActualWork" | where { $_.State -eq "Running" } )
  {
      Start-Sleep 1
  }

  DisplayMessage("Processing Ends")

  #Get-Job -Name "DoActualWork" | Receive-Job
}

function global:DisplayMessage([string]$message)
{
    Write-Host $message -ForegroundColor Red
}

DoWork

Get-EventSubscriber | Unregister-Event


foreach ($iss in $xx)
{
	$iss.properties.Split
	}
