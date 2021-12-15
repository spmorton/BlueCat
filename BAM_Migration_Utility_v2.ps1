# Written by Scott P. Morton PhD
# 2/10/2021

<# Changes for 2.1.6 11/5/2021
removed static entries from migration
in DHCP scopes#>

<# Changes for 2.1.5 7/1/2021
Fixed deployment of role and 
cleanup any individual roles 
below the main IPV4Block#>

<# Changes for 2.1.3 3/11/2021
Corrected output of multib lock detection
to not present erroneously duplicate/alternate
entries
#>

<# Changes for 2.1.2 3/9/2021
Corrected output of multib lock detection
to present the target network and parent network
information
#>

<# Changes for 2.1.1 2/23/2021
Added retry buttons for authentication
Adjusted auth methods and variables
to support retry of auth
#>

<# Changes for 2.0.6 2/19/2021
Added completion notification for Deploy Roles
Added an exit routine
Corrected a push options issue with IP4Blocks
#>

<# Changes for 2.0.5 2/19/2021
Added more detail in multi block detection
Added try, catch block for deploy role
Added completion notification for Sync SN/Range
#>

<# Changes for 2.0.4 2/19/2021
Presented subnet info in multi block detection when
    should be presenting the parent block
#>
<# Changes for 2.0.3 2/18/2021
Corrected an issue deleting DHCP options
Corrected an issue with deploy options
Corrected an issue with multi block detection
Corrected issue with deploy roles
Added missing completion notifications
Corrected a spelling error on one of the popup messages
Corrected spelling and wording on Change comment
 #>

<# Changes for 2.0.2 2/18/2021
During reset, adjust selected server index for deployment to -1
    forcing a new selection on susequent reruns
 #>

<# Changes for 2.0.1 2/17/2021
After many complaints, added a reset button
Disabled 'Parent ID' field after gathering subnets
Adjusted 'Get_Options' to force all 'dns-server' entries 
    to be at the facility block level
Added multiple block detection for sites with more than 1 root block
Added removal of all deployment roles at each subnet, standard is to use the block
Enabled Deploy roles to deploy at the parent block level and let inheritance work
 #>


$global:version = "2.1.6";
$global:Src = "proteus.chs.net";
$global:Dst = "bam.chs.net";


$wsdlSrcPath = "https://$Src/Services/API?wsdl";
$wsdlDstPath = "http://$Dst/Services/API?wsdl";

# Connect to the API.
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Setup the Src connection
$SrcCookieContainer = New-Object System.Net.CookieContainer;
$SrcProxy = New-WebServiceProxy -uri $($wsdlSrcPath);
$SrcProxy.url = $wsdlSrcPath;
$SrcProxy.CookieContainer = $SrcCookieContainer;
# Setup the Dst connection
$DstCookieContainer = New-Object System.Net.CookieContainer;
$DstProxy = New-WebServiceProxy -uri $($wsdlDstPath);
$DstProxy.url = $wsdlDstPath;
$DstProxy.CookieContainer = $DstCookieContainer;


#load libraries
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null;
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null;

#instantiate GUI objects
$Authenticate = New-Object System.Windows.Forms.Button;
$SrcServerLabel = New-Object System.Windows.Forms.Label;
$DstServerLabel = New-Object System.Windows.Forms.Label;
$SrcDplySrvLabel = New-Object System.Windows.Forms.Label;
$GetSubnets = New-Object System.Windows.Forms.Button;
$SyncSubnets = New-Object System.Windows.Forms.Button;
$GetOptions = New-Object System.Windows.Forms.Button;
$PushOptions = New-Object System.Windows.Forms.Button;
$SaveSubnets = New-Object System.Windows.Forms.Button;
$SaveOptions = New-Object System.Windows.Forms.Button;
$SyncIPs = New-Object System.Windows.Forms.Button;
$ClearSplits = New-Object System.Windows.Forms.Button;
$ProcessOutputTxtBox = New-Object System.Windows.Forms.TextBox;
$ProcessOutputLabel = New-Object System.Windows.Forms.Label;
$Reset = New-Object System.Windows.Forms.Button;
$Quit = New-Object System.Windows.Forms.Button;
$AuthGBox = New-Object System.Windows.Forms.GroupBox
$Parent = New-Object System.Windows.Forms.TextBox;
$MuliBlockLabel = New-Object System.Windows.Forms.Label;
$DeployGBox = New-Object System.Windows.Forms.GroupBox
$srcRetry = New-Object System.Windows.Forms.Button;
$dstRetry = New-Object System.Windows.Forms.Button;


# old from here

$loadServersLabel = New-Object System.Windows.Forms.Label;
$loadServers = New-Object System.Windows.Forms.Button;
$deployRoles = New-Object System.Windows.Forms.Button;
$serverList = New-Object System.Windows.Forms.ComboBox;
$writeOutput = New-Object System.Windows.Forms.Button;


#global variables instantiation
$global:allServers = @();
$global:ParentID = $NULL;
$global:dstID = $NULL;
$global:subnetData = $NULL;
$global:SrcDeploymentServer = $NULL;
$global:nline = "`r`n";
$global:subnetList = $NULL;
$global:fullOptions = $NULL;


#build GUI
function Show-Window {
$BAMApp = New-Object System.Windows.Forms.Form;
$BAMApp.Text = "BAM Migration Utility - $version";
$BAMApp.Name = "BAMApp";
$BAMApp.ClientSize = New-Object System.Drawing.Size(700, 650);
$BAMApp.Add_Closing({param($sender,$e)
    $result = [System.Windows.Forms.MessageBox]::Show(`
        "Are you sure you want to exit?", `
        "Close", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes)
    {
        $e.Cancel= $true
    }
    Quit
})

$Authenticate.Name = "Authenticate";
$Authenticate.Size = New-Object System.Drawing.Size(120, 30);
$Authenticate.Text = "Authenticate";
$Authenticate.Location = New-Object System.Drawing.Point(10, 10);
$Authenticate.add_Click({AuthMe});

$srcRetry.name = "srcretrybutton";
$srcRetry.Text = "R";
$srcRetry.Size = New-Object System.Drawing.Size(20, 20);
$srcRetry.Location = New-Object System.Drawing.Point(150, 15);
$srcRetry.Enabled = $false;
$srcRetry.add_Click({
   try {
       $SrcProxy.login($script:cred.UserName, $script:cred.GetNetworkCredential().password);
       $SrcServerLabel.BackColor = [Drawing.Color]::LightGreen;
       $ProcessOutputTxtBox.AppendText("Source login successful $nline");
       $srcRetry.Enabled = $false;   
       $GetSubnets.Enabled = $true;
       $loadServers.Enabled = $true;
    }
   catch {
       $SrcServerLabel.BackColor = [Drawing.Color]::Red;       
       $ProcessOutputTxtBox.AppendText("Source login failed $nline");
       return;    
   }
  
})

$SrcServerLabel.Size = New-Object System.Drawing.Size(230, 15);
$SrcServerLabel.Text = "Source: $Src";
$SrcServerLabel.Location = New-Object System.Drawing.Point(170, 20);
$SrcServerLabel.BackColor = [Drawing.Color]::Yellow;
$SrcServerLabel.Name = "sourceserverlabel";


$dstRetry.name = "dstretrybutton";
$dstRetry.Text = "R";
$dstRetry.Size = New-Object System.Drawing.Size(20, 20);
$dstRetry.Location = New-Object System.Drawing.Point(430, 15);
$dstRetry.Enabled = $false;
$dstRetry.add_Click({
   try {
       $DstProxy.login($script:cred.UserName, $script:cred.GetNetworkCredential().password);
       $DstServerLabel.BackColor = [Drawing.Color]::LightGreen;
       $ProcessOutputTxtBox.AppendText("Source login successful $nline");
       $dstRetry.Enabled = $false;
       $GetSubnets.Enabled = $true;
       $loadServers.Enabled = $true;
    }
   catch {
       $DstServerLabel.BackColor = [Drawing.Color]::Red;       
       $ProcessOutputTxtBox.AppendText("Source login failed $nline");
       return;    
   }
  
})

$DstServerLabel.Size = New-Object System.Drawing.Size(230, 15);
$DstServerLabel.Text = "Destination: $Dst";
$DstServerLabel.Location = New-Object System.Drawing.Point(450, 20);
$DstServerLabel.BackColor = [Drawing.Color]::Yellow;
$DstServerLabel.Name = "destinationserverlabel";

$SrcDplySrvLabel.Size = New-Object System.Drawing.Size(235, 20);
$SrcDplySrvLabel.Text = "Source Deployment Server";
$SrcDplySrvLabel.Location = New-Object System.Drawing.Point(135, 70);
$SrcDplySrvLabel.Font = New-Object System.Drawing.Font("Lucida Console",10,[System.Drawing.FontStyle]::Regular);
$SrcDplySrvLabel.BackColor = [Drawing.Color]::LightSkyBlue;
$SrcDplySrvLabel.Name = "srcdeploymentserverlabel";

$AuthGBox.Controls.AddRange(@($Authenticate,$SrcServerLabel,$DstServerLabel,$srcRetry,$dstRetry));
$AuthGBox.Location = New-Object System.Drawing.Point(5,5);
$AuthGBox.Size = New-Object System.Drawing.Size(690,45);

$ProcessOutputLabel.Size = New-Object System.Drawing.Size(100, 20);
$ProcessOutputLabel.Text = "Process Output";
$ProcessOutputLabel.Location = New-Object System.Drawing.Point(5, 325);
$ProcessOutputLabel.Name = "processoutputlabel";

$ProcessOutputTxtBox.Multiline = $True
$ProcessOutputTxtBox.Size = New-Object System.Drawing.Size(690, 290);
$ProcessOutputTxtBox.Location = New-Object System.Drawing.Point(5, 340);
$ProcessOutputTxtBox.Scrollbars = "Vertical";
$ProcessOutputTxtBox.Name = "processoutput";

$Parent.Size = New-Object System.Drawing.Size(110, 25);
$Parent.Text = "Enter Parent ID";
$Parent.Location = New-Object System.Drawing.Point(15, 70);
$Parent.Name = "parentID";
$Parent.add_Click({
    $Parent.Text = ""
})


$GetSubnets.Size = New-Object System.Drawing.Size(110, 25);
$GetSubnets.Text = "Load Subnets";
$GetSubnets.Location = New-Object System.Drawing.Point(15, 105);
$GetSubnets.Name = "subnetlist";
$GetSubnets.Enabled = $false;
$GetSubnets.add_Click({LoadSubnets});

$MuliBlockLabel.Size = New-Object System.Drawing.Size(130, 25);
$MuliBlockLabel.Text = "Multi Block Site Detection";
$MuliBlockLabel.Location = New-Object System.Drawing.Point(260, 105);
$MuliBlockLabel.Font = New-Object System.Drawing.Font("Lucida Console",10,[System.Drawing.FontStyle]::Regular);
$MuliBlockLabel.BackColor = [Drawing.Color]::LightSkyBlue;
$MuliBlockLabel.Name = "multiblocklabel";

$SaveSubnets.Size = New-Object System.Drawing.Size(110, 25);
$SaveSubnets.Text = "Save Subnets";
$SaveSubnets.Location = New-Object System.Drawing.Point(135, 105);
$SaveSubnets.Name = "saveoptionslist";
$SaveSubnets.Enabled = $false;
$SaveSubnets.add_Click({Save_Subnets});

$SyncSubnets.Size = New-Object System.Drawing.Size(110, 25);
$SyncSubnets.Text = "Sync SN/Ranges";
$SyncSubnets.Location = New-Object System.Drawing.Point(15, 140);
$SyncSubnets.Name = "syncsubnets";
$SyncSubnets.Enabled = $false;
$SyncSubnets.BackColor = [Drawing.Color]::Red;
$SyncSubnets.add_Click({Sync_Subnets});

$GetOptions.Size = New-Object System.Drawing.Size(110, 25);
$GetOptions.Text = "Get Options";
$GetOptions.Location = New-Object System.Drawing.Point(15, 175);
$GetOptions.Name = "optionslist";
$GetOptions.Enabled = $false;
$GetOptions.add_Click({Get_Options});

$SaveOptions.Size = New-Object System.Drawing.Size(110, 25);
$SaveOptions.Text = "Save Options";
$SaveOptions.Location = New-Object System.Drawing.Point(135, 175);
$SaveOptions.Name = "saveoptionslist";
$SaveOptions.Enabled = $false;
$SaveOptions.add_Click({Save_Options});

$PushOptions.Size = New-Object System.Drawing.Size(110, 25);
$PushOptions.Text = "Push Options";
$PushOptions.Location = New-Object System.Drawing.Point(15, 210);
$PushOptions.Name = "pushoptionslist";
$PushOptions.Enabled = $false;
$PushOptions.add_Click({Push_Options});

$SyncIPs.Size = New-Object System.Drawing.Size(110, 25);
$SyncIPs.Text = "Sync IP Space";
$SyncIPs.Location = New-Object System.Drawing.Point(15, 245);
$SyncIPs.Name = "syncipspace";
$SyncIPs.Enabled = $false;
$SyncIPs.add_Click({Sync_IP_Space});

$ClearSplits.Size = New-Object System.Drawing.Size(110, 25);
$ClearSplits.Text = "Clear Scope Splits";
$ClearSplits.Location = New-Object System.Drawing.Point(15, 280);
$ClearSplits.Name = "clearscopesplits";
$ClearSplits.Enabled = $false;
$ClearSplits.add_Click({Clear_Splits});

$writeOutput.Size = New-Object System.Drawing.Size(110, 25);
$writeOutput.Text = "Save Output";
$writeOutput.Location = New-Object System.Drawing.Point(580, 305);
$writeOutput.Name = "saveoutput";
$writeOutput.add_Click({Write_Output});

$Reset.Size = New-Object System.Drawing.Size(110, 25);
$Reset.Text = "Reset";
$Reset.Location = New-Object System.Drawing.Point(460, 305);
$Reset.Name = "reset";
$Reset.add_Click({Init});


# old 

$DeployGBox.Controls.AddRange(@($loadServersLabel,$serverList,$loadServers,$deployRoles));
$DeployGBox.Location = New-Object System.Drawing.Point(375,165);
$DeployGBox.Size = New-Object System.Drawing.Size(310,100);

$loadServersLabel.Size = New-Object System.Drawing.Size(300, 20);
$loadServersLabel.Text = "Select only one of the deployement server pair";
$loadServersLabel.Location = New-Object System.Drawing.Point(380, 215);
$loadServersLabel.Name = "loadserverslabel";

$serverList.Size = New-Object System.Drawing.Size(300, 410);
$serverList.Name = "serverList";
$serverList.Text = "Please Load Servers";
$serverList.Location = New-Object System.Drawing.Point(380, 235);
$serverList.AllowDrop = $True;
$serverList.Enabled = $false;
$BAMApp.Controls.Add($serverList);
$serverList.Add_SelectedIndexChanged({Check_Selection})

$loadServers.Name = "LoadServers";
$loadServers.Size = New-Object System.Drawing.Size(110, 25);
$loadServers.Text = "Get BAM Servers";
$loadServers.Location = New-Object System.Drawing.Point(380, 175);
$loadServers.Enabled = $false;
$loadServers.add_Click({Load_Servers});

$deployRoles.Name = "deployRoles";
$deployRoles.Size = New-Object System.Drawing.Size(110, 25);
$deployRoles.Text = "Deploy Roles";
$deployRoles.Location = New-Object System.Drawing.Point(500, 175);
$deployRoles.add_Click({Deploy_Roles});
$deployRoles.Enabled = $false;




$BAMApp.Controls.Add($ProcessOutputTxtBox);
$BAMApp.Controls.Add($ProcessOutputLabel);
$BAMApp.Controls.Add($AuthGBox);
$BAMApp.Controls.Add($GetSubnets);
$BAMApp.Controls.Add($GetOptions);
$BAMApp.Controls.Add($PushOptions);
$BAMApp.Controls.Add($SaveOptions);
$BAMApp.Controls.Add($SaveSubnets);
$BAMApp.Controls.Add($SyncIPs);
$BAMApp.Controls.Add($ClearSplits);
$BAMApp.Controls.Add($writeOutput);
$BAMApp.Controls.Add($Parent);
$BAMApp.Controls.Add($SrcDplySrvLabel);
$BAMApp.Controls.Add($SyncSubnets);
$BAMApp.Controls.Add($Reset);
$BAMApp.Controls.Add($MuliBlockLabel);
$BAMApp.Controls.Add($loadServers);
$BAMApp.Controls.Add($loadServersLabel);
$BAMApp.Controls.Add($deployRoles);
$BAMApp.Controls.Add($DeployGBox);

$BAMApp.ShowDialog()| Out-Null;
}

function Init() {
    $global:allServers = @();
    $global:ParentID = $NULL;
    $global:subnetData = $NULL;
    $global:SrcDeploymentServer = $NULL;
    $global:subnetList = $NULL;
    $global:fullOptions = $NULL;
    
    $SrcDplySrvLabel.Text = "Source Deployment Server";
    $ProcessOutputTxtBox.Text = "";
    $Parent.Text = "Enter Parent ID";

    $MuliBlockLabel.Text = "Multi Block Site";
    $MuliBlockLabel.BackColor = [Drawing.Color]::LightSkyBlue;

    $Parent.Enabled = $true;
    $SaveSubnets.Enabled = $false;
    $SyncSubnets.Enabled = $false;
    $GetOptions.Enabled = $false;
    $SaveOptions.Enabled = $false;
    $PushOptions.Enabled = $false;
    $SyncIPs.Enabled = $false;
    $ClearSplits.Enabled = $false;
    $serverList.Enabled = $false;
    $loadServers.Enabled = $false;
    $deployRoles.Enabled = $false;

    $serverList.SelectedIndex = -1;


}

Function catProps($inf)
{
	# concatenate the properites back together if needed
	$newProps = $inf[0]
	for($i = 1; $i -lt $inf.Count; $i++){
		$newProps = $newProps + "|" + $inf[$i]
	}
	return $newProps
}

Function Get-IPrange
{
	<# 
	.SYNOPSIS  
	Get the IP addresses in a range 
	.EXAMPLE 
	Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
	.EXAMPLE 
	Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
	.EXAMPLE 
	Get-IPrange -ip 192.168.8.3 -cidr 24 
	#> 
 
param 
	( 
	[string]$start, 
	[string]$end, 
	[string]$ip, 
	[string]$mask, 
	[int]$cidr 
	) 
 
Function IP-toINT64 () { 
	param ($ip) 

	$octets = $ip.split(".") 
	return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
Function INT64-toIP() { 
	param ([int64]$int) 

	return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
	if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
	if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
	if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
	if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
	if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 

	if ($ip) { 
	$startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
	$endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
	} else { 
	$startaddr = IP-toINT64 -ip $start 
	$endaddr = IP-toINT64 -ip $end 
	} 


	for ($i = $startaddr; $i -le $endaddr; $i++) 
	{ 
	INT64-toIP -int $i 
	}

}

function Check_Selection{
    if ($serverList.Text -ne "" -and $serverList.Text -ne "Please Load Servers") {
        $thisServer = $serverList.SelectedItem.ToString();
        $ProcessOutputTxtBox.AppendText("Server selected for deployment - $thisServer $nline");
        $deployRoles.Enabled=$true;        
    }

}
function Sync_IP_Space{
    foreach($item in $global:subnetData)
    {
        try{
            # Loop through each line of the csv and get the object from BC
            $SrcNet = $SrcProxy.searchByObjectTypes($item.CIDR,'IP4Network',  0, 2000);
            if ($SrcNet.count -eq 0) {
                $ProcessOutputTxtBox.AppendText("INFO - Subnet $item.CIDR not an IP4Network $nline");
                continue
            }
            # get the dhcp range from this subnet
            # $SrcRange = $SrcProxy.getEntities($SrcNet[0].id, 'DHCP4Range', 0, 2000)
            $ProcessOutputTxtBox.AppendText("Processing subnet $item $nline");
            #Write-Host "For Source Range " $SrcRange.properties
        }
        catch{
            $ProcessOutputTxtBox.AppendText("ERROR - Source - failed to acquire Net for $item.CIDR $nline");
            continue
        }
        # If the subnet has a dhcp range get the list of IP's in this subnet
        # including everything that is assigned
        try{
            $Srciplist = $SrcProxy.getNetworkLinkedProperties($SrcNet[0].id)
        }
        catch{
            $ProcessOutputTxtBox.AppendText("ERROR - Source - failed to acquire Linked Objects for $($SrcNet.id) $($SrcNet.properties) $nline");
            continue
        }
        try{
            $DstNet = $DstProxy.searchByObjectTypes($item.CIDR,'IP4Network',  0, 2000)
        }
        catch{
            $ProcessOutputTxtBox.AppendText("ERROR - Destination - failed to acquire Net for $item.CIDR $nline");
            $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
            continue
        }
        # if I need to update some properties then i would makle the change and update the object
        #     $DstProxy.update($DstNet[0])
        
        #  $SrcSingleOpt = $SrcProxy.getDHCPClientDeploymentOption($SrcNet[0].id,'router',0)
        #  $SrcOpts = $SrcProxy.getDeploymentOptions($SrcNet[0].id,"",-1)
    
        # acquire the address space for the subnet invovled
        $Addresses = Get-IPrange -ip $item.CIDR.split('/')[0] -cidr $item.CIDR.split('/')[1]
        for($i = 20; $i -lt ($Addresses.count - 1); $i++){
            try{
                $destIPAddr = $DstProxy.getIP4Address($DstNet[0].id,$Addresses[$i])
            }
            catch{
                $ProcessOutputTxtBox.AppendText("ERROR - Dest - Failed to acquire IP Addr $Addresses[$i] $nline");
                $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
            }
            # if the ip address is not allocated/assigned/reserved, etc. the 'id' is '0' so skip it
            if($destIPAddr.id -eq 0){
                continue
            }
            try{
                $info = $destIPAddr.properties.Split('|')
                $a = (0..($info.count-1)) | Where-Object {$info[$_].contains('address')}
                $s = (0..($info.count-1)) | Where-Object {$info[$_].contains('state')}
                $m = (0..($info.count-1)) | Where-Object {$info[$_].contains('mac')}
                if($info[$s] -eq 'state=DHCP_ALLOCATED'){
                    $newmac = $($info[$m].Replace('macAddress=','')).Replace('-','')
                    $DstProxy.changeStateIP4Address($destIPAddr.id,"MAKE_DHCP_RESERVED",$newmac)
                }
            }
            catch{
                $ProcessOutputTxtBox.AppendText("ERROR - Dest - Failed to split properties or set state for IP $Addresses[$i] $nline");
                #$destIPAddr.GetType()
                $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
            }
            try{
                $DstProxy.deleteWithOptions($destIPAddr.id,'noServerUpdate=true')
            }
            catch{
                $ProcessOutputTxtBox.AppendText("ERROR - Dest - Failed to delete destination IP $Addresses[$i] during cleanup $nline");
                $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
            }
        }
        for($i = 0; $i -lt $Srciplist.Count; $i++){
            # Take the next linked item
            $thisAddr = $Srciplist[$i]
            $id = $thisAddr.id
            $props = $thisAddr.properties
            if($thisAddr.id -eq 0){
                $name = ''
                continue
            }
            # split the properties so they can be modified or used elsewhere
            try{
                $info = $thisAddr.properties.Split('|')
                $a = (0..($info.count-1)) | Where-Object {$info[$_].contains('address')}
                $s = (0..($info.count-1)) | Where-Object {$info[$_].contains('state')}
                $m = (0..($info.count-1)) | Where-Object {$info[$_].contains('mac')}
                $h = (0..($info.count-1)) | Where-Object {$info[$_].contains('host')}
            }
            catch{
                $ProcessOutputTxtBox.AppendText("ERROR - Src - Failed to split properties for $id - $props $nline");
                $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
            }
            if($Addresses.IndexOf($info[$a].split('=')[1]) -lt 20){
                # Force a blank name every chance you get 
                $name = ''
                continue
            }
            if($info.Count -gt 2){
                if($h -and $info[$h].Length -gt 0){
                    try{
                        $hostinfo = $($info[$h].split('{')[1]).split(':')
                        $name = $hostinfo[1] + '.' + $hostinfo[3]
                    }
                    catch{
                        $ProcessOutputTxtBox.AppendText("ERROR - Src - Failed to split host info for $id - $props $nline");
                        $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace)
                    }
                }
                else{
                    $name = ''	
                }
                try{
                    if($m){
                        $newmac = $($info[$m].Replace('macAddress=','')).Replace('-','')
                    }
                    else{
                        $newmac = ''
                    }
                }
                catch{
                    $ProcessOutputTxtBox.AppendText("ERROR - Src - Failed to produce reduced MAC Addr for $id - $props $nline");
                    $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
                }
            }
            else{
                $name = ''
            }
            #$destIPAddr = $DstProxy.getIP4Address($DstNet[0].id,$info[0].split('=')[1])
            # $DstProxy.deleteWithOptions($destIPAddr.id,'noServerUpdate=true')
            if($info[$s] -eq 'state=DHCP Reserved'){
                    try{
                        $DstProxy.assignIP4Address(860,$info[$a].Split('=')[1],$newmac,$name ,"MAKE_DHCP_RESERVED","name=$($name)")
                        $name = ''
                    }
                    catch{
                        $ProcessOutputTxtBox.AppendText("ERROR - Dst - Failed to MAKE_DHCP_RESERVED for Src $id - $props $nline");
                        $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
                    }
            }
            elseif($info[2] -eq 'state=STATIC'){
                $rng = $srcProxy.getIPRangedByIP($item.id,"DHCP4Range",$info[$a].Split('=')[1])
                if (-Not $rng.id){
                    try{
                        $DstProxy.assignIP4Address(860,$info[$a].Split('=')[1],$newmac,$name ,"MAKE_STATIC","name=$($name)")
                        $name = ''
                    }
                    catch{
                        $ProcessOutputTxtBox.AppendText("ERROR - Dst - $i Failed to MAKE_STATIC for Src $id - $props $nline");
                        $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
                    }
                }
            }
            elseif($info[2] -eq 'state=RESERVED'){
                try{
                    $DstProxy.assignIP4Address(860,$info[$a].Split('=')[1],$newmac,$name ,"MAKE_RESERVED","name=$($name)")
                    $name = ''
                }
                catch{
                    $ProcessOutputTxtBox.AppendText("ERROR - Dst - Failed to MAKE_RESERVED for Src $id - $props $nline");
                    $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
                }
            }
            $name = ''
        }
    }
    $ProcessOutputTxtBox.AppendText("Finished Address Space Sync $nline");
    $ClearSplits.Enabled=$true;
}

function Clear_Splits{
    foreach($item in $global:subnetData){
        try {
            $DstNet = $DstProxy.searchByObjectTypes($item.CIDR,'IP4Network',  0, 2000)
            $ProcessOutputTxtBox.AppendText("Processing subnet $item $nline");
        }
        catch {
            $ProcessOutputTxtBox.AppendText("ERROR - Failed to acquire network in 'Clear_Splits' for $nline $item $nline");
        }
        $DstRange = $DstProxy.getEntities($DstNet[0].id, 'DHCP4Range', 0, 2000)
        if ($DstRange.count -eq 0){
            continue
        }
#        $ProcessOutputTxtBox.AppendText("For Source Range $SrcRange.properties");
    
        if($DstRange.Count -eq 1){
            try{
                $iprange = $DstRange[0].properties.split('|')
                $s = $iprange[0].split('=')[1]
                $e = $iprange[1].split('=')[1]
                $DstProxy.resizeRange($DstRange.id,"$s-$e","load-balance-split=false")
            }
            catch{
                $ProcessOutputTxtBox.AppendText("ERROR - Destination - failed to clear load balanced split for $nline $item $nline");
                $ProcessOutputTxtBox.AppendText($_.ScriptStackTrace);
                continue
            }
        }
        else{
            $ProcessOutputTxtBox.AppendText("ERROR - Destination id $SrcNet[0].id with name $SrcNet[0].name - Does not contain a DHCP scope $nline");
        }
    }
    $ProcessOutputTxtBox.AppendText("Finished Clearing Range Splits $nline");
}
    
function Get_Options {
    #$options = @();
    $global:fullOptions = @();
    #$addition = @{"Subnet" = $subnet};
    #foreach ($entry in $global:subnetData) {
    $additionP = @{"Subnet" = $global:subnetData[0].CIDR};
    for ($i = 0; $i -lt $global:subnetData.Count; $i++){
        $tmp = @();
        $options = @();
        $subnet = $global:subnetData[$i].CIDR; #$entry.CIDR;
        $network = $global:SrcProxy.searchByObjectTypes($subnet,"IP4Network", 0, 9999);
        $range = $global:SrcProxy.getEntities($network.id, "DHCP4Range", 0, 9999);
        $ProcessOutputTxtBox.AppendText("Getting deployment options $subnet. $nline");
        $addition = @{"Subnet" = $subnet};

        if ($i -eq 0){
            try {
                $options += $global:SrcProxy.getDeploymentOptions($global:SrcDeploymentServer.id, "DHCPV4ClientOption", -1);
                $options += $global:SrcProxy.getDeploymentOptions($global:SrcDeploymentServer.id, "DHCPServiceOption", -1);
            }
            catch {
                $ProcessOutputTxtBox.AppendText("INFO - No deployment options found for deployment server $global:SrcDeploymentServer.id in $subnet. $nline");    
            }
        }
        try {
            $options += $global:SrcProxy.getDeploymentOptions($network.id, "DHCPV4ClientOption", -1);
            $options += $global:SrcProxy.getDeploymentOptions($network.id, "DHCPServiceOption", -1);
        } catch { 
            $ProcessOutputTxtBox.AppendText("INFO - No deployment options found for subnet $subnet. $nline");
        }
            # try {
                #$options += $global:wsp.getDeploymentOptions($range.id, "DHCPV4ClientOption", -1);
                #} catch { Write-Host "No options attached to range."; }
            foreach ($option in $options) {
                if ($option.properties.contains("inherited=true")) {
                    continue
                } elseif ($option.name -eq "wins-nbns-server" -or $option.name -eq "wins-nbt-node-type") {
                    continue
                } elseif ($option.name -eq "tftp-server-name") {
                    $option.name = "next-server";
                    $option.type = "DHCPService";
                } elseif ($option.name -eq "boot-file-name") {
                    $option.name = "filename";
                    $option.type = "DHCPService";
                } 
                if ($option.name -eq "dns-server") {
                    Add-Member -InputObject $option -NotePropertyMembers $additionP -PassThru;
                } else {
                    Add-Member -InputObject $option -NotePropertyMembers $addition -PassThru;
                }

                $tmp += $option;
            }
        $global:fullOptions += $tmp;
    }
    $ProcessOutputTxtBox.AppendText("INFO - Get options completed $nline");
    $SaveOptions.Enabled=$true;
    $PushOptions.Enabled=$true;
}

function Save_Options{
    $fileOut = New-Object system.windows.forms.savefiledialog;
    $fileOut.ShowDialog();
    $global:fullOptions | Select Subnet, id, name, properties, type, value | Export-CSV -Path $fileOut.FileName -NoTypeInformation;
}

function Save_Subnets{
    $fileOut = New-Object system.windows.forms.savefiledialog;
    $fileOut.ShowDialog();
    $global:subnetData | Export-CSV -Path $fileOut.FileName -NoTypeInformation;
}

function Write_Output{
    $fileOut = New-Object system.windows.forms.savefiledialog;
    $fileOut.ShowDialog();
    $ProcessOutputTxtBox.Text | Out-File -FilePath $fileOut.FileName
    }
function Push_Options{
    foreach ($entry in $global:subnetData) { # $global:fullOptions
        $CIDR = $entry.CIDR;
        $network = $global:DstProxy.searchByObjectTypes($CIDR,'IP4Network', 0, 9999);
        if ($network.Count -eq 0){
            $network = $global:DstProxy.searchByObjectTypes($CIDR,'IP4Block', 0, 9999);
            if ($network.Count -eq 0) {
                $ProcessOutputTxtBox.AppendText("ERROR - subnet $CIDR in $parentId - $name does not exist $nline");
                continue
            } else {
                $ProcessOutputTxtBox.AppendText("INFO - subnet $CIDR in $parentId - $name is an 'IP4Block' $nline");
            }
        }
        try {
            $options = $global:DstProxy.getDeploymentOptions($network.id, "DHCPV4ClientOption", -1);
            $options += $global:DstProxy.getDeploymentOptions($network.id, "DHCPServiceOption", -1);
        }
        catch {
            $ProcessOutputTxtBox.AppendText("INFO - Destination - No deployment options to cleanup for $CIDR. $nline");    
        }
        foreach ($option in $options) {
            if ($option.properties.contains("inherited=true")) {
                continue;
            }
            $type = $option.type;
            $name = $option.name;
            $id = $option.id
            $ProcessOutputTxtBox.AppendText("Deleting option $id - $name - $type $nline");
            $global:DstProxy.delete($id);   
            #if ($options.type -eq "DHCPClient") {
            #    $global:DstProxy.deleteDHCPClientDeploymentOption($id,$name,0);   
            #} elseif ($options.type -eq "DHCPService") {
            #    $global:DstProxy.deleteDHCPServiceDeploymentOption(($id,$name,0);                
        }

        $parentId = $network.id

        foreach ($o in $global:fullOptions){
            if ($o.Subnet -eq $CIDR){
                $name = $o.name;
                $properties = $o.properties;
                #remove superfluous properties
                if ($properties.Contains("server=")) {
                    $splitProps = $properties.split("|");
                    foreach ($element in $splitProps) {
                        if ($element.Contains("server")) {
                            $properties = $properties.Replace($element + "|", '');
                        }
                    }
                }
                $type = $o.type;
                $value = $o.value;
        
                if ($type.equals("DHCPClient")) {
                    try {
                        $global:DstProxy.addDHCPClientDeploymentOption($parentId, $name, $value, $properties);
                        $ProcessOutputTxtBox.AppendText("SUCCESS $CIDR - $parentId - $name - Processed $nline");
                    }
                    catch {
                        $ProcessOutputTxtBox.AppendText("ERROR - DHCPClient option '$name', possible duplicate entry $nline")                        
                    }
                } elseif($type.equals("DHCPService")) {
                    try {
                        $global:DstProxy.addDHCPServiceDeploymentOption($parentId, $name, $value, $properties);
                        $ProcessOutputTxtBox.AppendText("SUCCESS $CIDR - $parentId - $name - Processed $nline");
                    }
                    catch {
                        $ProcessOutputTxtBox.AppendText("ERROR - DHCPService option '$name', possible duplicate entry $nline")                        
                    }
                }
        
            }
        }
    }
    $SyncIPs.Enabled=$true;
    $ProcessOutputTxtBox.AppendText("INFO - Push options completed $nline")
    #$ClearSplits.Enabled=$true;
}

function LoadSubnets {
    $global:subnetList = @();
    $global:subnetData = @();

    if ($Parent.Text -eq "" -or $Parent.Text -eq "Enter Parent ID") {
        [System.Windows.Forms.Messagebox]::Show("Please enter the 'object ID' of the parent IP Block for the site to be migrated");
        return
    }
    $p = $global:SrcProxy.getEntityById($Parent.Text);
    if ($p.id -eq 0){
        [System.Windows.Forms.Messagebox]::Show("The ID entered is not valid, Please enter the 'Object ID' of the parent IP Block for the site to be migrated");
        return
    }
    $global:ParentID = $Parent.Text;
    $Parent.Enabled = $false;
    $global:subnetList += $p;
    $global:subnetList += $global:SrcProxy.getEntities($global:ParentID,"IP4Network",0,9999);

    $global:subnetData = ReturnSubnetData($global:subnetList);

    $ProcessOutputTxtBox.AppendText("$nline $nline Subnets Loaded $nline $nline");
    foreach ($item in $global:subnetData) {
        $net = $item.CIDR
        $ProcessOutputTxtBox.AppendText("$net $nline");
    #    Write-Host $item.subnet;
    }
    Get_Src_Deploy_Srvs;
    Multi_Block_Check;
    $SaveSubnets.Enabled=$true;
    $SyncSubnets.Enabled=$true;
    $serverList.Enabled = $true;
    $ProcessOutputTxtBox.AppendText("INFO - Subnet detection completed $nline");

}

function Multi_Block_Check() {
    # returns the deployment roles assigned to the source deployment server by ID
    $roles = $global:SrcProxy.getServerDeploymentRoles($global:SrcDeploymentServer.id);
    $flag = 0;
    $nets = @()
    $blockinfo = @{}
    foreach ($role in $roles) {
        if ($role.entityId -eq $global:ParentID){
            continue
        }
        $thisParent = $global:SrcProxy.getParent($role.entityId)
        if ($thisParent.id -ne $global:ParentID) {
            $flag = 1;
            $netinfo = $global:SrcProxy.getEntityById($role.entityId);
            if (-Not $blockinfo.Contains($thisParent.id) -and -Not $blockinfo.Contains($netinfo.id)) {
                $blockinfo.Add($thisParent.id,$thisParent)
            }
        }
    }
    if ($flag -eq 0) {
        $MuliBlockLabel.BackColor = [Drawing.Color]::LightGreen;
        $ProcessOutputTxtBox.AppendText("INFO - No extra Blocks detected $nline");
    } else {
        $MuliBlockLabel.BackColor = [Drawing.Color]::OrangeRed;
        $ProcessOutputTxtBox.AppendText("ERROR - site assigned multiple IP4Blocks, Other Blocks are:$nline");
        foreach ($key in $blockinfo.Keys) {
            $i = $blockinfo.Item($key)
            $j = ReturnSubnetData($i)
            $ProcessOutputTxtBox.AppendText("    ObjectID - $($j.id) , $($j.CIDR) , $($j.name) $nline");
        }
        $a = "This site has been assigned multiple IP4Blocks. $nline";
        $b = "Check the output box for the networks detected and run the tool"
        $c = " on those blocks before migrating DHCP helper addresses. $nline"
        $d = "Additionally, make sure the network resource fully understands what is happening before continuing."
        [System.Windows.Forms.Messagebox]::Show("$a$b$c$d");
    }
    # returns the object the role is assigned to by entityId probably not needed
    # $global:SrcProxy.getEntityById(10116272);
    # use getParent to confirm which block it is under
    
}

function ReturnSubnetData($raw){
    $data = @();
    foreach ($item in $raw) {
        if ($item -eq $NULL){
            continue
        }
        $row = "" | Select id,name,CIDR
    
        $props = $item.properties.split('|');
        $row.id = $item.id;
        $row.name = $item.name;
        foreach ($p in $props) {
            if ($p.Contains("CIDR")){
                $row.CIDR = $p.split("=")[1];
                break;
            }
        }
        $data += $row;
    }
    return $data

}

function Get_Src_Deploy_Srvs(){
    foreach ($item in $global:subnetData) {
        $d = $global:SrcProxy.getDeploymentRoles($item.id);
        if ($d[0].service -eq "DHCP" -and $d[0].type -eq "MASTER"){
            $id = $d[0].id;
            $global:SrcDeploymentServer = $global:SrcProxy.getServerForRole($id);
            $SrcDplySrvLabel.Text = $global:SrcDeploymentServer.name;
            break
        }    
    }
    $ProcessOutputTxtBox.AppendText("INFO - Source deployment server detected $($SrcDplySrvLabel.Text) $nline");
}

#get list of servers from BAM
function Get_Servers {
    $allServers = $global:DstProxy.getEntities(860, "Server", 0, 10000);
    foreach ($currentServer in $allServers) {
        $name = $currentServer.name;
        #populate list of servers
        if ($name.Contains("corp") -or $name.Contains("ipam")) {
            $global:allServers += $currentServer;
        }
    }
    $i = $global:allServers.Count
    $ProcessOutputTxtBox.AppendText("$nline INFO - $i potential deployment servers loaded $nline");
    #export server list to CSV file for subsequent uses
    #$global:allServers | Select id, name, properties | Export-CSV -Path C:\servers.csv -NoTypeInformation;
}

#load list of servers from BAM
function Load_Servers {
     Get_Servers;
     #$serverList.Text = $global:allServers[0].name;
     foreach ($server in $global:allServers) {
        $serverList.Items.Add($server.name)| Out-Null;
     }
     #$deployRoles.Enabled = $true;
}


# FIXME - deploy to parent object
#deploy roles to selected server
function Deploy_Roles {
    $selectedServer = $serverList.Text;
    #set correct server names based on selection
    if ($selectedServer.Contains("ipam01")) {
    $server1 = $selectedServer
    $server2 = $selectedServer.Replace("ipam01", "ipam02");
    } elseif ($selectedServer.Contains("ipam02")) {
    $server2 = $selectedServer;
    $server1 = $selectedServer.Replace("ipam02", "ipam01");
    } elseif ($selectedServer.Contains("dhcp01")) {
    $server1 = $selectedServer
    $server2 = $selectedServer.Replace("dhcp01", "dhcp02");
    } elseif ($selectedServer.Contains("dhcp02")) {
    $server2 = $selectedServer;
    $server1 = $selectedServer.Replace("dhcp02", "dhcp01");
    }
    $selection = $global:allServers | ? {$_.name -eq $server1 };
    $selection2 = $global:allServers | ? {$_.name -eq $server2 };
    $interface = $global:DstProxy.getEntities($selection.id, "NetworkServerInterface", 0 , 10);
    $interface2 = $global:DstProxy.getEntities($selection2.id, "NetworkServerInterface", 0, 10);
    $int2id = $interface2.id;
    try {
        $global:DstProxy.addDHCPDeploymentRole($global:dstID, $interface.id, "MASTER", "secondaryServerInterfaceId="+$int2id);
        $ProcessOutputTxtBox.AppendText("INFO - Deployed role to Object $global:dstID with servers $server1 and $server2 $nline");
    }
    catch {
        $ProcessOutputTxtBox.AppendText("ERROR - failed to deploy role, check for an existing entry $nline");
    }
    #deploy servers
    #$global:DstProxy.deployServer($selection.id);
    #$global:DstProxy.deployServer($selection2.id);
}

function Sync_Subnets{
    $dstB = $global:DstProxy.searchByObjectTypes($global:subnetData[0].CIDR,"IP4Block",0,1);
    $global:dstID = $dstB.id;

    for ($i = 1; $i -lt $global:subnetData.Count; $i++) {
        $subnet = $global:subnetData[$i].CIDR;
        $ProcessOutputTxtBox.AppendText("Checking subnet $subnet $nline");
        $network = $global:DstProxy.searchByObjectTypes($subnet,'IP4Network', 0, 9999);
        if ($network.Count -eq 0){
            $props = $global:subnetList[$i].properties;
            try {
                $global:DstProxy.addIP4Network($global:dstID,$subnet,$props);
                $network = $global:DstProxy.searchByObjectTypes($subnet,'IP4Network', 0, 9999);
                $ProcessOutputTxtBox.AppendText("Created subnet $subnet $nline");
            }
            catch {
                $ProcessOutputTxtBox.AppendText("ERROR - failed to created subnet $subnet $nline");
                continue
            }
        }
        $SrcRange = $SrcProxy.getEntities($global:subnetData[$i].id, 'DHCP4Range', 0, 2000)
        if ($SrcRange.Count -eq 0) {
            continue
        }
        # Clean up any deployment roles below the block level
        try {
            $drole = $DstProxy.getEntities($network.id,"DHCPDeploymentRole",0,100)
            if($drole.length) {
                $DstProxy.delete($drole.id)
            }
        }
        catch {
            
        }
        $SrcProp = $SrcRange.properties.split('|');
        $DstRange = $DstProxy.getEntities($network.id, 'DHCP4Range', 0, 2000)
        $DstProp = $DstRange.properties.split('|');
        if ($DstRange.count -eq 0) {
            try {
                $s = $SrcProp[0].split("=")[1]
                $e = $SrcProp[1].split("=")[1]
                $global:DstProxy.addDHCP4Range($network.id,$s,$e,$SrcRange.name);
                $DstRange = $DstProxy.getEntities($network.id, 'DHCP4Range', 0, 2000)
                $ProcessOutputTxtBox.AppendText("Created DHCP range for subnet $subnet $nline");
            }
            catch {
                $ProcessOutputTxtBox.AppendText("ERROR - failed to created Range for $subnet $nline");         
            }
        } elseif ($DstProp[0] -ne $SrcProp[0] -or $DstProp[1] -ne $SrcProp[1]) {
            try {
                $global:DstProxy.delete($DstRange.id)
            }
            catch {
                $n = $DstRange.id;
                $ProcessOutputTxtBox.AppendText("ERROR - failed to delete DHCP Range ID $n with starting address $DstProp[0] $nline");
            }
            try {
                $s = $SrcProp[0].split("=")[1]
                $e = $SrcProp[1].split("=")[1]
                $global:DstProxy.addDHCP4Range($network.id,$s,$e,$SrcRange.name);
                $DstRange = $DstProxy.getEntities($network.id, 'DHCP4Range', 0, 2000)
                $ProcessOutputTxtBox.AppendText("RE- Created DHCP range for subnet $subnet $nline");
            }
            catch {
                $ProcessOutputTxtBox.AppendText("ERROR - failed to created Range for $subnet $nline");         
            }
        }
        $network = $global:DstProxy.getEntityByCIDR($global:dstID,$subnet,'IP4Network');
        $srcnetwork = $global:SrcProxy.searchByObjectTypes($subnet,'IP4Network', 0, 9999);
        $name = $srcnetwork.name;
        $network.name = $name;
        $global:DstProxy.update($network);
    }
    $dstsubnetList = $global:DstProxy.getEntities($global:dstID,"IP4Network",0,9999)
    $dstSNData = ReturnSubnetData($dstsubnetList);
    if ($dstsubnetList.Count -eq $global:subnetList.Count - 1) {
        $SyncSubnets.BackColor = [Drawing.Color]::LightGreen;
    } else {
        $SyncSubnets.BackColor = [Drawing.Color]::Yellow;
    }
    $GetOptions.Enabled=$true;
    $ProcessOutputTxtBox.AppendText("INFO - Sync SN/Ranges completed $nline");
}
function AuthMe {
    $SrcProxy.logout;
    $DstProxy.logout;
    $script:cred = Get-Credential;
    # Login to both systems
    try {
        $SrcProxy.login($script:cred.UserName, $script:cred.GetNetworkCredential().password);
        $SrcServerLabel.BackColor = [Drawing.Color]::LightGreen;
        $ProcessOutputTxtBox.AppendText("Source login successful $nline");     
    }
    catch {
        $SrcServerLabel.BackColor = [Drawing.Color]::Red;       
        $ProcessOutputTxtBox.AppendText("Source login failed $nline");
        $srcRetry.Enabled = $true;
        return;    
    }
    try {
        $DstProxy.login($script:cred.UserName, $script:cred.GetNetworkCredential().password);
        $DstServerLabel.BackColor = [Drawing.Color]::LightGreen;       
        $ProcessOutputTxtBox.AppendText("Destination login successful $nline");     
    }
    catch {
        $DstServerLabel.BackColor = [Drawing.Color]::Red;       
        $ProcessOutputTxtBox.AppendText("Destination login failed $nline");
        $dstRetry.Enabled = $true;
        return;
    }
    $GetSubnets.Enabled = $true;
    $loadServers.Enabled = $true;
}

function Quit() {
    Write-Host ("Logging off systems $nline")
    $global:SrcProxy.logout()
    $global:SrcProxy.logout()
}
#show GUI
Show-Window;

