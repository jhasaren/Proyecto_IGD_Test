// ====================================================
// Despliegue Infraestructura MS Azure
// Autor: John A. Sanchez
// Fecha: 03/Jul/2026
// Este script asume que el Grupo de Recursos ya fue creado manualmente por el administrador de Azure.
// ====================================================

// ========================================================================
// Parámetros desde el archivo .bicepparam
// ========================================================================

@minLength(3)
param projectPrefix string
@minLength(3)
param environment string
param location string = resourceGroup().location
param sqlLocation string
param sqlAdminLogin string
@secure()
param sqlAdminPassword string
param sqlServerName string = toLower('${projectPrefix}-sqldb-${environment}')
param sqlDatabaseName string = toLower('${projectPrefix}-${environment}-srcdb')

@allowed([
  'standard'
  'premium'
])
param databricksSkuName string = 'premium'

// ========================================================================
// VARIABLES: ESTÁNDAR DE NOMENCLATURA (prefijoempresa-tipo-ambiente)
// ========================================================================

// Abreviación oficial Azure para Storage Account: 'dl'
// NOTA: por restricciones de Azure el nombre de Storage Account no debe llevar guion
var storageAccountName = toLower('${projectPrefix}${environment}dl')

// Definición de contenedores para la Arquitectura Medallón
var medallionContainers = [
  'bronze'
  'silver'
  'gold'
]

// IDs de Roles Oficiales de Azure (Definiciones de Rol Integradas)
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6' //Key Vault Secrets User

// Abreviación oficial Azure para Key Vault: 'kv'
var keyVaultName = toLower('${projectPrefix}-kv-${environment}')

// Abreviación oficial Azure para Data Factory: 'adf'
var dataFactoryName = toLower('${projectPrefix}-adf-${environment}')

// Abreviación oficial Azure para Databricks: 'dbw' y 'dbac'
var databricksWorkspaceName = toLower('${projectPrefix}-dbw-${environment}')
var databricksAccessConnectorName = toLower('${projectPrefix}-dbac-${environment}')

// ==========================================
// CAPA DE ALMACENAMIENTO: Data Lake Gen2
// ==========================================
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}

// Despliegue automatizado de los contenedores Medallón
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [
  for containerName in medallionContainers: {
    parent: blobServices
    name: containerName
    properties: {
      publicAccess: 'None' // Garantiza que los datos sensibles de negocio no queden expuestos públicamente
    }
  }
]

// ==========================================
// CAPA DE SEGURIDAD: Azure Key Vault
// ==========================================
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
  }
}

// ==========================================
// CAPA DE DATOS: Azure SQL Database (fuente)
// ==========================================
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: sqlLocation
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: sqlLocation
  sku: {
    name: 'GP_S_Gen5' //Serverless
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1 //max de vcores
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368 //32gb max permitido en free
    minCapacity: json('0.5')
    autoPauseDelay: 60 //60 minutos
  }
}

// ==========================================
// CAPA DE INTEGRACIÓN: Azure Data Factory V2
// ==========================================
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned' // Habilita la identidad para autenticación segura sin contraseñas (RBAC)
  }
  properties: {
    publicNetworkAccess: 'Enabled' // Nota: En entornos corporativos ultra-seguros se restringe con Private Endpoints
  }
}

// ==========================================
// CAPA DE PROCESAMIENTO: Azure Databricks
// ==========================================
resource databricksAccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: databricksAccessConnectorName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: databricksWorkspaceName
  location: location
  sku: {
    name: databricksSkuName
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId(
      'Microsoft.Resources/resourceGroups',
      'rg-${databricksWorkspaceName}-managed'
    )
    parameters: {
      enableNoPublicIp: {
        value: false
      }
    }
  }
}

// ========================================================================
// CONTROL DE ACCESO (RBAC): Asignación de Roles Automatizada
// ========================================================================

// Permiso: Data Factory como Colaborador de Datos de Storage Blob en el Data Lake
resource adfStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, dataFactory.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal' // Tipo explícito para acelerar la propagación de identidades en Azure
  }
}

// Permiso: Data Factory como Usuario de Secretos en el Key Vault
resource adfKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, dataFactory.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Permiso: Databricks Access Connector como Colaborador de Datos de Storage Blob en el Data Lake
resource databricksStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, databricksAccessConnector.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: databricksAccessConnector.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Permiso: Databricks Access Connector como Usuario de Secretos en el Key Vault
resource databricksKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, databricksAccessConnector.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: databricksAccessConnector.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// OUTPUTS:
output storageAccountId string = storageAccount.id
output storageAccountEndpoints object = storageAccount.properties.primaryEndpoints
output keyVaultUri string = keyVault.properties.vaultUri
output dataFactoryId string = dataFactory.id
output dataFactoryIdentityPrincipalId string = dataFactory.identity.principalId
output sqlServerName string = sqlServer.name
output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name

output databricksWorkspaceUrl string = databricksWorkspace.properties.workspaceUrl
output databricksWorkspaceId string = databricksWorkspace.id
