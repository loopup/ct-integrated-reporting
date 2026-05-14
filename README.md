<!-- ai-summary:start -->
## AI Summary
**Kind:** automation
**Language:** PowerShell
**Runtime:** PowerShell 5.1+ / Azure Automation

This repository contains PowerShell automation scripts that collect Microsoft Teams DDI (Direct Dial-In) configuration data from a customer's tenant and report it to the LoopUp Cloud Telephony platform for hosted billing and DDI activation determination. The domain is Cloud Telephony (CT) integrated reporting, bridging Microsoft Teams voice configuration with LoopUp's back-end customer management APIs. Scripts communicate outbound over HTTPS REST to two LoopUp services: the identity service (`identity.loopup.com`) for OAuth2 client-credentials authentication, and the CT DDI activation API (`ctda.loopup.com`) to submit DDI data. The repo ships two deployment variants — an Azure Automation runbook (with a one-click ARM template deploy) and an on-premises Windows Scheduled Task — sharing a common core script downloaded at runtime from GitHub. Key technologies are PowerShell, Microsoft Teams PowerShell module, Azure Automation Accounts, and Azure Resource Manager (ARM) templates.
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
| MicrosoftTeams (PowerShell module) | 4.0.0 (Azure deployment) |

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

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Floopup%2Fct-integrated-reporting%2Fmain%2Fscripts%2FAzure%2Fazuredeploy.json)
