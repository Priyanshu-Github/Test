@description('Workspace name')
@minLength(4)
@maxLength(63)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Workspace SKU')
@allowed([
  'PerGB2018'
  'Standalone'
  'PerNode'
  'CapacityReservation'
])
param skuName string = 'PerGB2018'

@description('Retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB; -1 means unlimited')
param dailyQuotaGb int = -1

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: logAnalyticsWorkspace
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

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
