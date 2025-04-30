targetScope = 'resourceGroup'
import {tags_t} from './types.bicep'

param name string
param type string
param location string
param storageAccountName string
param tags tags_t

resource existingManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (type == 'existing') {
  name: name
}

//create managed identity for VMSSs
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (type == 'new') {
  name: name
  location: location
  tags: tags
}

module ccwMIRoleAssignments './miRoleAssignments.bicep' = if (type == 'new') {
  name: 'ccwRoleForLockerManagedIdentity'
  params: {
    principalId: managedIdentity.properties.principalId
    roles: ['Storage Blob Data Reader']
    storageAccountName: storageAccountName
  }
}

output managedIdentityId string = type =='new' ? managedIdentity.id : existingManagedIdentity.id
