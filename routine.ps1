
foreach($item in $csvList)
{
	try{
		# Loop through each line of the csv and get the object from BC
		$SrcNet = $SrcProxy.searchByObjectTypes($item.Subnet,'IP4Network',  0, 2000)
		# get the dhcp range from this subnet
		$SrcRange = $SrcProxy.getEntities($SrcNet[0].id, 'DHCP4Range', 0, 2000)
	}
	catch{
		Write-Host "Source - failed to acquire Net/Range for `n $item"
		continue
	}
	# If the subnet has a dhcp range get the list of IP's in this subnet
	# including everything that is assigned
	if($SrcRange.Count -eq 1){
		try{
			$Srciplist = $SrcProxy.getNetworkLinkedProperties($SrcNet[0].id)
		}
		catch{
			Write-Host "Source - failed to acquire Linked Objects for `n $SrcNet[0]`n"
			continue
		}
		try{
			$DstNet = $DstProxy.searchByObjectTypes($item.Subnet,'IP4Network',  0, 2000)
			$DstRange = $DstProxy.getEntities($DstNet[0].id, 'DHCP4Range', 0, 2000)
		}
		catch{
			Write-Host "Destination - failed to acquire Net/Range for `n $item`n"
			Write-Host $_.ScriptStackTrace
			continue
		}
		# if I need to update some properties then i would makle the change and update the object
		#     $DstProxy.update($DstNet[0])
		
		#  $SrcSingleOpt = $SrcProxy.getDHCPClientDeploymentOption($SrcNet[0].id,'router',0)
		#  $SrcOpts = $SrcProxy.getDeploymentOptions($SrcNet[0].id,"",-1)
	
		if($DstRange.Count -eq 1){
			# acquire the address space for the subnet invovled
			$Addresses = Get-IPrange -ip $item.Subnet.split('/')[0] -cidr $item.Subnet.split('/')[1]
			for($i = 20; $i -lt ($Addresses.count - 1); $i++){
				try{
					$destIPAddr = $DstProxy.getIP4Address($DstNet[0].id,$Addresses[$i])
				}
				catch{
					Write-Host "Dest - Failed to acquire IP Addr `n $Addresses[i]`n"
					Write-Host $_.ScriptStackTrace
				}
				# if the ip address is not allocated/assigned/reserved, etc. the 'id' is '0' so skip it
				if($destIPAddr.id -eq 0){
					continue
				}
				try{
					$info = $destIPAddr.properties.Split('|')
					$a = (0..($info.count-1)) | where {$info[$_].contains('address')}
					$s = (0..($info.count-1)) | where {$info[$_].contains('state')}
					$m = (0..($info.count-1)) | where {$info[$_].contains('mac')}
					if($info[$s] -eq 'state=DHCP_ALLOCATED'){
						$newmac = $($info[$m].Replace('macAddress=','')).Replace('-','')
						$DstProxy.changeStateIP4Address($destIPAddr.id,"MAKE_DHCP_RESERVED",$newmac)
					}
				}
				catch{
					Write-Host "Dest - Failed to split properties for IP `n$destIPAddr `n"
					$destIPAddr.GetType()
					Write-Host $_.ScriptStackTrace
				}
				try{
					$DstProxy.deleteWithOptions($destIPAddr.id,'noServerUpdate=true')
				}
				catch{
					Write-Host "Dest - Failed to delete destination IP`n $destIPAddr `nduring cleanup `n"
					Write-Host $_.ScriptStackTrace
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
					$a = (0..($info.count-1)) | where {$info[$_].contains('address')}
					$s = (0..($info.count-1)) | where {$info[$_].contains('state')}
					$m = (0..($info.count-1)) | where {$info[$_].contains('mac')}
					$h = (0..($info.count-1)) | where {$info[$_].contains('host')}
				}
				catch{
					Write-Host "Src - Failed to split properties for `n  $id - $props`n"
					Write-Host $_.ScriptStackTrace
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
							Write-Host "Src - Failed to split host info for `n $id - $props`n"
							Write-Host $_.ScriptStackTrace
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
						Write-Host "Src - Failed to produce reduced MAC Addr for `n  $id - $props `n"
						Write-Host $_.ScriptStackTrace
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
							Write-Host "Dst - Failed to MAKE_DHCP_RESERVED for Src `n  $id - $props`n"
							Write-Host $_.ScriptStackTrace
						}
				}
				elseif($info[2] -eq 'state=STATIC'){
					try{
						$DstProxy.assignIP4Address(860,$info[$a].Split('=')[1],$newmac,$name ,"MAKE_STATIC","name=$($name)")
						$name = ''
					}
					catch{
						Write-Host "Dst - $i Failed to MAKE_STATIC for Src `n  $id - $props`n"
						Write-Host $_.ScriptStackTrace
					}
				}
				elseif($info[2] -eq 'state=RESERVED'){
					try{
						$DstProxy.assignIP4Address(860,$info[$a].Split('=')[1],$newmac,$name ,"MAKE_RESERVED","name=$($name)")
						$name = ''
					}
					catch{
						Write-Host "Dst - Failed to MAKE_RESERVED for Src `n  $id - $props`n"
						Write-Host $_.ScriptStackTrace
					}
				}
				$name = ''
			}
		}
		else{
			Write-Host "Destination id" $SrcNet[0].id "with name" $SrcNet[0].name " - Does not contain a DHCP scope"
		}
			
	}
	else{
		Write-Host "Source id" $SrcNet[0].id "with name" $SrcNet[0].name " - Does not contain a DHCP scope"
	}
}


