@description('Name of the existing storage account')
param storageAccountName string

@description('Resource tags')

@description('Name of the blob container')
@minLength(3)
@maxLength(63)
param containerName string

@description('Public access level')
@allowed([
  'None'
  'Blob'
  'Container'
])
param publicAccess string = 'None'

@description('Default encryption scope')
param defaultEncryptionScope string = '$account-encryption-key'

@description('Deny encryption scope override')
param denyEncryptionScopeOverride bool = false

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: storageAccountName
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2025-06-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-06-01' = {
  parent: blobServices
  name: containerName
  properties: {
    publicAccess: publicAccess
    defaultEncryptionScope: defaultEncryptionScope
    denyEncryptionScopeOverride: denyEncryptionScopeOverride
  }
}

output name string = container.name
output id string = container.id
