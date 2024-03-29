param(
	$wsdlPath,
	$cred,
	[long]$config_id,
	[long]$DNSView_id = -100,
	$csvList
	)

# Setup event handler to forward messages to parent process
Register-EngineEvent -SourceIdentifier Proteus-Messages -Forward

# BEGIN access Section

# Connect to the API
$CookieContainer = New-Object System.Net.CookieContainer
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$wsdlProxy = New-WebServiceProxy -uri $($wsdlPath)
$wsdlProxy.url = $wsdlPath
$wsdlProxy.CookieContainer = $CookieContainer

#!!!!!!! Begin Login 
# user must be api enabled

$wsdlProxy.login($cred.UserName.split('\')[1], $cred.GetNetworkCredential().password)

# END access Section

$null = New-Event -SourceIdentifier Proteus-Messages -MessageData $message

Function Assign_IP4()
{	
	foreach ($item in $script:csvList)
	{
		
		$wsdlProxy.assignIP4Address($script:config_id,$item.ipAddress,$item.deviceMac, $item.deviceName,"MAKE_DHCP_RESERVED","name=$($item.deviceName)")
		[System.Windows.Forms.Application]::DoEvents()
		if ($DNSView_id -ne -100)
		{
			$wsdlProxy.addHostRecord($script:DNSView_id, $item.deviceName, $item.ipAddress, 900, "")
		}
	}
}


