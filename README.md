<!-- ai-summary:start -->
## AI Summary
**Kind:** automation
**Language:** PowerShell
**Runtime:** PowerShell 5.1+ / Azure Automation

This repository contains PowerShell automation scripts that collect Microsoft Teams DDI (Direct Dial-In) configuration data from a customer's tenant and report it to the LoopUp Cloud Telephony platform for hosted billing and DDI activation determination. The domain is Cloud Telephony (CT) integrated reporting, bridging Microsoft Teams voice configuration with LoopUp's back-end customer management APIs. Scripts communicate outbound over HTTPS REST to two LoopUp services: the identity service (`identity.loopup.com`) for OAuth2 client-credentials authentication, and the CT DDI activation API (`ctda.loopup.com`) to submit DDI data. The repo ships two deployment variants — an Azure Automation runbook (with a one-click ARM template deploy) and an on-premises Windows Scheduled Task — sharing a common core script downloaded at runtime from GitHub. Both variants support the Microsoft Commercial/GCC clouds and the US Government clouds (GCC High and DoD) via a `TeamsEnvironmentName` setting. Key technologies are PowerShell, Microsoft Teams PowerShell module, Azure Automation Accounts, and Azure Resource Manager (ARM) templates.
<!-- ai-summary:end -->

<!-- ai-loopup-dependencies:start -->
## LoopUp Dependencies
### Services Called
| Service | Protocol | Purpose |
|---------|----------|---------|
| `identity.loopup.com` | HTTPS REST (POST `/connect/token`) | OAuth2 client-credentials token issuance |
| `ctda.loopup.com` | HTTPS REST (POST `/v1/customers/{customerId}/teams-ddi-activation-determination`) | Submit Teams DDI list for hosted billing / activation determination |

### NuGet/npm Packages
| Package | Version |
|---------|--------|
| MicrosoftTeams (PowerShell module) | 7.8.0 (Azure deployment) |

### Infrastructure
- EventStoreDB: no
- SQL Server: no
- Azure Service Bus/RabbitMQ: no
<!-- ai-loopup-dependencies:end -->

<!-- ai-inputs-outputs:start -->
## Inputs & Outputs
### Inputs
| Type | Name/Route | Description |
|------|-----------|-------------|
| Automation credential | `LoopUpServiceAccountCredentials` | Azure Automation credential asset that stores the Microsoft Teams service account username/password used by the runbook via `Get-AutomationPSCredential`. |
| Automation variable | `LoopUpClientId` | LoopUp API client ID retrieved with `Get-AutomationVariable` in Azure Automation and passed as a parameter when running the on-premises script. |
| Automation variable | `LoopUpClientSecret` | LoopUp API client secret sourced from an Automation variable (or parameterized in the on-premises task) before requesting an OAuth2 token. |
| Automation variable | `LoopUpCustomerId` | LoopUp customer identifier stored as an Automation variable and forwarded to the common script. |
| Automation variable (optional) | `filterOVRP` | Optional OnlineVoiceRoutingPolicy filter kept as an Automation variable and supplied to the common script (also accepted as an optional parameter on-premises). |
| Automation variable (optional) | `TeamsEnvironmentName` | Microsoft cloud hosting the Teams tenant: `Commercial` (default, also used for GCC), `TeamsGCCH` (GCC High) or `TeamsDOD` (DoD). Passed to `Connect-MicrosoftTeams -TeamsEnvironmentName`; also accepted as an optional `-teamsEnvironmentName` parameter on-premises. |
| SecretManagement secret | `LoopUpHostedBillingScript.connection` | On-premises deployment retrieves the Teams password from this SecretManagement vault entry via `Get-Secret` prior to `Connect-MicrosoftTeams`. |
| Parameter (on-premises only) | `luServiceAccountUsername` | Username passed to the on-premises scheduled task; Azure Automation instead reads it from the credential asset. |
| MS Teams | `Get-CsOnlineUser` | Queries all enterprise-voice-enabled users with assigned DDIs from the customer's Teams tenant. |

### Outputs
| Type | Name | Description |
|------|------|-------------|
| HTTPS POST | `teams-ddi-activation-determination` | JSON array of DDI + OnlineVoiceRoutingPolicy objects sent to LoopUp CTDA API |
| Log file | `C:\LoopUp\ddi_<yyyyMMdd>.log` | Transcript log written on on-premises deployments |
<!-- ai-inputs-outputs:end -->

---

# ct-integrated-reporting

LoopUp Hosted Billing Script

## LoopUp hosted DDI configuration reporting deployment

**Commercial / GCC tenants:**

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Floopup%2Fct-integrated-reporting%2Fmain%2Fscripts%2FAzure%2Fazuredeploy.json)

**GCC High / DoD tenants (Azure Government):**

[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Floopup%2Fct-integrated-reporting%2Fmain%2Fscripts%2FAzure%2Fazuredeploy.json)

## Deploying in GCC High / DoD (US Government clouds)

GCC High and DoD are separate Microsoft national clouds with their own endpoints (`login.microsoftonline.us`, `graph.microsoft.us` / `dod-graph.microsoft.us`, `portal.azure.us`). The same scripts and ARM template support them — no separate version is required — but the deployment differs as follows.

**Which cloud am I in?** Only GCC High and DoD need these steps. GCC (non-High) tenants use the standard commercial endpoints — follow the normal instructions above and leave `TeamsEnvironmentName` as `Commercial`.

### Azure deployment differences

1. Use the **Deploy to Azure Gov** button above. GCC High/DoD Microsoft 365 tenants are paired with Azure Government subscriptions, which can only be managed through `portal.azure.us` — the standard button targets `portal.azure.com` and cannot deploy there.
2. Select an **Azure Government region** for the automation account (`usgovvirginia`, `usgovarizona`, `usgovtexas`, or `usdodcentral`/`usdodeast` for DoD).
3. Set the **`TeamsEnvironmentName`** template parameter to `TeamsGCCH` (GCC High) or `TeamsDOD` (DoD). This is stored as an Automation variable and makes the runbook connect to Teams with `Connect-MicrosoftTeams -TeamsEnvironmentName <value>`, which routes all Microsoft authentication and Graph traffic to the US Government endpoints. No other URLs need changing.

### On-premises deployment differences

Add `-teamsEnvironmentName TeamsGCCH` (or `TeamsDOD`) to the PowerShell arguments in the scheduled task, e.g.:

```
-ExecutionPolicy Bypass -File C:\LoopUp\SelfHostedDdiConfigurationReporting.ps1 -luServiceAccountUsername [Username] -luClientID [ID] -luClientSecret [Secret] -luCustomerID [ID] -teamsEnvironmentName TeamsGCCH
```

Everything else is identical to the standard on-premises setup.

### Prerequisites and notes

- The LoopUp service account must exist in the GCC High/DoD tenant and, as with commercial deployments, must be excluded from MFA (the script signs in non-interactively with username/password).
- Outbound HTTPS access must be allowed to `identity.loopup.com` and `ctda.loopup.com` (LoopUp's endpoints are the same in all clouds — there are no `.us` variants), and to `raw.githubusercontent.com` (the runbook downloads the core script at runtime) and `www.powershellgallery.com` (module import during deployment).
- The MicrosoftTeams PowerShell module version deployed by the ARM template (7.8.0) supports credential authentication in GCC High and DoD.
