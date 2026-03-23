@description('App Service name')
param name string

@description('Azure region')
param location string

@description('Tags to apply to the App Service')
param tags object = {}

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Kind of App Service. Use app,app,linux for Linux apps.')
param kind string = 'app'

@description('HTTPS-only enforcement')
param httpsOnly bool = true

@description('Optional site configuration object')
param siteConfig object = {}

@description('App settings as name/value pairs')
param appSettings array = []

@description('Optional Log Analytics workspace resource ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

var normalizedAppSettings = [for setting in appSettings: {
  name: setting.name
  value: setting.value
}]

resource appService 'Microsoft.Web/sites@2024-11-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: union(siteConfig, {
      appSettings: normalizedAppSettings
    })
  }
}

#disable-next-line use-recent-api-versions // Newer diagnostics type metadata in linter is currently inconsistent for this schema.
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: appService
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

output id string = appService.id
output appServiceName string = appService.name
output defaultHostName string = appService.properties.defaultHostName
