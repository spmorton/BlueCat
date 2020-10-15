# BEGIN access Section

#$prodPath = "https://10.5.176.232/Services/API?wsdl"
$prodPath = "http://proteus.chs.net/Services/API?wsdl"

# Connect to the API and authenticate.
$CookieContainer = New-Object System.Net.CookieContainer
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$Prod = New-WebServiceProxy -uri $($prodPath)
$Prod.url = $prodPath
$Prod.CookieContainer = $CookieContainer

#!!!!!!! Begin Login 
# user must be api enabled

#Production
$cred = Get-Credential
$Prod.login($cred.UserName, $cred.GetNetworkCredential().password)


# Test
<#$apiUsername = "api-admin"
$apiPassword = "admin"
$Prod.login($apiUsername, $apiPassword)
#>
# END access Section


# Get the file containing the domain list
$fd = New-Object system.windows.forms.openfiledialog
$fd.showdialog()
$fd.filename


# Setup the data
$newRecords = @()
$newRecords = Import-Csv -Path $fd.FileName


# Find all the old SPF records and delete them
#$data = $prod.searchByObjectTypes("spf", "TXTRecord", 0, 10000)
#$data += $prod.searchByObjectTypes("spf", "GenericRecord", 0, 10000)

#Write-Host "Exporting deletion list to c:\temp\deletedlist.csv"
#$data | Export-Csv -Path "c:\temp\createdlist2.csv" -NoTypeInformation


#foreach ($child in $data)
#{
#    $view = $Prod.getParent($child.id)
#    while ($view.type -ne "View")
#    {
#        $view = $Prod.getParent($view.id)        
#    }
#
#    if ($view.Name -eq "External")
#    {
#        Write-Host "Deleting -" $child
#        $Prod.delete($child.id)
#    }
#}

$spfData = "v=spf1 mx ptr ip4:204.227.128.69 -all"


foreach ($child2 in $newRecords)
{
    Write-Host "Adding -" $child2.name
    $Prod.addTXTRecord(6284,$child2.DomainName,$spfData,7200,"")
}





