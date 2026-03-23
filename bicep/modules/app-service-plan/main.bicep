@description('App Service Plan name')
@minLength(1)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('SKU name (e.g. FC1, Y1, EP1, B1, S1, P1v3)')
param skuName string

@description('SKU tier (e.g. FlexConsumption, Dynamic, ElasticPremium, Basic, Standard, PremiumV3)')
param skuTier string

@description('Plan kind; use linux for Linux plans')
param kind string = ''

@description('Set true for Linux plans')
param reserved bool = false

@description('Enable zone redundancy; requires Premium or Isolated SKU')
param zoneRedundant bool = false

@description('Maximum elastic worker count for Elastic Premium plans')
param maximumElasticWorkerCount int = 1

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    reserved: reserved
    zoneRedundant: zoneRedundant
    maximumElasticWorkerCount: maximumElasticWorkerCount
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: appServicePlan
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

output id string = appServicePlan.id
output name string = appServicePlan.name
