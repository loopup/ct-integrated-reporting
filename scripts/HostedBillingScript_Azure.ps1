#LoopUp Endpoint URL
$endpointUrl = "https://prod-166.westus.logic.azure.com:443/workflows/7c0497e062234ff2ae617fd21231e89b/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=1eveUH7pqDXn0lrY9dspfuMXBeTIwPgrMAynFPP-5Lo"

#Teams PowerShell Authentication
$credentials = Get-AutomationPSCredential -Name 'LoopUpServiceAccountCredentials'
Connect-MicrosoftTeams -Credential $credentials 

#Days in the month
$firstDaysInMonth = get-date -day 1 -Hour 0 -Minute 0 -Second 0
$lastDaysInMonth = get-date $firstDaysInMonth.AddMonths(1).AddSeconds(-1)
$daysInMonth = ($lastDaysInMonth-$firstDaysInMonth).Days + 1

#Pro Rata
$proRata = "1"

#Tenant OnMicrosoft Domain
$tenantVerifiedDomain = (Get-CsTenant).DisplayName

#Automation Account Variables
$filterOVRP = Get-AutomationVariable -Name "filterOVRP"

#filterOVRP
if ($filterOVRP -eq "N/A") {
    $billingData = Get-CsOnlineUser | where-object {$_.EnterpriseVoiceEnabled -like '*True*' -and ($_.LineUri -notlike '')} | Select-Object @{Name='LineUri'; Expression={$_.LineURI.ToLower().replace("tel:+","")}}, OnlineVoiceRoutingPolicy, @{Name='TenantName'; Expression = {$tenantVerifiedDomain}}, @{Name='DaysInMonth'; Expression = {$daysInMonth}}, @{Name='ProRata'; Expression = {$proRata}}
}else {
    $billingData = Get-CsOnlineUser | where-object {$_.EnterpriseVoiceEnabled -like '*True*' -and ($_.OnlineVoiceRoutingPolicy -like "*$filterOVRP*")} | Select-Object @{Name='LineUri'; Expression={$_.LineURI.ToLower().replace("tel:+","")}}, OnlineVoiceRoutingPolicy, @{Name='TenantName'; Expression = {$tenantVerifiedDomain}}, @{Name='DaysInMonth'; Expression = {$daysInMonth}}, @{Name='ProRata'; Expression = {$proRata}}            
}

#Convert data to Json
$output = ConvertTo-Json $billingData -Depth 1

#Send data to endpoint url
Invoke-RestMethod -Method Post -Uri $endpointUrl -Body $output -ContentType application/json

#Output
Write-Output $output

