using '../main.bicep'

// ─── Required: environment-specific values ───
param environment = 'qa'
param location = 'centralus' // Must match ASP region

param appServicePlanId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/nx-cus-nonprod-eds-qa-rg/providers/Microsoft.Web/serverfarms/nx-cus-nonprod-eds-Questions-qa-asp'

param storageAccountName = 'stdacedisondemotest'

param keyVaultName = '<qa-shared-key-vault-name>'

// No secrets in this file. All sensitive values are stored in Key Vault
// and referenced via @Microsoft.KeyVault(...) in the orchestrator.

// ─── App settings — non-secret, app-specific overrides only ───
param appSettings = [
  // {
  //   name: 'SOME_NON_SECRET_SETTING'
  //   value: 'some-value'
  // }
]
