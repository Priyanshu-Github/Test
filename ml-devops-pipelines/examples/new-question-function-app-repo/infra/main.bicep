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

// ─── Params with sensible defaults (override in .bicepparam only if needed) ───

@description('Application name — used for resource naming')
param appName string = 'func-new-question'

@description('Azure region — must match the App Service Plan region')
param location string = 'centralus'

@description('Name of the shared Key Vault')
param keyVaultName string

@description('Name of the User-Assigned Managed Identity for this Function App')
param managedIdentityName string

@description('Name of the storage account backing the Function App runtime')
param storageAccountName string

@description('Additional app settings — use Key Vault references for secrets')
param appSettings array = []

// ─── Well-known role definition IDs ───
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var storageBlobDataOwnerRoleId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageQueueDataContributorRoleId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

// ─── Deploy User-Assigned Managed Identity ───
// Persists across Function App recreations → principalId stays stable →
// no stale role-assignment orphans on downstream resources.
module managedIdentity 'br/modules:managed-identity:1.0.0' = {
  name: 'deploy-${managedIdentityName}-${environment}'
  params: {
    name: managedIdentityName
    location: location
  }
}

// ─── Existing reference to the UAMI ───
// Used for compile-time resource ID (guid input) and runtime principalId/clientId.
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

// ─── Host-required app settings ───
// Functions runtime + blob trigger use the identity-based settings (__credential
// is the explicit signal — host/trigger honor it over the flat connection string).
// The flat AzureWebJobsStorage entry exists ONLY to satisfy app code that reads
// os.environ['AzureWebJobsStorage'] at import time and passes it to
// BlobServiceClient.from_connection_string(). Requires allowSharedKeyAccess=true
// on the storage account. Tech debt: remove once app code uses DefaultAzureCredential.
var hostAppSettings = [
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storageAccountName
  }
  {
    name: 'AzureWebJobsStorage__credential'
    value: 'managedidentity'
  }
  {
    name: 'AzureWebJobsStorage__clientId'
    value: uami.properties.clientId
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${functionStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
]

// ─── Deploy Function App via ACR module (Y1 Consumption) ───
module functionApp 'br/modules:function-app:3.0.1' = {
  name: 'deploy-${appName}-${environment}'
  params: {
    name: '${appName}-${environment}'
    location: location
    kind: 'functionapp,linux'
    appServicePlanId: appServicePlanId
    linuxFxVersion: 'Python|3.11'
    publicNetworkAccess: 'Enabled'
    appSettings: union(hostAppSettings, appSettings)
    userAssignedIdentityResourceId: uami.id
  }
  dependsOn: [
    managedIdentity
  ]
}

// ─── Grant UAMI access to shared Key Vault ───
// Key Vault Secrets User — allows @Microsoft.KeyVault(...) references to resolve.
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

// ─── Grant UAMI access to Function App storage ───
// Storage Blob Data Owner — required for the Functions host to read/write its
// internal containers (azure-webjobs-secrets, azure-webjobs-hosts) via identity.
resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: storageAccountName
}

resource stgBlobOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionStorageAccount.id, uami.id, storageBlobDataOwnerRoleId)
  scope: functionStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    managedIdentity
  ]
}

// Storage Queue Data Contributor — required for Functions host to manage
// internal queues (leases, triggers) via identity.
resource stgQueueContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionStorageAccount.id, uami.id, storageQueueDataContributorRoleId)
  scope: functionStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageQueueDataContributorRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    managedIdentity
  ]
}

// Storage Table Data Contributor — required for Functions host to persist
// host state/metadata in internal tables via identity. Missing this role
// causes functions to not appear in the portal even when the host is healthy.
resource stgTableContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionStorageAccount.id, uami.id, storageTableDataContributorRoleId)
  scope: functionStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    managedIdentity
  ]
}

// ─── Outputs ───
output functionAppId string = functionApp.outputs.id
output functionAppName string = functionApp.outputs.name
output functionAppHostName string = functionApp.outputs.defaultHostName
output managedIdentityId string = uami.id
output managedIdentityPrincipalId string = uami.properties.principalId
