// Orchestrator — Shared Infrastructure
// Deploys baseline shared resources consumed by Function Apps and App Services.
// All environment-specific values are injected via .bicepparam files.

// ──────────────────────────────────────────
// Environment
// ──────────────────────────────────────────

@description('Deployment environment')
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string

@description('Azure region')
param location string = 'centralus'

// ──────────────────────────────────────────
// Log Analytics Workspace
// ──────────────────────────────────────────

@description('Resource ID of an existing shared Log Analytics workspace managed outside this template')
param logAnalyticsWorkspaceResourceId string = ''

// ──────────────────────────────────────────
// Shared resources catalogs
// ──────────────────────────────────────────

@description('Shared Storage Accounts catalog')
param storageAccounts array = []

@description('Shared App Service Plans catalog')
param appServicePlans array = []

@description('Shared Application Insights catalog')
param appInsightsComponents array = []

// ──────────────────────────────────────────
// Key Vault
// ──────────────────────────────────────────

@description('Name of the shared Key Vault. Empty skips Key Vault deployment.')
param keyVaultName string = ''

@description('Public network access for Key Vault — Enabled for initial setup, Disabled once VNet is in place')
@allowed([
  'Enabled'
  'Disabled'
])
param keyVaultPublicNetworkAccess string = 'Enabled'

// ──────────────────────────────────────────
// Derived values
// ──────────────────────────────────────────

var resolvedLogAnalyticsWorkspaceId = !empty(logAnalyticsWorkspaceResourceId) ? logAnalyticsWorkspaceResourceId : ''

// ──────────────────────────────────────────
// Shared Storage Accounts
// ──────────────────────────────────────────

module sharedStorageAccounts 'br/modules:storage-account:2.0.0' = [for (storage, i) in storageAccounts: {
  name: 'deploy-shared-storage-${environment}-${i}'
  params: {
    name: storage.name
    location: storage.?location ?? location
    skuName: storage.?skuName ?? 'Standard_LRS'
    kind: storage.?kind ?? 'StorageV2'
    accessTier: storage.?accessTier ?? 'Hot'
    httpsOnly: storage.?httpsOnly ?? true
    minimumTlsVersion: storage.?minimumTlsVersion ?? 'TLS1_2'
    allowBlobPublicAccess: storage.?allowBlobPublicAccess ?? false
    allowSharedKeyAccess: storage.?allowSharedKeyAccess ?? false
    publicNetworkAccess: storage.?publicNetworkAccess ?? 'Disabled'
    networkAcls: storage.?networkAcls ?? {
      defaultAction: 'Deny'
      bypass: 'AzureServices, Logging, Metrics'
    }
 }
}]

// ──────────────────────────────────────────
// Shared App Service Plans
// ──────────────────────────────────────────

module sharedAppServicePlans 'br/modules:app-service-plan:1.0.0' = [for (plan, i) in appServicePlans: {
  name: 'deploy-shared-asp-${environment}-${i}'
  params: {
    name: plan.name
    location: plan.?location ?? location
    skuName: plan.skuName
    kind: plan.?kind ?? 'linux'
    reserved: plan.?reserved ?? false
    zoneRedundant: plan.?zoneRedundant ?? false
  }
}]

// ──────────────────────────────────────────
// Shared App Insights (workspace-based)
// ──────────────────────────────────────────

module sharedAppInsights 'br/modules:app-insights:1.0.0' = [for (appi, i) in appInsightsComponents: {
  name: 'deploy-shared-appi-${environment}-${i}'
  params: {
    name: appi.name
    location: appi.?location ?? location
    kind: appi.?kind ?? 'web'
    applicationType: appi.?applicationType ?? 'web'
    workspaceResourceId: appi.?logAnalyticsWorkspaceId ?? resolvedLogAnalyticsWorkspaceId
    retentionInDays: appi.?retentionInDays ?? 90
  }
}]

var appInsightsOutputValue = [for (appi, i) in appInsightsComponents: {
  key: appi.?key ?? appi.name
  name: sharedAppInsights[i].outputs.name
  id: sharedAppInsights[i].outputs.id
  connectionString: sharedAppInsights[i].outputs.connectionString
}]

// ──────────────────────────────────────────
// Shared Key Vault
// ──────────────────────────────────────────

module sharedKeyVault 'br/modules:key-vault:1.0.0' = if (!empty(keyVaultName)) {
  name: 'deploy-shared-key-vault-${environment}'
  params: {
    name: keyVaultName
    location: location
    publicNetworkAccess: keyVaultPublicNetworkAccess
    logAnalyticsWorkspaceId: resolvedLogAnalyticsWorkspaceId
  }
}

// ──────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────

output logAnalyticsWorkspaceId string = resolvedLogAnalyticsWorkspaceId
output logAnalyticsWorkspaceName string = !empty(resolvedLogAnalyticsWorkspaceId) ? last(split(resolvedLogAnalyticsWorkspaceId, '/')) : ''
output appInsightsSkippedBecauseWorkspaceMissing bool = false

output storageAccountsOutput array = [for (storage, i) in storageAccounts: {
  key: storage.?key ?? storage.name
  name: sharedStorageAccounts[i].outputs.name
  id: sharedStorageAccounts[i].outputs.id
}]

output appServicePlansOutput array = [for (plan, i) in appServicePlans: {
  key: plan.?key ?? plan.name
t ation
  skuName: plan.skuName
}]

output appInsightsOutput array = appInsightsOutputValue

output keyVaultName string = !empty(keyVaultName) ? sharedKeyVault.outputs.name : ''
output keyVaultUri string = !empty(keyVaultName) ? sharedKeyVault.outputs.uri : ''
output keyVaultId string = !empty(keyVaultName) ? sharedKeyVault.outputs.id : ''
