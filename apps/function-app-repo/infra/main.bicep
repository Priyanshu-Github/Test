// Orchestrator — new-watcher-function-app
// References versioned modules from ACR. Does NOT define resources directly.
// All environment-specific values injected via .bicepparam files.
// Common values (runtime, tags, location) have defaults here to keep param files minimal.
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

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('Name of the storage account used by the Function App')
param storageAccountName string

// ─── Params with sensible defaults (override in .bicepparam only if needed) ───

@description('Application name — used for resource naming')
param appName string = 'func-new-watcher'

@description('Azure region for all resources')
param location string = 'eastus2'

@description('Application Insights connection string — empty disables App Insights')
param appInsightsConnectionString string = ''

@description('Subnet resource ID for VNet integration — empty disables VNet integration')
param vnetSubnetId string = ''

@description('Additional app settings (e.g., Key Vault references)')
param appSettings array = []

@description('Resource tags')
param tags object = {
  project: 'ml-platform'
  team: 'platform'
}

// ─── Reference existing storage account to create deployment container ───
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'deploymentpackage'
  properties: {
    publicAccess: 'None'
  }
}

// ─── Build connection string for StorageAccountConnectionString auth mode ───
// TODO [Path 2]: Once admin grants the service connection 'Role Based Access Control Administrator'
// on this resource group, switch back to SystemAssignedIdentity (remove deploymentStorageAuthMode
// and storageConnectionString below) and add a role assignment resource for Storage Blob Data Owner.
// SystemAssignedIdentity is the enterprise best practice — connection string is a temporary workaround.
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'

// ─── Deploy Function App via ACR module (Flex Consumption) ───
module functionApp 'br/modules:function-app-flex:1.0.0' = {
  name: 'deploy-${appName}-${environment}'
  dependsOn: [
    deploymentContainer
  ]
  params: {
    name: '${appName}-${environment}'
    location: location
    tags: union(tags, {
      environment: environment
      app: appName
    })
    appServicePlanId: appServicePlanId
    storageAccountName: storageAccountName
    // TODO [Path 2]: Remove deploymentStorageAuthMode to revert to SystemAssignedIdentity (default)
    deploymentStorageAuthMode: 'StorageAccountConnectionString'
    functionsWorkerRuntime: 'python'
    runtimeVersion: '3.11'
    appInsightsConnectionString: appInsightsConnectionString
    vnetSubnetId: vnetSubnetId
    appSettings: union(appSettings, [
      // TODO [Path 2]: Remove this — not needed when using SystemAssignedIdentity
      {
        name: 'AzureWebJobsStorage'
        value: storageConnectionString
      }
    ])
  }
}

// ─── Outputs ───
output functionAppId string = functionApp.outputs.id
output functionAppName string = functionApp.outputs.name
output functionAppHostName string = functionApp.outputs.defaultHostName
output principalId string = functionApp.outputs.principalId

// ─── POST-DEPLOYMENT: Role assignment required for Path 2 (SystemAssignedIdentity) ───
// TODO [Path 2]: When switching to SystemAssignedIdentity, the Function App's managed identity
// needs 'Storage Blob Data Owner' on the storage account. Either:
//   (a) Ask admin to run once per environment:
//       az role assignment create \
//         --assignee <principalId from outputs> \
//         --role "Storage Blob Data Owner" \
//         --scope "/subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/<storageAccountName>"
//   (b) Or grant service connection 'Role Based Access Control Administrator' on the RG,
//       then add a roleAssignment resource in this Bicep file to automate it.
