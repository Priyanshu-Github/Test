@description('User-Assigned Managed Identity name')
@minLength(3)
@maxLength(128)
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output id string = userAssignedIdentity.id
output name string = userAssignedIdentity.name
output principalId string = userAssignedIdentity.properties.principalId
output clientId string = userAssignedIdentity.properties.clientId
output tenantId string = userAssignedIdentity.properties.tenantId
