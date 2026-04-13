using '../main.bicep'

// ─── Required: environment-specific values ───
param environment = 'qa'
param location = 'centralus' // Must match ASP region

param appServicePlanId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/nx-cus-nonprod-eds-qa-rg/providers/Microsoft.Web/serverfarms/nx-cus-nonprod-eds-Questions-qa-asp'

param storageAccountName = 'stdacedisondemotest'

param keyVaultName = '<qa-shared-key-vault-name>'

// No secrets in this file. Sensitive values (App Insights connection string,
// API keys, etc.) are stored in Key Vault and referenced via
// @Microsoft.KeyVault(...) in the orchestrator's app settings.

// ─── App settings — only non-secret, app-specific overrides ───
param appSettings = [
  // Key Vault references for additional secrets:
  // {
  //   name: 'SOME_API_KEY'
  //   value: '@Microsoft.KeyVault(VaultName=<qa-shared-key-vault-name>;SecretName=some-api-key)'
  // }
]
