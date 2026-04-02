// Azure Function App — Flex Consumption Plan (FC1)
//
// Purpose-built for Flex Consumption. Does NOT support traditional plans.
// For Consumption (Y1), Premium (EP1), or Standard (S1) plans, use the
// `function-app` module instead.
//
// Key differences from traditional function-app module:
//   - Requires functionAppConfig (deployment storage, scale, runtime)
//   - Runtime is set via functionAppConfig.runtime, NOT linuxFxVersion
//   - Deployment uses blob container storage with managed identity or connection string
//   - Always Linux-only (kind = functionapp,linux)

@description('Function App name')
@minLength(2)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('App Service Plan resource ID (must be FC1 SKU)')
param appServicePlanId string

@description('Linked storage account name')
param storageAccountName string

@description('Functions worker runtime')
@allowed([
  'dotnet-isolated'
  'node'
  'python'
  'java'
  'powershell'
  'custom'
])
param functionsWorkerRuntime string

@description('Runtime version (e.g. 3.11 for Python, 20 for Node.js, 8.0 for .NET)')
param runtimeVersion string

// ─── Deployment storage settings ───

@description('Deployment storage authentication mode')
@allowed([
  'SystemAssignedIdentity'
  'StorageAccountConnectionString'
])
param deploymentStorageAuthMode string = 'SystemAssignedIdentity'

// ─── Scale and concurrency ───

@description('Maximum instance count for Flex Consumption')
param maximumInstanceCount int = 100

@description('Instance memory in MB')
@allowed([
  2048
  4096
])
param instanceMemoryMB int = 2048

// ─── Optional settings ───

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Functions extension version')
@allowed([
  '~4'
])
param functionsExtensionVersion string = '~4'

@description('FTP/FTPS state')
@allowed([
  'AllAllowed'
  'FtpsOnly'
  'Disabled'
])
param ftpsState string = 'Disabled'

@description('Enable HTTP/2')
param http20Enabled bool = true

@description('Minimum TLS version')
@allowed([
  '1.2'
])
param minTlsVersion string = '1.2'

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Subnet resource ID for VNet integration')
param vnetSubnetId string = ''

@description('Additional app settings including Key Vault references')
param appSettings array = []

// ─── Variables ───

var storageAccountBlobEndpoint = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/deploymentpackage'

var deploymentAuthSystemIdentity = {
  type: 'SystemAssignedIdentity'
}

var deploymentAuthConnectionString = {
  type: 'StorageAccountConnectionString'
  storageAccountConnectionStringName: 'AzureWebJobsStorage'
}

var deploymentAuth = deploymentStorageAuthMode == 'SystemAssignedIdentity'
  ? deploymentAuthSystemIdentity
  : deploymentAuthConnectionString

var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storageAccountName
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: functionsExtensionVersion
  }
]

var appInsightsSettings = !empty(appInsightsConnectionString)
  ? [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsightsConnectionString
      }
    ]
  : []

var allAppSettings = union(baseAppSettings, appInsightsSettings, appSettings)

// ─── Resource ───

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
    virtualNetworkSubnetId: !empty(vnetSubnetId) ? vnetSubnetId : null
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: storageAccountBlobEndpoint
          authentication: deploymentAuth
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: functionsWorkerRuntime
        version: runtimeVersion
      }
    }
    siteConfig: {
      appSettings: allAppSettings
      ftpsState: ftpsState
      http20Enabled: http20Enabled
      minTlsVersion: minTlsVersion
    }
  }
}

// ─── Outputs ───

output id string = functionApp.id
output name string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
