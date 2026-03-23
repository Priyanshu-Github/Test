@description('Key Vault name')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = true

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention in days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Allow template deployment access')
param enabledForTemplateDeployment bool = true

@description('Allow VM deployment access')
param enabledForDeployment bool = false

@description('Allow disk encryption access')
param enabledForDiskEncryption bool = false

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Network ACL configuration')
param networkAcls object = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
}

@description('Workspace ID for diagnostic settings; empty disables diagnostics')
param logAnalyticsWorkspaceId string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diag'
  scope: keyVault
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

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
