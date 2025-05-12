targetScope = 'subscription'
import * as types from './types.bicep'

param location string
param adminUsername string
@secure()
param adminPassword string
param adminSshPublicKey string = '' 
param storedKey types.storedKey_t = {id: 'foo', location: 'foo', name:'foo'}
@minLength(1)
@maxLength(64)
param ccVMName string
param ccVMSize string
param ccVMIdentityType types.vm_identity_type_t = 'SystemAssigned'
param ccVMIdentities string[] = []
param nodeVMIdentityType string = 'new'
param nodeVMIdentityName string = 'ccwLockerManagedIdentity'
param resourceGroup string
param sharedFilesystem types.sharedFilesystem_t
param additionalFilesystem types.additionalFilesystem_t = { type: 'disabled' }
param network types.vnet_t
param storageAccountName string = ''
param storagePrivateDnsZone types.storagePrivateDnsZone_t
param clusterInitSpecs types.cluster_init_param_t = []
param clusterSettings types.clusterSettings_t = { startCluster: true, version: '23.11.7-1', healthCheckEnabled: false }
param schedulerNode types.scheduler_t
param loginNodes types.login_t = { initialNodes: 0, maxNodes: 0, osImage: '', sku: '' }
param htc types.htc_t = { maxNodes: 0, osImage: '', sku: '' }
param hpc types.hpc_t = { maxNodes: 0, osImage: '', sku: '' }
param gpu types.hpc_t = { maxNodes: 0, osImage: '', sku: '' }
param execute types.execute_t = { maxCores: 0, osImage: '', sku: '', useSpot: false }
param nodeNameIsHostname bool = false
param nodeNamePrefix string = ''
param schedulerHostname string = ''
param tags types.resource_tags_t 
@secure()
param databaseAdminPassword string = ''
param databaseConfig types.databaseConfig_t = { type: 'disabled' }
@minLength(3)
@description('The user-defined name of the cluster. Regex: ^[a-zA-Z0-9@_-]{3,}$')
param clusterName string = 'ccw'
param acceptMarketplaceTerms bool = false
param ood types.oodConfig_t = { type: 'disabled' }

param infrastructureOnly bool = false
param insidersBuild bool = false

// build.sh will override this, but for development please set this yourself as a parameter
param branch string = 'main'
// This needs to be updated on each release. Our Cloud.Project records require a release tag
param projectVersion string = '2025.04.24'
param pyxisProjectVersion string = '1.0.0'
//Internal developer use only: set true use custom CycleCloud release build 
param manualInstall bool = false
param cyclecloudBaseImage string = 'azurecyclecloud:azure-cyclecloud:cyclecloud8-gen2:8.7.120250213'
param osDiskSku string = 'StandardSSD_LRS'
param diskSku string = 'Premium_LRS'
param clusterType string = 'slurm'

resource ccwResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroup
  location: location
  tags: tags[?'Resource group'] ?? {}
}

module makeCCWresources 'ccw.bicep' = {
  name: 'pid-d5d2708b-a4ef-42c0-a89b-b8bd6dd6d29b-partnercenter'
  scope: ccwResourceGroup
  params: {
    location: location
    infrastructureOnly: infrastructureOnly
    insidersBuild: insidersBuild
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminSshPublicKey: adminSshPublicKey
    sharedFilesystem: sharedFilesystem
    additionalFilesystem: additionalFilesystem
    network: network
    storagePrivateDnsZone: storagePrivateDnsZone
    storageAccountName: storageAccountName != '' ? storageAccountName : null
    clusterInitSpecs: clusterInitSpecs
    clusterType: clusterType
    clusterSettings: clusterSettings
    schedulerNode: schedulerNode
    loginNodes: loginNodes
    htc: htc
    hpc: hpc
    gpu: gpu
    execute: execute
    nodeNameIsHostname: nodeNameIsHostname
    nodeNamePrefix: nodeNamePrefix
    schedulerHostname: schedulerHostname
    storedKey: storedKey
    ccVMName: ccVMName
    ccVMSize: ccVMSize
    ccVMIdentityType: ccVMIdentityType
    ccVMIdentities: ccVMIdentities
    nodeVMIdentityType: nodeVMIdentityType
    nodeVMIdentityName: nodeVMIdentityName
    resourceGroup: resourceGroup
    databaseAdminPassword: databaseAdminPassword
    databaseConfig: databaseConfig
    tags: tags
    clusterName: clusterName
    branch: branch
    projectVersion: projectVersion
    pyxisProjectVersion: pyxisProjectVersion
    manualInstall: manualInstall
    acceptMarketplaceTerms: acceptMarketplaceTerms
    ood: ood
    cyclecloudBaseImage: cyclecloudBaseImage
    osDiskSku: osDiskSku
    diskSku: diskSku
  }
}
