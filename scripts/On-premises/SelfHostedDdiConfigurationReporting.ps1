# Parameters
Param
(
    [Parameter(Mandatory = $true)] [string] $luServiceAccountUsername,
    [Parameter(Mandatory = $true)] [string] $luClientId,
    [Parameter(Mandatory = $true)] [string] $luClientSecret,
    [Parameter(Mandatory = $true)] [string] $luCustomerId,
    [Parameter(Mandatory = $false)] [string] $filterOVRP,
    [Parameter(Mandatory = $false)] [string] $teamsEnvironmentName
)

# Logging
$timestamp = Get-Date -Format "yyyyMMdd"
$logFilename = "C:\LoopUp\ddi_$timestamp.log"

# Start Logging
Start-Transcript -Path $logFilename

# Teams PowerShell Authentication
$User = "$luServiceAccountUsername"
$PWord = Get-Secret -Name LoopUpHostedBillingScript.connection
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
# teamsEnvironmentName selects the Microsoft cloud: TeamsGCCH for GCC High, TeamsDOD for DoD. Omit for Commercial/GCC.
if ($teamsEnvironmentName -and $teamsEnvironmentName -ne "Commercial") {
    Connect-MicrosoftTeams -Credential $credential -TeamsEnvironmentName $teamsEnvironmentName
} else {
    Connect-MicrosoftTeams -Credential $credential
}

# Download script from GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/loopup/ct-integrated-reporting/main/scripts/Common/SelfHostedDdiConfigurationReporting.ps1" -OutFile "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1"

# Run script
& "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1" $luClientId $luClientSecret $luCustomerId $filterOVRP

# Tidy up
Remove-Item "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1"

# Remove PS Session
Get-PSSession | Where-Object {$_.ComputerName -like "*api*"} | Remove-PSSession

# End Logging
Stop-Transcript