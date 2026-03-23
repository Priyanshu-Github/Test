@description('Function App name')
@minLength(2)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Function app kind')
@allowed([
  'functionapp,linux'
  'functionapp'
])
param kind string = 'functionapp,linux'

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Linked storage account name')
param storageAccountName string

@description('Storage authentication mode')
@allowed([
  'managedIdentity'
  'connectionString'
  'userAssigned'
])
param storageAuthMode string = 'managedIdentity'

@description('Storage account resource group for cross-resource-group listKeys lookups')
param storageAccountResourceGroup string = ''

@description('User-assigned managed identity resource ID')
param userAssignedIdentityResourceId string = ''

@description('User-assigned managed identity client ID')
param userAssignedIdentityClientId string = ''

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Functions extension version')
@allowed([
  '~4'
])
param functionsExtensionVersion string = '~4'

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

@description('Linux FX version when deploying Linux Function App')
param linuxFxVersion string = ''

@description('.NET framework version for Windows Function App')
param netFrameworkVersion string = ''

@description('Always On setting; not supported on Consumption/Flex Consumption plans')
param alwaysOn bool = false

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

@description('Identity resource ID for Key Vault references with user-assigned identity')
param keyVaultReferenceIdentity string = ''

@description('Additional app settings including Key Vault references')
param appSettings array = []

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

var storageAccountResourceGroupResolved = !empty(storageAccountResourceGroup)
  ? storageAccountResourceGroup
  : resourceGroup().name

var storageAccountResourceId = resourceId(storageAccountResourceGroupResolved, 'Microsoft.Storage/storageAccounts', storageAccountName)

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResourceId, '2025-06-01').keys[0].value}'

var storageConnectionStringSettings = storageAuthMode == 'connectionString' ? [
  {
    name: 'AzureWebJobsStorage'
    value: storageConnectionString
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnectionString
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(name)
  }
] : []

var storageManagedIdentitySettings = storageAuthMode == 'managedIdentity' ? [
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storageAccountName
  }
] : []

var storageUserAssignedSettings = storageAuthMode == 'userAssigned' ? [
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
    value: userAssignedIdentityClientId
  }
] : []

var storageSettings = union(storageConnectionStringSettings, storageManagedIdentitySettings, storageUserAssignedSettings)

var baseAppSettings = [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: functionsExtensionVersion
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionsWorkerRuntime
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

var allAppSettings = union(baseAppSettings, storageSettings, appInsightsSettings, appSettings)

var identityType = storageAuthMode == 'userAssigned'
  ? 'SystemAssigned, UserAssigned'
  : 'SystemAssigned'

var userAssignedIdentities = storageAuthMode == 'userAssigned'
  ? {
      '${userAssignedIdentityResourceId}': {}
    }
  : null

resource functionApp 'Microsoft.Web/sites@2025-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  identity: {
    type: identityType
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
    virtualNetworkSubnetId: !empty(vnetSubnetId) ? vnetSubnetId : null
    keyVaultReferenceIdentity: !empty(keyVaultReferenceIdentity) ? keyVaultReferenceIdentity : null
    siteConfig: {
      appSettings: allAppSettings
      linuxFxVersion: !empty(linuxFxVersion) ? linuxFxVersion : null
      netFrameworkVersion: !empty(netFrameworkVersion) ? netFrameworkVersion : null
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      http20Enabled: http20Enabled
      minTlsVersion: minTlsVersion
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = functionApp.id
output name string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
