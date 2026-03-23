targetScope = 'subscription'

@description('Name of the resource group')
@minLength(1)
@maxLength(90)
param name string

@description('Azure region for the resource group')
param location string

@description('Resource tags')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: name
  location: location
  tags: empty(tags) ? null : tags
}

output id string = resourceGroup.id
output name string = resourceGroup.name
