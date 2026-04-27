@description('App Service Plan name')
@minLength(1)
@maxLength(60)
param name string

@description('Azure region')
param location string

@description('SKU name (e.g. FC1, Y1, EP1, B1, S1, P1v3)')
param skuName string

@description('Plan kind; use linux for Linux plans')
param kind string = 'linux'

@description('Set true for Linux plans')
param reserved bool = false

@description('Enable zone redundancy; requires Premium or Isolated SKU')
param zoneRedundant bool = false

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: name
  location: location
  kind: kind
  sku: {
    name: skuName
  }
  properties: {
    reserved: reserved
    zoneRedundant: zoneRedundant
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
