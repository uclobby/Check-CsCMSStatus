
<#PSScriptInfo

.VERSION 1.1

.GUID ab4272c3-2180-4599-8c0f-dca557128393

.AUTHOR David Paulino

.COMPANYNAME UC Lobby

.COPYRIGHT

.TAGS Lync LyncServer SkypeForBusiness SfBServer SQL

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
  Version 1.0: 2019/10/09 - Initial release.
  Version 1.1: 2023/10/07 - Updated to publish in PowerShell Gallery.

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Run a SQL query to all Front Ends in a pool, if no pool is specified, it will use the current computer to check if belongs to a Lync/Skype for Business Front End Pool and execute a SQL query. 

#> 

[CmdletBinding()]
param(
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $PoolFqdn,
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $SQLInstance,
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $SQLDatabase,
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $SQLQuery,
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $SQLFile

    )

$startTime=Get-Date;

#Checking if the Lync/Skype for Business Module is available
if(!(Get-Module -ListAvailable -Name Lync,SkypeforBusiness)){
    Write-Warning "Could not find Lync/Skype for Business PowerShell Module."
    
    return
}

$ServerFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName

#If the PoolFQDN is missing we will try to use the current computer.
if($PoolFqdn){
    $ComputersInPool = (Get-CsComputer -Pool $PoolFqdn -ErrorAction SilentlyContinue)
    
} else {
    $ComputersInPool = (Get-CsComputer -Identity $ServerFqdn -ErrorAction SilentlyContinue)
    $PoolFqdn = $ComputersInPool.Pool
    $ComputersInPool = (Get-CsComputer -Pool $PoolFqdn -ErrorAction SilentlyContinue)
}

if($ComputersInPool){
    Write-Host "Pool FQDN:" $PoolFqdn -ForegroundColor Green
    Write-Host "SQL Instance:" $SQLInstance -ForegroundColor Cyan
    if($SQLDatabase){
        Write-Host "SQL Database:" $SQLDatabase -ForegroundColor Green
    }
    $SQLOutput = New-Object System.Collections.ArrayList


    #Push/Pop so avoid the SQLSERV "drive".
    Push-Location
    foreach($Computer in $ComputersInPool){
        try{
            $ServerInstance = $Computer.fqdn + "\" + $SQLInstance
            if($SQLFile) {
                if($SQLDatabase){
                   $SQLResult= Invoke-Sqlcmd -InputFile $SQLFile -ServerInstance $ServerInstance -Database $SQLDatabase -ErrorAction SilentlyContinue
                } else {
                   $SQLResult = Invoke-Sqlcmd -InputFile $SQLFile -ServerInstance $ServerInstance -ErrorAction SilentlyContinue
                } 
            } elseif ($SQLQuery){

                if($SQLDatabase){
                   $SQLResult= Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $ServerInstance -Database $SQLDatabase -ErrorAction SilentlyContinue
                } else {
                   $SQLResult = Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $ServerInstance -ErrorAction SilentlyContinue
                } 


            }
            
            if($SQLResult){
                $RSInfo = New-Object PSObject -Property @{FrontEnd       =  $Computer.fqdn }
                $SQLResult | Get-Member -MemberType Property | ForEach-Object {
                    $RSInfo | Add-Member -MemberType NoteProperty -Name $_.Name  -Value $SQLResult.psobject.properties[$_.Name].value
                }
                [void]$SQLOutput.Add($RSInfo)
            }

        } catch {
            Write-Warning "Failed to connect to: $ServerInstance"
        }
    }
    Pop-Location
    $endTime = Get-Date
    $totalTime= [math]::round(($endTime - $startTime).TotalSeconds,2)
    Write-Host "Date:" (Get-Date -format g) -ForegroundColor Yellow
    Write-Host "Execution time:" $totalTime "seconds" -ForegroundColor Cyan

    $SQLOutput
    
} else {
    Write-Warning "Invalid/unknown Pool FQDN."
}


