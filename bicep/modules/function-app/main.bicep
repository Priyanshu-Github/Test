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

@description('Functions extension version')
param functionsExtensionVersion string = '~4'

@description('Linux FX version when deploying Linux Function App')
param linuxFxVersion string = 'Python|3.11'

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

@description('Additional app settings including Key Vault references. Caller owns all secrets (AzureWebJobsStorage, APPLICATIONINSIGHTS_CONNECTION_STRING, etc.).')
param appSettings array = []

@description('Resource ID of the User-Assigned Managed Identity to attach to this Function App.')
param userAssignedIdentityResourceId string

var baseAppSettings = [
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

var allAppSettings = union(baseAppSettings, appSettings)

resource functionApp 'Microsoft.Web/sites@2025-03-01' = {
  name: name
  location: location
  kind: kind
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    reserved: kind == 'functionapp,linux'
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
    keyVaultReferenceIdentity: userAssignedIdentityResourceId
    siteConfig: {
      appSettings: allAppSettings
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      http20Enabled: http20Enabled
    }
  }
}

output id string = functionApp.id
output name string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
