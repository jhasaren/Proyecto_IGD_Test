# Despliegue de Infraestructura como Codigo (IaC) con Azure Bicep

**Autor:** John Alexander Sánchez Rengifo
**Fecha de Documentación:** 09/07/2026

Documento de Referencia Principal: Para una explicación detallada de todo el proceso y diseño de la solución, ver [/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf].

Este componente se encarga de definir, aprovisionar y configurar de manera automatizada los recursos requeridos en Microsoft Azure para dar soporte al pipeline de datos, garantizando la consistencia y repetibilidad del entorno.

---

## IaC con Azure Bicep y Justificacion

Se ha seleccionado Azure Bicep como la tecnologia de Infraestructura como Codigo (IaC) para este proyecto. Las principales razones de esta eleccion dentro del entorno de Microsoft Azure son:

* **Soporte Nativo e Inmediato:** Al ser una herramienta oficial de Microsoft, Bicep ofrece soporte inmediato para todas las caracteristicas, recursos y SKUs de Azure en cuanto estan disponibles en la API de Azure Resource Manager (ARM).
* **Sin Administracion de Estado Local o Remoto:** A diferencia de herramientas multiplataforma como Terraform, Bicep no requiere configurar ni almacenar archivos de estado remotos (state files), ya que el estado del entorno es consultado y gestionado directamente por la plataforma Azure.
* **Integracion y Sintaxis Limpia:** Ofrece una sintaxis declarativa simple y legible en comparacion con las plantillas ARM JSON tradicionales, integrándose sin fricciones con Azure CLI y el sistema de control de accesos RBAC de Azure.

---

## Requisitos Previos en el Ambiente Local

Antes de ejecutar las plantillas de Bicep, asegúrese de tener configurado el entorno local con las siguientes herramientas:

1. **Instalación de Azure CLI:**
   * **Windows:** Descargue e instale el instalador MSI oficial de Azure CLI.
   * **Linux (Debian/Ubuntu):** Ejecute el siguiente comando en su terminal:
     ```bash
     curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
     ```
   * **macOS:** Instale utilizando Homebrew:
     ```bash
     brew update && brew install azure-cli
     ```

2. **Verificación de Bicep:**
   Azure CLI instala e integra Bicep automáticamente. Puede validar que esté disponible ejecutando:
   ```bash
   az bicep --help
   ```

---

## Dependencias de Seguridad y Permisos en Azure

> [!IMPORTANT]
> En alineación con las políticas de gobernanza habituales en entornos corporativos, este despliegue asume un modelo de privilegios mínimos. El script no realiza tareas a nivel de suscripción ni crea grupos de recursos.
> 
> Por lo tanto, es una dependencia obligatoria que:
> 1. El Grupo de Recursos ya se encuentre creado previamente por el administrador de la nube.
> 2. Su cuenta o Service Principal disponga de rol de Colaborador (Contributor) y Administrador de Acceso de Usuario (User Access Administrator) sobre dicho Grupo de Recursos (este último es indispensable para permitir la delegación de roles RBAC en las Identidades Administradas de ADF y Databricks).

---

## Configuración de Parámetros de Despliegue

Los parámetros de configuración se definen en el archivo de parámetros localizado en [/infra/dev/dev.bicepparam]. Deberá editar este archivo y establecer los valores correspondientes a su entorno antes de iniciar el despliegue:

```bicep
using 'main.bicep'

param projectPrefix = 'dataknow' // Prefijo del proyecto para nombrado de recursos (ej: 'dataknow')
param environment = 'dev' // Ambiente del proyecto (ej: 'dev', 'qa', 'prod')
param sqlLocation = 'westus' // Ubicación geográfica exclusiva para Azure SQL Database
param sqlAdminLogin = '' // Nombre de usuario administrador de la base de datos SQL
param sqlAdminPassword = '' // Contraseña del administrador SQL (Se recomienda robusta)
param databricksSkuName = 'premium' // Nivel de precios del workspace de Databricks ('premium' o 'standard')
```

### Descripción Detallada de Parámetros:

* **projectPrefix:** Define la raíz del estándar de nomenclatura corporativa. Ayuda a evitar colisiones globales de nombres en recursos como Storage Accounts o Key Vaults.
* **environment:** Define el sufijo de entorno que se añadirá al nombre de los recursos.
* **sqlLocation:** Región de Azure destinada específicamente a la base de datos transaccional fuente (ej: `westus`, `eastus`).
* **sqlAdminLogin:** Cuenta de inicio de sesión con privilegios máximos en el motor Azure SQL.
* **sqlAdminPassword:** Contraseña de acceso para el inicio de sesión administrador. Esta contraseña es parametrizada de forma segura por Bicep para evitar su exposición en textos planos dentro de los logs de despliegue.
* **databricksSkuName:** Nivel de licenciamiento para el Workspace de Databricks. Se recomienda mantener en `premium` para soportar características de control de acceso avanzado.

---

## Instrucciones para el Despliegue

Siga este procedimiento secuencial para iniciar el despliegue de la infraestructura desde su máquina local:

### Paso 1: Autenticación en la Nube
Abra su terminal y ejecute el proceso de inicio de sesión en Azure CLI:

```bash
az login
```

Esto abrirá una pestaña en su navegador web predeterminado para que ingrese sus credenciales corporativas. Una vez autenticado, la consola listará sus suscripciones asignadas.

### Paso 2: Selección de Suscripción (Si aplica)
Si su cuenta tiene acceso a múltiples suscripciones, asegúrese de seleccionar la correcta donde reside su grupo de recursos:

```bash
az account set --subscription "Nombre-o-ID-de-su-Suscripcion"
```

### Paso 3: Posicionamiento en el Directorio de Trabajo
Navegue con su terminal hacia la carpeta donde están localizados los scripts de infraestructura:

```bash
cd infra/dev
```

### Paso 4: Ejecución del Despliegue a Nivel de Grupo de Recursos
Ejecute la creación del despliegue apuntando al nombre del Grupo de Recursos previamente creado:

```bash
az deployment group create \
  --name "despliegue-infraestructura-dataknow-test-igd" \
  --resource-group "Nombre-De-Su-Grupo-De-Recursos" \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

### Paso 5: Confirmación de Recursos
Una vez finalizada la ejecución de forma exitosa (el estado de salida en consola debe indicar `Succeeded`), puede revisar el resultado visual de su entorno desplegado en la captura provista en [/infra/recursos_aprovisionados_azure_iac.png].
