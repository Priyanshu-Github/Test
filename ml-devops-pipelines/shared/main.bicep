// Orchestrator — Shared Infrastructure
// Deploys platform-wide resources consumed by multiple Function Apps.
// All environment-specific values injected via .bicepparam files.
//
// This file lives in the INFRA-DEPLOYMENTS repo under shared/main.bicep

// ─── Environment-specific params (MUST be in .bicepparam) ───

@description('Deployment environment')
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string

// Blob containers are owned by the application team — not managed here.
// param storageAccountName string

@description('Name of the shared Key Vault — empty skips Key Vault deployment')
param keyVaultName string = ''

// ─── Params with sensible defaults ───

@description('Azure region')
param location string = 'centralus'

@description('Public network access for Key Vault — Enabled for initial setup, Disabled once VNet is in place')
@allowed([
  'Enabled'
  'Disabled'
])
param keyVaultPublicNetworkAccess string = 'Enabled'

@description('Log Analytics workspace resource ID — empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object = {
  project: 'ml-platform'
  team: 'platform'
  layer: 'shared-infra'
}

// ─── Shared Key Vault ───
// One Key Vault per environment. All Function Apps reference secrets from here
// using Key Vault references in app settings + managed identity.
// RBAC-only (no access policies). enabledForTemplateDeployment allows
// the pipeline to read secrets during Bicep deployment if needed.

module sharedKeyVault 'br/modules:key-vault:1.0.0' = if (!empty(keyVaultName)) {
  name: 'deploy-shared-key-vault-${environment}'
  params: {
    name: keyVaultName
    location: location
    publicNetworkAccess: keyVaultPublicNetworkAccess
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// ─── Shared blob containers ───
// Blob containers are owned and created by the application team.
// The blob-container module is available in the registry if they need it.
// var sharedContainerNames = [
//   'others'
//   'letters'
//   'draft-reports'
//   'metadatas'
//   'fr-results'
//   'text-files'
//   'questions'
//   'info'
//   'checked'
//   'logging'
//   'medical-records'
//   'combined-medical-records'
// ]
//
// module sharedContainers 'br/modules:blob-container:1.0.0' = [for name in sharedContainerNames: {
//   name: 'deploy-container-${name}'
//   params: {
//     storageAccountName: storageAccountName
//     containerName: name
//   }
// }]

// ─── Outputs ───

output keyVaultName string = !empty(keyVaultName) ? sharedKeyVault.outputs.name : ''
output keyVaultUri string = !empty(keyVaultName) ? sharedKeyVault.outputs.uri : ''
output keyVaultId string = !empty(keyVaultName) ? sharedKeyVault.outputs.id : ''
