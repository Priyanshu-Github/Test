 see // Orchestrator — new-question-webapp (Angular SPA on Linux App Service)
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

@description('Resource ID of the App Service Plan (B1+/Premium — Dedicated, Linux)')
param appServicePlanId string

// ─── Params with sensible defaults (override in .bicepparam only if needed) ───

@description('Application name — used for resource naming')
param appName string = 'app-new-question-webapp'

@description('Azure region — must match the App Service Plan region')
param location string = 'centralus'

@description('Name of the shared Key Vault')
param keyVaultName string

@description('Name of the User-Assigned Managed Identity for this Web App')
param managedIdentityName string

@description('Linux runtime stack (e.g. NODE|20-lts, DOTNETCORE|8.0, PYTHON|3.11)')
param linuxFxVersion string = 'NODE|20-lts'

@description('Startup command for Linux Web App. For Angular SPA: pm2 serve /home/site/wwwroot --no-daemon --spa')
param appCommandLine string = ''

@description('Health check path. Empty string disables.')
param healthCheckPath string = ''

@description('Additional app settings — use Key Vault references for secrets')
param appSettings array = []

// ─── Well-known role definition IDs ───
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// ─── Deploy User-Assigned Managed Identity ───
// Persists across Web App recreations → principalId stays stable →
// no stale role-assignment orphans on downstream resources.
module managedIdentity 'br/modules:managed-identity:1.0.0' = {
  name: 'deploy-${managedIdentityName}-${environment}'
  params: {
    name: managedIdentityName
    location: location
  }
}

// ─── Existing reference to the UAMI ───
// Used for compile-time resource ID and runtime principalId/clientId.
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

// ─── Deploy Web App via ACR module ───
// Module bakes WEBSITE_RUN_FROM_PACKAGE=1; caller passes other settings.
module webApp 'br/modules:app-service:2.1.0' = {
  name: 'deploy-${appName}-${environment}'
  params: {
    name: '${appName}-${environment}'
    location: location
    kind: 'app,linux'
    appServicePlanId: appServicePlanId
    linuxFxVersion: linuxFxVersion
    appCommandLine: appCommandLine
    healthCheckPath: healthCheckPath
    publicNetworkAccess: 'Enabled'
    appSettings: appSettings
    userAssignedIdentityResourceId: uami.id
  }
  dependsOn: [
    managedIdentity
  ]
}

// ─── Grant UAMI access to shared Key Vault ───
// Key Vault Secrets User — allows @Microsoft.KeyVault(...) references to resolve
// at app startup. Without this, app settings using KV references fail to load.
resource sharedKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sharedKeyVault.id, uami.id, keyVaultSecretsUserRoleId)
  scope: sharedKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    managedIdentity
  ]
}

// ─── Outputs ───
output webAppId string = webApp.outputs.id
output webAppName string = webApp.outputs.name
output webAppHostName string = webApp.outputs.defaultHostName
output managedIdentityId string = uami.id
output managedIdentityPrincipalId string = uami.properties.principalId
