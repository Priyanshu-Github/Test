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
param location string = 'centralus'

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

// ─── Deploy Function App via ACR module (Flex Consumption) ───
module functionApp 'br/modules:function-app-flex:1.0.0' = {
  name: 'deploy-${appName}-${environment}'
  params: {
    name: '${appName}-${environment}'
    location: location
    tags: union(tags, {
      environment: environment
      app: appName
    })
    appServicePlanId: appServicePlanId
    storageAccountName: storageAccountName
    functionsWorkerRuntime: 'python'
    runtimeVersion: '3.11'
    appInsightsConnectionString: appInsightsConnectionString
    vnetSubnetId: vnetSubnetId
    appSettings: appSettings
  }
}

// ─── Outputs ───
output functionAppId string = functionApp.outputs.id
output functionAppName string = functionApp.outputs.name
output functionAppHostName string = functionApp.outputs.defaultHostName
output principalId string = functionApp.outputs.principalId
