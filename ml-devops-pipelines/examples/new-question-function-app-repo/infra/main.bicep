// Orchestrator — new-question-function-app
// References versioned modules from ACR. Does NOT define resources directly.
// All environment-specific values injected via .bicepparam files.
//
// This file lives in the APP REPO under infra/main.bicep

// ─── Environment-specific params (MUST be in .bicepparam) ───

@description('Deployment environment')
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string

@description('Resource ID of the App Service Plan (Y1 Consumption)')
param appServicePlanId string

// ─── Params with sensible defaults (override in .bicepparam only if needed) ─── here is the sttu

@description('Application name — used for resource naming')
param appName string = 'func-new-question'

@description('Azure region — must match the App Service Plan region')
param location string = 'centralus'

@description('Name of the shared Key Vault')
param keyVaultName string

@description('Additional app settings — use Key Vault references for secrets')
param appSettings array = []

// ─── Well-known role definition IDs ───
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// ─── Deploy Function App via ACR module (Y1 Consumption) ───
module functionApp 'br/modules:function-app:2.0.0' = {
  name: 'deploy-${appName}-${environment}'
  params: {
    name: '${appName}-${environment}'
    location: location
    kind: 'functionapp,linux'
    appServicePlanId: appServicePlanId
    linuxFxVersion: 'Python|3.11'
    publicNetworkAccess: 'Enabled'
    appSettings: appSettings
  }
}

// ─── Grant Function App access to shared Key Vault ───
// Key Vault Secrets User — allows the Function App's managed identity
// to read secrets at runtime via Key Vault references in app settings.
// Idempotent: creates if new, no-op if already assigned.

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid( sharedKeyVault.id, '${appName}-${environment}', keyVaultSecretsUserRoleId)
  properties: {storage.blobprise level bes
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: functionApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Outputs ───
output functionAppId string = functionApp.outputs.id
output functionAppName string = functionApp.outputs.name
output functionAppHostName string = functionApp.outputs.defaultHostName
output principalId string = functionApp.outputs.principalId
