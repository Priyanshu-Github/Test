@description('Application Insights name')
@minLength(1)
@maxLength(260)
param name string

@description('Azure region')
param location string

@description('Component kind')
param kind string = 'web'

@description('Application type')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

@description('Log Analytics workspace resource ID for workspace-based App Insights')
param workspaceResourceId string

@description('Data retention in days')
param retentionInDays int = 90

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: kind
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceResourceId
    RetentionInDays: retentionInDays
  }
}

output id string = appInsights.id
output name string = appInsights.name
output connectionString string = appInsights.properties.ConnectionString
