@description('Workspace name')
@minLength(4)
@maxLength(63)
param name string

@description('Azure region')
param location string

@description('Workspace SKU')
@allowed([
  'PerGB2018'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param skuName string = 'PerGB2018'

@description('Retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
  }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
