@description('Storage account name')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Storage SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Storage account kind')
@allowed([
  'StorageV2'
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
])
param kind string = 'StorageV2'

@description('Default access tier')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Require HTTPS traffic only')
param httpsOnly bool = true

@description('Minimum TLS version')
@allowed([
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Allow anonymous blob access')
param allowBlobPublicAccess bool = false

@description('Allow shared key access; disable to enforce Entra ID authentication')
param allowSharedKeyAccess bool = false

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Network ACL rules')
param networkAcls object = {
  defaultAction: 'Deny'
  bypass: 'AzureServices, Logging, Metrics'
}

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: httpsOnly
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
