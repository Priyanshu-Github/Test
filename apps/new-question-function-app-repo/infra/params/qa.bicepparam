using '../main.bicep'

// ─── Required: environment-specific values ───
param environment = 'qa'
param location = 'centralus' // Must match ASP region

param appServicePlanId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/nx-cus-nonprod-eds-qa-rg/providers/Microsoft.Web/serverfarms/nx-cus-nonprod-eds-Questions-qa-asp'

param keyVaultName = '<qa-shared-key-vault-name>'

param managedIdentityName = 'id-func-new-question-qa'

param storageAccountName = '<qa-function-storage-account-name>'

// No secrets in this file. All sensitive values are stored in Key Vault
// and referenced via @Microsoft.KeyVault(...) below.
// AzureWebJobsStorage is handled by the orchestrator via identity-based connection.

// ─── App settings — values resolved from Key Vault at runtime ───
param appSettings = [
  {
    name: 'CLAUDE_API_KEY'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=claude-api-key)'
  }
  {
    name: 'ASPOSE_KEY'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=aspose-key)'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=app-insights-connection-string)'
  }
]
