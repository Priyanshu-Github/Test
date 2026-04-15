using '../main.bicep'

param environment = 'qa'
param location = 'centralus'

// Shared monitoring foundation
param logAnalyticsWorkspaceName = 'law-qa-edison-ml-01'

// Shared Key Vault (used by all apps via KV references)
param keyVaultName = 'kv-dacedisondemotest'

// Shared Storage Accounts
// NOTE: Replace placeholder names if your naming standard differs.
param storageAccounts = [
  {
    key: 'shared'
    name: 'stqaedisonshared01'
    allowSharedKeyAccess: true
  }
]

// Shared App Service Plans
// NOTE: Replace placeholder names if your naming standard differs.
param appServicePlans = [
  {
    key: 'shared-b1'
    name: 'asp-qa-shared-b1-01'
    skuName: 'B1'
    kind: 'linux'
    reserved: true
  }
]

// Shared Application Insights components (workspace-based)
// NOTE: Replace placeholder names if your naming standard differs.
param appInsightsComponents = [
  {
    key: 'shared'
    name: 'appi-qa-shared-01'
  }
]
