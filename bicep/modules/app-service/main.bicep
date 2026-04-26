@description('Web App name')
@minLength(2)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('Web app kind')
@allowed([
  'app,linux'
  'app'
])
param kind string = 'app,linux'

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Linux FX version (e.g. NODE|20-lts, DOTNETCORE|8.0, PYTHON|3.11). Ignored for Windows webapps.')
param linuxFxVersion string = 'NODE|20-lts'

@description('Startup command for Linux Web App. Leave empty to use stack default.')
param appCommandLine string = ''

@description('Always On setting; not supported on Free/Shared plans')
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

@description('Minimum TLS version')
@allowed([
  '1.0'
  '1.1'
  '1.2'
  '1.3'
])
param minTlsVersion string = '1.2'

@description('Enable client affinity (ARR sticky sessions)')
param clientAffinityEnabled bool = false

@description('Enable WebSockets')
param webSocketsEnabled bool = false

@description('Health check path. Leave empty to disable.')
param healthCheckPath string = ''

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Route all outbound traffic through VNet integration. Only takes effect when VNet integration is configured separately.')
param vnetRouteAllEnabled bool = false

@description('App settings array. Caller owns all secrets (APPLICATIONINSIGHTS_CONNECTION_STRING, WEBSITE_RUN_FROM_PACKAGE, etc.).')
param appSettings array = []

@description('Connection strings array. Each item: { name, connectionString, type }.')
param connectionStrings array = []

@description('CORS configuration. Pass { allowedOrigins: [], supportCredentials: false } to disable CORS.')
param cors object = {
  allowedOrigins: []
  supportCredentials: false
}

@description('Resource ID of the User-Assigned Managed Identity to attach to this Web App.')
param userAssignedIdentityResourceId string

resource webApp 'Microsoft.Web/sites@2025-03-01' = {
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
    reserved: kind == 'app,linux'
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
    clientAffinityEnabled: clientAffinityEnabled
    keyVaultReferenceIdentity: userAssignedIdentityResourceId
    siteConfig: {
      appSettings: appSettings
      connectionStrings: connectionStrings
      linuxFxVersion: linuxFxVersion
      appCommandLine: appCommandLine
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      http20Enabled: http20Enabled
      minTlsVersion: minTlsVersion
      webSocketsEnabled: webSocketsEnabled
      vnetRouteAllEnabled: vnetRouteAllEnabled
      healthCheckPath: healthCheckPath
      cors: cors
    }
  }
}

output id string = webApp.id
output name string = webApp.name
output defaultHostName string = webApp.properties.defaultHostName
