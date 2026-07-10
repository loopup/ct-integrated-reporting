# Parameters
Param
(
    [Parameter(Mandatory = $true)] [string] $luClientId,
    [Parameter(Mandatory = $true)] [string] $luClientSecret,
    [Parameter(Mandatory = $true)] [string] $luCustomerId,
    [Parameter(Mandatory = $false)] [string] $filterOVRP,
    [Parameter(Mandatory = $false)] [string] $identityEndpointUrl = "https://identity.loopup.com",
    [Parameter(Mandatory = $false)] [string] $ddiEndpointUrl = "https://ctda.loopup.com"
)

# Teams DDI data
Write-Host "Getting DDIs from Teams"

# Filter server-side so only enterprise voice users with a number are downloaded, rather than every user in the tenant
$evUserFilter = 'EnterpriseVoiceEnabled -eq $true -and LineUri -ne $null'
try {
   if ((Get-Command Get-CsOnlineUser).Parameters.ContainsKey('Properties')) {
      $enterpriseVoiceUsers = Get-CsOnlineUser -Filter $evUserFilter -Properties "LineUri, OnlineVoiceRoutingPolicy"
   } else {
      $enterpriseVoiceUsers = Get-CsOnlineUser -Filter $evUserFilter
   }
} catch {
   # Older MicrosoftTeams modules may reject the server-side filter
   Write-Host "Server-side filtering unavailable, falling back to client-side filtering"
   $enterpriseVoiceUsers = Get-CsOnlineUser | Where-Object {
      $_.EnterpriseVoiceEnabled -like '*True*'
   }
}

if (-not ($filterOVRP -eq "N/A" -or $filterOVRP -eq "")) {
   $enterpriseVoiceUsers = $enterpriseVoiceUsers | Where-Object {
      $_.OnlineVoiceRoutingPolicy -like "*$filterOVRP*"
   }
}

$billingData = $enterpriseVoiceUsers | Where-Object {
   $_.LineUri -notlike ''
   } | Select-Object @{
      Name='ddi'; Expression={$_.LineURI.ToLower().replace("tel:","")}
   }, @{
      Name='onlineVoiceRoutingPolicy'; Expression={$_.OnlineVoiceRoutingPolicy}}

# LoopUp Authentication
Write-Host "Authenticating LoopUp client ID & Secret"
try {
   $identityBody = @{
       client_id = "$luClientId"
       client_secret = "$luClientSecret"
       grant_type = "client_credentials"
       scope = "ddi_activation"
   }
   $identityResponse = Invoke-RestMethod -Method Post -Uri $identityEndpointUrl/connect/token -Body $identityBody -ContentType "application/x-www-form-urlencoded"
   $identityToken = $identityResponse.Access_Token
} catch {
   Write-Error -Message "Failed to generate authentication token" -Exception $_.Exception
   exit 1
}

# Convert DDI data to Json
Write-Host "Generating DDI request"
$ddiBody = ConvertTo-Json $billingData -Depth 1
Write-Output "DDI request: $ddiBody"

# Send DDI data to LoopUp
Write-Host "Sending DDI data to LoopUp"
try {
   $headers = @{
      Authorization="Bearer $identityToken"
   }
   $ddiResponse = Invoke-RestMethod -Method Post -Uri $ddiEndpointUrl/v1/customers/$luCustomerId/teams-ddi-activation-determination -Body $ddiBody -ContentType "application/json" -Headers $headers
   Write-Host "Complete"
} catch {
   Write-Error -Message "Failed to submit ddi data" -Exception $_.Exception
   exit 1
}

