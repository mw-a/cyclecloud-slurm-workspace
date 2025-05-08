targetScope = 'resourceGroup'
import {storagePrivateDnsZone_t,tags_t} from './types.bicep'

param location string
param tags tags_t
param saName string
param subnetId string
param storagePrivateDnsZone storagePrivateDnsZone_t

var privateDnsZoneId = storagePrivateDnsZone.?id
var privateDnsZoneSubscription = privateDnsZoneId != null ? split(privateDnsZoneId, '/')[2] : subscription().id
var privateDnsZoneResourceGroup = privateDnsZoneId != null ? split(privateDnsZoneId, '/')[4] : resourceGroup().name
var createVnetLink = storagePrivateDnsZone.type == 'existing' ? storagePrivateDnsZone.vnetLink : storagePrivateDnsZone.type == 'new'

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: saName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      }      
  }
}

var storageBlobPrivateEndpointName = contains(saName, 'ccwstorage') ? 'ccwstorage-blob-pe' : '${saName}-blob-pe'

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: storageBlobPrivateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      { 
        name: storageBlobPrivateEndpointName
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageAccount.id
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    customNetworkInterfaceName: '${storageBlobPrivateEndpointName}-nic'
    subnet: {
      id: subnetId
    }
  }
}

var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

module newBlobPrivateDnsZone 'storage-newDnsZone.bicep' = if (storagePrivateDnsZone.type == 'new') {
  name: 'ccwStorageNewDnsZone'
  params: {
    name: blobPrivateDnsZoneName
    tags: tags
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (storagePrivateDnsZone.type == 'existing') {
  name: blobPrivateDnsZoneName
  scope: resourceGroup(privateDnsZoneSubscription, privateDnsZoneResourceGroup)
}

module blobPrivateDnsZoneVnetLink 'storage-vnetLink.bicep' = if (createVnetLink) {
  name: 'ccwStorageBlobPrivateDnsZoneVnetLink'
  scope: resourceGroup(privateDnsZoneSubscription, privateDnsZoneResourceGroup)
  params: {
    storageAccountId: storageAccount.id
    subnetId: subnetId
    blobPrivateDnsZoneName: storagePrivateDnsZone.type == 'existing' ? blobPrivateDnsZone.name : newBlobPrivateDnsZone.outputs.blobPrivateDnsZoneName //force dependency
    tags: tags
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (storagePrivateDnsZone.type != 'none') {
  parent: storageBlobPrivateEndpoint
  name: 'default'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: blobPrivateDnsZoneName
        properties:{
          privateDnsZoneId: storagePrivateDnsZone.type == 'existing' ? blobPrivateDnsZone.id : newBlobPrivateDnsZone.outputs.blobPrivateDnsZoneId
        }
      }
    ]
  }
}

output storageAccountName string = storageAccount.name
