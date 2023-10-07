<#
.DESCRIPTION
	This script checks the current CMS status on Primary and Backup pools.

.NOTES
  Version      	   		: 0.6
  Author    			: David Paulino 
  Info                  : TBD

#>
Push-Location
$ManServer = Get-CsManagementConnection
if ($ManServer.SqlInstance -eq $null){
    $SqlServer = $ManServer.SqlServer.ToString();
} else  {
    $SqlServer = $ManServer.SqlServer.ToString() + "\" + $ManServer.SqlInstance;
}    
$ConfStoreServer = (Get-CsConfigurationStoreLocation).BackEndServer

if($ConfStoreServer -eq $SqlServer){
    Write-Host "Management Connection and Configuration Store Location match:" $SqlServer -ForegroundColor Cyan
    try{
        $CMSDBs = Get-CsService -CentralManagementDatabase 
    } catch {
         Write-Host "Failed to get the details from Central Management Database!" -ForegroundColor Red
    }
    foreach($CMSDB in $CMSDBs){
        Write-Host "Checking the current value for:"$CMSDB.PoolFqdn -ForegroundColor Yellow
        if($CMSDB.SqlInstanceName -eq "") {
            $SQLInstance = $CMSDB.PoolFqdn.ToString() 
        } else {
            $SQLInstance = $CMSDB.PoolFqdn.ToString() + "\" + $CMSDB.SqlInstanceName
        }
        try{
            $SQLRes = Invoke-Sqlcmd -query "SELECT [Value] FROM [xds].[dbo].[DbConfigInt] WHERE [Name] = 'CurrentState'" -ServerInstance $SQLInstance -ErrorAction Stop    
            if($ManServer.SqlServer.ToString() -eq $CMSDB.PoolFqdn){
                $CMSValue = 0;
            } else {
                $CMSValue = 3;
            }
            if($SQLRes.Value -eq $CMSValue){
                Write-Host $SQLInstance "- has the correct value:" $SQLRes.Value -ForegroundColor Green
            } else {
                Write-Host $SQLInstance "- has the wrong value:" $SQLRes.Value -ForegroundColor Red
            }
        } 
        Catch {
            Write-Host "Failed to connect to:" $SQLInstance  -ForegroundColor Red
        }
    }
} else {
    Write-Host "Mismatch between the Management Connection and Configuration Store Location" -ForegroundColor Red
}
Pop-Location