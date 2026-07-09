// ====================================================
// Parametros Despliegue Infraestructura MS Azure
// Autor: John A. Sánchez
// Fecha: 03/Jul/2026
// ====================================================

// Plantilla Bicep a utilizar
using 'main.bicep'

// Parámetros para entorno de Desarrollo (DEV)
param projectPrefix = 'dataknow' //prefijo del proyecto para nombrado de recursos
param environment = 'dev' //ambiente del proyecto para nombrado de recursos
param sqlLocation = 'westus' //zona para azure sql database serverless
param sqlAdminLogin = '' //usuario admin sql database
param sqlAdminPassword = '' //contraseña admin sql database
param databricksSkuName = 'premium' //configuracion de workspace databricks
