targetScope = 'resourceGroup'

@description('Azure Container Registry name')
@minLength(5)
@maxLength(50)
param name string

@description('Azure region for ACR')
param location string

@description('Tags applied to ACR')
param tags object = {}

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Premium'

@description('Public network access setting for ACR')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Retention period in days for untagged manifests')
@minValue(1)
@maxValue(365)
param retentionDays int = 30

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: publicNetworkAccess
    policies: {
      retentionPolicy: {
        days: retentionDays
        status: 'enabled'
      }
    }
  }
}

output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
output acrId string = containerRegistry.id
