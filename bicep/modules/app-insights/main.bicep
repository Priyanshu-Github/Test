@description('Application Insights name')
@minLength(1)
@maxLength(260)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Component kind')
@allowed([
  'web'
  'ios'
  'other'
  'store'
  'java'
  'phone'
])
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
@allowed([
  30
  60
  90
  120
  180
  270
  365
  550
  730
])
param retentionInDays int = 90

@description('Sampling percentage from 0 to 100')
@minValue(0)
@maxValue(100)
param samplingPercentage int = 100

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param diagnosticsWorkspaceId string = ''

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceResourceId
    RetentionInDays: retentionInDays
    SamplingPercentage: samplingPercentage
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticsWorkspaceId)) {
  name: '${name}-diag'
  scope: appInsights
  properties: {
    workspaceId: diagnosticsWorkspaceId
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

output id string = appInsights.id
output name string = appInsights.name
output connectionString string = appInsights.properties.ConnectionString
