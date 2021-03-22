Import-Module ActiveDirectory

<# Listing all DC in the forest by their name #>
function Get-AllDCsInForest{
[CmdletBinding()]
param(
    [string]$ReferenceDomain = $env:USERDOMAIN
)
 
$ForestObj = Get-ADForest -Server $ReferenceDomain
foreach($Domain in $ForestObj.Domains) {
    Get-ADDomainController -Filter * -Server $Domain | select Name
     
}
 
}
<# Create an empty array #>
$targets = @() 

<# Test the connection to each DC, if alive add is added in the array, otherwise print status #>
foreach($dc in ($allDCCs= @(Get-AllDCsInForest)))
{
    if(Test-Connection -BufferSize 32 -Count 1 -ComputerName $dc.Name -Quiet)
    {
        $targets += $dc
    }
    else
    {
        Write-Host $dc.Name " is Offline"
}
}

<# For each alive DC get the list of Log Analytics Workspace IDs #>
foreach($target in $targets){
$target
Invoke-Command -ScriptBlock {

$AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg 

try
			{
              $OMSWorkSpaces=$AgentCfg.GetCloudWorkspaces()
              foreach($OMSWorkSpace in $OMSWorkSpaces)
			  {
                $OMSList=$OMSWorkspace.workspaceId + ", "
              }
              $OMSList=$OMSList.TrimEnd(", ")
            }
            catch
			{
              $OMSList=''
            }
      <# Compare the Workspace ID with the Workspace ID you are looking for #>
      $OMSList.Contains('00000000-0000-0000-0000-000000000000') 

} -ComputerName $target.Name
}

