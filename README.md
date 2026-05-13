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
| Parameter | `luClientId` | LoopUp API client ID (OAuth2) |
| Parameter | `luClientSecret` | LoopUp API client secret (OAuth2) |
| Parameter | `luCustomerId` | LoopUp customer identifier |
| Parameter | `filterOVRP` | Optional OnlineVoiceRoutingPolicy filter to scope DDI collection |
| Parameter | `luServiceAccountUsername` | Microsoft Teams service account username (on-premises variant) |
| Parameter | `identityEndpointUrl` | Override for LoopUp identity service URL (default: `https://identity.loopup.com`) |
| Parameter | `ddiEndpointUrl` | Override for LoopUp DDI API URL (default: `https://ctda.loopup.com`) |
| MS Teams | `Get-CsOnlineUser` | Queries all enterprise-voice-enabled users with assigned DDIs from the customer's Teams tenant |

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
