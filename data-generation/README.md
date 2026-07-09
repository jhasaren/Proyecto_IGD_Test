# Generación de Datos Transaccionales (Dummy Dataset)
**Autor:** John Alexander Sánchez Rengifo
**Fecha de Documentación:** 09/07/2026

Documento de Referencia Principal: Para una explicación detallada de todo el proceso y diseño de la solución, ver [/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf].

Este componente del proyecto se encarga de la simulación, generación y carga de datos transaccionales y de catálogo para el **Escenario C (Salud y Servicios Médicos)** en la base de datos origen.

---

## Requisitos Previos y Dependencias

> [!IMPORTANT]
> Se requiere contar con un entorno aprovisionado en Microsoft Azure. Si no se han creado los recursos cloud, se recomienda seguir primero la guía de Infraestructura como Código (IaC) detallada en [infra/dev].

El entorno debe disponer de los siguientes recursos activos:
* **Azure Databricks Workspace (Premium):** Ejecución de scripts en PySpark.
* **Azure SQL Database (fuente):** Destino relacional para los datos dummy.
* **Azure Storage Account Gen2 (ADLS Gen2):** Con el contenedor `bronze` para el almacenamiento de archivos temporales Parquet.
* **Azure Key Vault:** Gestión de secretos y cadenas de conexión.
* **Azure Data Factory V2 (ADF):** Para el flujo de ingesta y orquestación.

---

## Guía Paso a Paso para la Replicabilidad

### Paso 1: Configurar la Base de Datos Relacional (Azure SQL)
Utilice su cliente SQL predilecto (SSMS, Azure Data Studio, etc.) para conectarse a la instancia de **Azure SQL Database**.

1. Ejecute el script DDL [schema_db.sql] para crear las tablas relacionales.
2. El diseño lógico que describe estas tablas y sus llaves foráneas se encuentra disponible en [/docs/modelo_entidad_relacion.png].

---

### Paso 2: Cargar y Configurar Notebooks en Azure Databricks

1. Ingrese a su Workspace de Azure Databricks.
2. Importe el archivo de tipo bundle comprimido [data-generation_solo_notebooks.dbc] en su carpeta personal de Workspace.
3. Suba el archivo de configuración [config.json] **al mismo nivel (en la raíz)** de los notebooks importados.

---

### Paso 3: Personalizar Parametrización en `config.json`

Edite el archivo [config.json] con los valores adecuados a su entorno:

```json
{
  "_descripcion": "Configuración centralizada para generación de datos dummy - Prueba Dataknow IGD.",
  "schema_db_local": "dbo",
  "storage_base": "abfss://bronze@dataknowdevdl.dfs.core.windows.net",
  "random_seed": 133007052026,
  "start_date": "2023-07-05",
  "end_date":   "2026-07-05"
}
```

#### Descripción de Parámetros:
* `schema_db_local`: El nombre del esquema de base de datos donde desplegó las tablas (usualmente `dbo`).
* `storage_base`: URI del contenedor `bronze` en ADLS Gen2 donde se escribirán temporalmente los archivos Parquet. Debe seguir la nomenclatura de driver seguro `abfss://`.
* `random_seed`: Semilla para garantizar la reproducibilidad y consistencia en la generación pseudoaleatoria.
* `start_date` / `end_date`: Rango temporal del historial clínico y de agendamiento a generar.

---

### Paso 4: Ejecución de Notebooks Generadores
Ejecute secuencialmente los notebooks importados en Databricks (del **01 al 06**).

> [!TIP]
> Al finalizar las ejecuciones, valide en el almacenamiento ADLS Gen2 que se hayan generado exactamente **11 archivos** en formato Parquet correspondientes a cada una de las tablas transaccionales. En caso de requerirlo, en este directorio se incluye un respaldo comprimido de estos datos en [data_parquet.zip].

---

### Paso 5: Despliegue de la Orquestación en Azure Data Factory (ADF)

Para mover eficientemente los archivos Parquet generados en el Data Lake hacia las tablas físicas de Azure SQL Database:

1. Importe el pipeline comprimido localizado en la ruta [/orchestration/PIPELINE_000_ORQ_CARGA_DATOS_DUMMY.zip].
2. Durante el proceso de importación, configure o asocie los **Linked Services** (Servicios Vinculados) correspondientes a su base de datos origen y al almacenamiento de ADLS Gen2.
3. Puede realizar validaciones de tipo *Debug* en ADF sobre las actividades individuales de carga para asegurar la correcta lectura de los archivos Parquet.

---

### Paso 6: Ejecución y Validación General

Una vez validadas las conexiones, dispare la ejecución manual del pipeline principal `000_ORQ` desde ADF y espere hasta que su estado sea exitoso.

Para certificar que el proceso de carga fue completo y no se presentaron pérdidas de registros, ejecute la siguiente sentencia de auditoría SQL en su base de datos destino:

```sql
SELECT 'PAIS' AS TABLA, COUNT(*) AS CANT FROM dbo.PAIS
UNION ALL
SELECT 'DEPARTAMENTO' AS TABLA, COUNT(*) FROM dbo.DEPARTAMENTO
UNION ALL
SELECT 'CIUDAD' AS TABLA, COUNT(*) FROM dbo.CIUDAD
UNION ALL
SELECT 'EPS' AS TABLA, COUNT(*) FROM dbo.EPS
UNION ALL
SELECT 'RED_SEDES' AS TABLA, COUNT(*) FROM dbo.RED_SEDES
UNION ALL
SELECT 'PAC_REGISTRO' AS TABLA, COUNT(*) FROM dbo.PAC_REGISTRO
UNION ALL
SELECT 'MED_PLANTA' AS TABLA, COUNT(*) FROM dbo.MED_PLANTA
UNION ALL
SELECT 'HCE_ENCUENTROS' AS TABLA, COUNT(*) FROM dbo.HCE_ENCUENTROS
UNION ALL
SELECT 'GCM_CAMAS' AS TABLA, COUNT(*) FROM dbo.GCM_CAMAS
UNION ALL
SELECT 'FAR_DISPENSACION' AS TABLA, COUNT(*) FROM dbo.FAR_DISPENSACION
UNION ALL
SELECT 'AGE_CITAS' AS TABLA, COUNT(*) FROM dbo.AGE_CITAS;
```

#### Métricas Esperadas de Carga:

| Nombre de la Tabla | Registros Esperados | Tipo de Tabla / Datos |
| :--- | :--- | :--- |
| **PAIS** | 3 | Catálogo Maestro |
| **DEPARTAMENTO** | 9 | Catálogo Maestro |
| **CIUDAD** | 18 | Catálogo Maestro |
| **EPS** | 12 | Catálogo Maestro |
| **RED_SEDES** | 82 | Entidad Maestro |
| **PAC_REGISTRO** | 100,000 | Entidad Maestro (Pacientes) |
| **MED_PLANTA** | 2,000 | Entidad Maestro (Médicos) |
| **HCE_ENCUENTROS** | 2,000,000 | Transaccional (Historias Clínicas) |
| **GCM_CAMAS** | 683,904 | Transaccional (Ocupación Diaria) |
| **FAR_DISPENSACION** | 3,000,000 | Transaccional (Farmacia) |
| **AGE_CITAS** | 1,500,000 | Transaccional (Agendamiento) |

> [!NOTE]
> La correspondencia exacta de estos conteos en su base de datos confirma que el proceso de ingesta e integridad referencial transaccional finalizó de manera exitosa.
