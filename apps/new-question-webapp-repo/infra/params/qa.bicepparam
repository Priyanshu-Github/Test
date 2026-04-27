using '../main.bicep'

// ─── Required: environment-specific values ───
param environment = 'qa'
param location = 'centralus' // Must match ASP region

param appServicePlanId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/nx-cus-nonprod-eds-qa-rg/providers/Microsoft.Web/serverfarms/<QA_ASP_NAME>'

param keyVaultName = '<qa-shared-key-vault-name>'

param managedIdentityName = 'id-app-new-question-webapp-qa'

// ─── Runtime / startup ───
param linuxFxVersion = 'NODE|20-lts'

// Angular SPA serving via pm2 (Node runtime has pm2 pre-installed on Linux App Service).
// Artifact mounted at /home/site/wwwroot via WEBSITE_RUN_FROM_PACKAGE=1.
// --spa flag handles client-side routing (returns index.html for unknown routes).
param appCommandLine = 'pm2 serve /home/site/wwwroot --no-daemon --spa'

// Empty disables health check — Angular SPA has no built-in /health endpoint.
// Set this if/when the app exposes one (e.g. '/health').
param healthCheckPath = ''

// No secrets in this file. All sensitive values live in Key Vault and are
// resolved at runtime via @Microsoft.KeyVault(...) using the UAMI.
// WEBSITE_RUN_FROM_PACKAGE is baked into the module — do NOT pass it here.

// ─── App settings — values resolved from Key Vault at runtime ───
param appSettings = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=app-insights-connection-string)'
  }
]
