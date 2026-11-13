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
   $propertiesParameter = (Get-Command Get-CsOnlineUser).Parameters['Properties']
   if ($propertiesParameter) {
      # Pass the property names in the shape this module version's -Properties parameter expects
      $properties = @('LineUri', 'OnlineVoiceRoutingPolicy')
      if (-not $propertiesParameter.ParameterType.IsArray) {
         $properties = $properties -join ','
      }
      $enterpriseVoiceUsers = Get-CsOnlineUser -Filter $evUserFilter -Properties $properties -ErrorAction Stop
   } else {
      $enterpriseVoiceUsers = Get-CsOnlineUser -Filter $evUserFilter -ErrorAction Stop
   }
} catch {
   # Older MicrosoftTeams modules may reject the server-side filter
   Write-Host "Server-side filtering unavailable, falling back to client-side filtering"
   $enterpriseVoiceUsers = Get-CsOnlineUser | Where-Object {
      $_.EnterpriseVoiceEnabled -like '*True*'
   }
}
$enterpriseVoiceUserCount = @($enterpriseVoiceUsers).Count

if (-not ($filterOVRP -eq "N/A" -or $filterOVRP -eq "")) {
   $enterpriseVoiceUsers = $enterpriseVoiceUsers | Where-Object {
      $_.OnlineVoiceRoutingPolicy -like "*$filterOVRP*"
   }
}

# Always an array, even for zero or one user, so the request body is a JSON array
$billingData = @($enterpriseVoiceUsers | Where-Object {
   $_.LineUri -notlike ''
} | ForEach-Object {
   [pscustomobject]@{
      ddi = ([string]$_.LineUri).ToLower().Replace("tel:", "")
      onlineVoiceRoutingPolicy = if ($_.OnlineVoiceRoutingPolicy) { [string]$_.OnlineVoiceRoutingPolicy } else { $null }
   }
})

Write-Host "Found $enterpriseVoiceUserCount enterprise voice users, $($billingData.Count) with a DDI to report"
if ($billingData.Count -eq 0) {
   Write-Error -Message "No DDIs found to report. $enterpriseVoiceUserCount enterprise voice users were returned by Teams (OVRP filter: '$filterOVRP'). Check the Teams connection is to the correct tenant and cloud, and that users have a LineUri assigned."
   exit 1
}

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
$ddiBody = ConvertTo-Json -InputObject $billingData -Depth 2
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
   # Include the API's response body; Invoke-RestMethod otherwise only reports the status line
   $responseDetails = $_.ErrorDetails.Message
   Write-Error -Message "Failed to submit ddi data: $($_.Exception.Message) $responseDetails" -Exception $_.Exception
   exit 1
}
