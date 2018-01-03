Function Get-OctopusEnvironmentMachines{
    Param(
        [string]$EnvironmentName, #"App1 DEV"
        [string]$APIKey, #API-XXXXXXXXXXXXXXXXXXXXXXXXX
        [string]$OctopusBaseURI #http://octopus
    )
    try{
        $environmentsJSON=Invoke-WebRequest -URI "$OctopusBaseURI/api/environments" -Header @{ "X-Octopus-ApiKey" = $apiKey } -Method GET;
    }catch{
        throw "Get-OctopusEnvironmentMachines: Failed to retrieve list of environments :: $_ "
    }
    $environments=$environmentsJSON.content|ConvertFrom-JSON;
    $environment=$($environments.items|?{$_.name.contains($EnvironmentName)})
    write-host "EnvironmentMachinesURI: $($environment.links.machines)"
    #Get array of environment machines 
    try{
        $environmentMachinesJSON=Invoke-WebRequest -URI "$OctopusBaseURI$($environment.links.machines)" -Header @{ "X-Octopus-ApiKey" = $apiKey } -Method GET;
    }catch{
        throw "Get-OctopusEnvironmentMachines: Failed to retrieve list of environment machines :: $_ "
    }
    $environmentMachines=$environmentMachinesJSON.content|ConvertFrom-JSON;
    if(($environmentMachines.Items -eq $null) -or ($environmentMachines.Items.count -lt 1)){
        return $false;
    }else{
        return ($environmentMachines.Items | %{$_ | select ID,Name})
    }
}

Function Set-OctopusTentacleDisabled{
    Param(
        [switch]$SetEnabled,
        [string][Parameter(Mandatory=$true)]$MachineID, #"Machines-40"
        [string]$APIKey, #API-XXXXXXXXXXXXXXXXXXXXXXXXX
        [string]$OctopusBaseURI, #http://octopus
        [switch]$DisableOctopusServer
    )
    try{
        $machineJSON=Invoke-WebRequest -URI "$OctopusBaseURI/api/machines/$MachineID/" -Header @{ "X-Octopus-ApiKey" = $apiKey } -Method GET;
    }catch{
        throw "Set-OctopusTentacleDisabled: Failed to find Tentacle ID: $MachineID :: $_ "
    }
    $machine=$machineJSON.content|ConvertFrom-JSON;
    #$machine=$($Machines.items|?{$_.id -eq $MachineID})
    
    #Do not disable the Octopus Server's deployment agent unless the override flag is in place
    if(($Machine.Name -eq "OctopusServer") -and ($DisableOctopusServer -eq $false)){return $null;}
    
    if($SetEnabled -eq $true){
        write-host "Set-OctopusTentacleDisabled: MachineID($MachineID) Set to ENABLED";
        if($machine.IsDisabled -ne $False){$machine.IsDisabled=$False;}
        else{return $true}
    }else{
        write-host "Set-OctopusTentacleDisabled: MachineID($MachineID) Set to DISABLED";
        if(($machine.IsDisabled -ne $null) -and ($machine.IsDisabled -ne $True)){$machine.IsDisabled=$True;}
        else{return $true;}
    }
    $bodyJson=($machine|ConvertTo-JSON);
    write-host "Set-OctopusTentacleDisabled: Posting changes to the MachineID to Octopus...";
    try{
        Invoke-WebRequest -URI "$OctopusBaseURI/api/machines/$($machine.id)" -Header @{ "X-Octopus-ApiKey" = $apiKey } -Method PUT -Body $bodyJson;
    }catch{
        throw "Set-OctopusTentacleDisabled: Failed to set the MachineID ($MachineID):: $_"
    }
}

$tentacleVmName = "New Test PT"
$apikey = "API-XXXXXXXXXXXXXXXXXXXXXXXXX"
$headers = @{"X-Octopus-ApiKey"=$apikey} 
$octopusurl = "http://cd.XXXXXXXXXXXXXXXXXXXXXXXXX.com/"


#Get List of Machines
$EMachines=Get-OctopusEnvironmentMachines -EnvironmentName "XXXXXXXXXXXXXXXXXXXXXXXXX" -APIKey $apikey -OctopusBaseURI $octopusurl
$vmfull
foreach($vm in $EMachines)
{
        $vmfullJson= Invoke-RestMethod ($octopusurl+"api/machines/"+$vm.Id) -Headers $headers -Method Get
        $roles = $vmfullJson.Roles
         Write-Host $vm.Name+"---"+ $roles
        if($roles -contains "XXXXXXXXXXXXXXXXXXXXXXXXX")
        {
        Write-Host $vm.Name
        Invoke-RestMethod ($octopusurl+"api/machines/"+$vm.Id) -Method Delete -Headers $headers

        }
       
}


#Disable the Machines
#$EMachines|%{Set-OctopusTentacleDisabled -MachineID ($_.id) -APIKey $apikey -OctopusBaseURI $octopusurl}
#Enable the Machines
#$EMachines|%{Set-OctopusTentacleDisabled -MachineID ($_.id) -APIKey $apikey -OctopusBaseURI $octopusurl -SetEnabled}
