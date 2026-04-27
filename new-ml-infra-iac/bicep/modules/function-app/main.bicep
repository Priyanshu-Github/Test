@description('Function App name')
@minLength(2)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('Function app kind')
@allowed([
  'functionapp,linux'
  'functionapp'
])
param kind string = 'functionapp,linux'

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Linked storage account name')
param storageAccountName string = ''

@description('Storage account resource group for cross-resource-group listKeys lookups')
param storageAccountResourceGroup string = ''

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Functions extension version')
param functionsExtensionVersion string = '~4'

@description('Linux FX version when deploying Linux Function App')
param linuxFxVersion string = 'PYTHON|3.11'

@description('Always On setting; not supported on Consumption plans')
param alwaysOn bool = true

@description('FTP/FTPS state')
@allowed([
  'AllAllowed'
  'FtpsOnly'
  'Disabled'
])
param ftpsState string = 'Disabled'

@description('Enable HTTP/2')
param http20Enabled bool = true

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Additional app settings including Key Vault references')
param appSettings array = []

var storageAccountResourceGroupResolved = !empty(storageAccountResourceGroup)
  ? storageAccountResourceGroup
  : resourceGroup().name

var storageAccountResourceId = resourceId(storageAccountResourceGroupResolved, 'Microsoft.Storage/storageAccounts', storageAccountName)

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResourceId, '2025-06-01').keys[0].value}'

var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: storageConnectionString
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: functionsExtensionVersion
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'python'
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
]

var appInsightsSettings = !empty(appInsightsConnectionString)
  ? [
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsightsConnectionString
 t to hibut i c. but an se     }
    ]
  : []

var allAppSettings = union(baseAppSettings, appInsightsSettings, appSettings)

resource functionApp 'Microsoft.Web/sites@2025-03-01' = {
  name: name
  location: location
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
    siteConfig: {
      appSettings: allAppSettings
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      http20Enabled: http20Enablet to highwill be d
    }
  }
}

output id string = functionApp.id
output name string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
