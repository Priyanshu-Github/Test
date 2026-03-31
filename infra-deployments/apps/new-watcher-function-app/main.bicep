// Orchestrator — new-watcher-function-app
// References versioned modules from ACR. Does NOT define resources directly.
// All values injected via .bicepparam files per environment.

@description('Deployment environment')
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string

@description('Azure region for all resources')
param location string

@description('Application name')
param appName string

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('Name of the storage account used by the Function App')
param storageAccountName string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Functions worker runtime')
@allowed([
  'python'
  'node'
])
param functionsWorkerRuntime string

@description('Linux FX version (e.g., Python|3.11)')
param linuxFxVersion string

@description('Subnet resource ID for VNet integration')
param vnetSubnetId string = ''

@description('Resource tags')
param tags object = {}

@description('Additional app settings (e.g., Key Vault references)')
param appSettings array = []

@description('Health check path')
param healthCheckPath string = ''

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

// ─── Deploy Function App via ACR module ───
module functionApp 'br/<acr-alias>:function-app:1.0.0' = {
  name: 'deploy-${appName}-${environment}'
  params: {
    name: '${appName}-${environment}'
    location: location
    tags: union(tags, {
      environment: environment
      app: appName
    })
    kind: 'functionapp,linux'
    appServicePlanId: appServicePlanId
    storageAccountName: storageAccountName
    appInsightsConnectionString: appInsightsConnectionString
    functionsWorkerRuntime: functionsWorkerRuntime
    linuxFxVersion: linuxFxVersion
    vnetSubnetId: vnetSubnetId
    appSettings: appSettings
    healthCheckPath: healthCheckPath
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// ─── Outputs ───
output functionAppId string = functionApp.outputs.id
output functionAppName string = functionApp.outputs.name
output functionAppHostName string = functionApp.outputs.defaultHostName
output principalId string = functionApp.outputs.principalId
