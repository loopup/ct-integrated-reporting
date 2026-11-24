#Automation Account Variables
$luClientId = Get-AutomationVariable -Name "LoopUpClientId"
$luClientSecret = Get-AutomationVariable -Name "LoopUpClientSecret"
$luCustomerId = Get-AutomationVariable -Name "LoopUpCustomerId"
$filterOVRP = Get-AutomationVariable -Name "filterOVRP"

# TeamsEnvironmentName selects the Microsoft cloud (Commercial, TeamsGCCH, TeamsDOD).
# The variable does not exist on automation accounts deployed before GCC High/DoD support was added, so default to Commercial.
try {
    $teamsEnvironmentName = Get-AutomationVariable -Name "TeamsEnvironmentName" -ErrorAction Stop
} catch {
    $teamsEnvironmentName = ""
}

#Teams PowerShell Authentication
$credentials = Get-AutomationPSCredential -Name 'LoopUpServiceAccountCredentials'
if ($teamsEnvironmentName -and $teamsEnvironmentName -ne "Commercial") {
    Connect-MicrosoftTeams -Credential $credentials -TeamsEnvironmentName $teamsEnvironmentName
} else {
    Connect-MicrosoftTeams -Credential $credentials
}

# Download script from GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/loopup/ct-integrated-reporting/main/scripts/Common/SelfHostedDdiConfigurationReporting.ps1" -OutFile "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1"

# Run script
& "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1" $luClientId $luClientSecret $luCustomerId $filterOVRP

# Tidy up
Remove-Item "$PSScriptRoot\SelfHostedDdiConfigurationReporting.ps1"