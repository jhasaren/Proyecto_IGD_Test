# Prueba Técnica DataKnow - Ingeniería de Datos
**Participante:** John Alexander Sánchez Rengifo - [jhonalexander90@gmail.com](mailto:jhonalexander90@gmail.com)
**Fecha de Documentación:** 09/07/2026

Documento de Referencia Principal: Para una explicación detallada de todo el proceso y diseño de la solución, ver [/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf].

---

## 1. Descripción del Proyecto & Escenario Seleccionado

Se seleccionó el **ESCENARIO C — SALUD Y SERVICIOS MÉDICOS** debido a las siguientes consideraciones estratégicas y técnicas:
* **Comprensión del Dominio de Negocio:** Permite definir con mayor claridad y coherencia las reglas de negocio en la capa semántica final (**Gold**).
* **Volumen y Complejidad de los Datos:** Es el escenario con el mayor volumen de datos transaccionales, lo cual representa un reto idóneo para validar el diseño de arquitecturas escalables.
* **Modelo Entidad-Relación Intuitivo:** Las relaciones lógicas entre las entidades (pacientes, médicos, sedes, encuentros y camas) permiten construir un modelo dimensional robusto y de alto valor analítico.

---

## 2. Estructura del Repositorio

El proyecto está organizado de la siguiente manera:

```text
Proyecto_Pruebas_IGD/
├── README.md                                 # Este archivo (documentación general)
├── docs/                                     # Documentación gráfica y técnica
│   ├── modelo_entidad_relacion.png           # Diagrama ER de la base de datos fuente
│   └── Arquitectura_Solucion_Analitica_Test_DataKnow.pdf # Documento explicativo de todo el proceso y diseño de arquitectura
├── data-generation/                          # Componentes de generación de datos sintéticos
│   ├── config.json                           # Configuración del rango de fechas y paths de carga
│   ├── schema_db.sql                         # Script DDL de creación de tablas en Azure SQL
│   ├── evidencia_carga_exitosa.png           # Captura de pantalla de carga exitosa
│   ├── data-generation_completo.zip          # Código fuente completo para la generación de datos
│   ├── data-generation_solo_notebooks.dbc    # Exportación DBC de Databricks con notebooks de generación
│   └── data_parquet.zip                      # Respaldo de los datos dummy generados en formato Parquet
├── infra/                                    # Infraestructura como Código (IaC)
│   ├── recursos_aprovisionados_azure_iac.png # Evidencia de recursos desplegados en Azure
│   └── dev/                                  # Plantillas Bicep para despliegue en ambiente de Desarrollo
│       ├── main.bicep                        # Script principal de aprovisionamiento de Azure
│       ├── dev.bicepparam                    # Parámetros del entorno de desarrollo
│       └── main.json                         # Compilación ARM Template resultante
├── orchestration/                            # Orquestación de datos con Azure Data Factory (ADF)
│   ├── PIPELINE_000_ORQ_CARGA_DATOS_DUMMY.zip     # Pipeline de inicialización y carga transaccional
│   ├── PIPELINE_000_ORQ_GENERAL_DATAKNOW_PROJECT.zip # Pipeline general de ejecución de notebooks
│   ├── evidencia_ejecucion_pipeline_datos_dummy.png  # Evidencia de ADF cargando datos
│   ├── evidencia_ejecucion_pipeline_dataknow_project_1.png
│   └── evidencia_ejecucion_pipeline_dataknow_project_2.png
└── pipelines/                                # Código PySpark de procesamiento y calidad de datos
    ├── dataknow_project.dbc                  # Notebooks empaquetados para importar a Databricks
    ├── dataknow_project.zip                  # Código fuente de notebooks en formato estructurado
    ├── dataknow_project_html.zip             # Exportación en HTML de las ejecuciones de los notebooks
    ├── evidencia_ejecucion_exitosa.png       # Pantallazo de ejecución exitosa en Databricks
    ├── log_ejecucion_qa_silver.txt           # Logs detallados del framework de calidad de datos en Silver
    ├── log_ejecucion_qa_gold.txt             # Logs detallados del framework de calidad de datos en Gold
    ├── vistas_silver_qa_parquet.zip          # Vistas resultantes de la zona Silver QA en Parquet
    ├── vistas_gold_parquet.zip                # Vistas de las dimensiones y hechos de la zona Gold
    └── modelo_dimensional/                   # Estructura del modelo dimensional analítico
        ├── modelo_dimensional_gold.png       # Diagrama de modelo de datos estrella (Dimensiones y Hechos)
        └── tablero_pbi/                      # Entregables del tablero Power BI
            ├── Tablero_Healthnet.pbix        # Archivo de Power BI Desktop con reportes y dashboards
            ├── 01_Vista_Ocupacion_Camas.png  # Reporte de capacidad y ocupación
            ├── 02_Vista_Gestion_Alertas.png  # Reporte de alertas críticas e inconsistencias de datos
            ├── 03_Vista_Costos_Atencion.png  # Análisis financiero y costos de atención médica
            ├── 04_Vista_Perfil_Paciente.png  # Perfil sociodemográfico de pacientes
            ├── 05_Maestro_QA_Ejecuciones.png # Dashboard del maestro de ejecuciones de calidad
            └── 06_Detalle_QA_Silver.png      # Dashboard con el detalle de errores por regla de calidad
```

---

## 3. Diseño de la Arquitectura Cloud (Azure & IaC con Bicep)

La arquitectura de la solución sigue las mejores prácticas de la **Cloud Adoption Framework (CAF)** y las arquitecturas de referencia de Microsoft Azure para analítica moderna.

### 3.1 Diagrama de Arquitectura Lógica

ver '/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf' slide 2

### 3.2 Componentes Aprovisionados
* **Azure SQL Database (Serverless):** Motor relacional que sirve como fuente transaccional OLTP. Permite un escalado dinámico de 0.5 a 1 vCore con pausa automática a los 60 minutos para optimizar costos de computación.
* **Azure Storage Account Gen2 (ADLS Gen2):** Cuenta de almacenamiento optimizada para Big Data con habilitación del Espacio de Nombres Jerárquico (`isHnsEnabled: true`). Organizada en tres contenedores correspondientes a la **Arquitectura Medallón: `bronze`, `silver`, `gold`**.
* **Azure Data Factory V2:** Orquestador principal encargado de ejecutar la ingesta desde el motor SQL hacia el Data Lake y de disparar secuencialmente el procesamiento en Databricks (orquestador).
* **Azure Databricks (Premium SKU):** Motor de cálculo distribuido ejecutando PySpark para procesar, limpiar y estructurar los datos analíticos.
* **Azure Key Vault:** Almacenamiento centralizado y seguro de secretos, llaves y cadenas de conexión.
* **Asignaciones de Roles RBAC Automatizadas:** El despliegue de Bicep asigna de manera autónoma los permisos **Storage Blob Data Contributor** y **Key Vault Secrets User** a las identidades administradas (Managed Identities) de ADF y Databricks, eliminando la necesidad de quemar llaves de acceso en el código.

---

## 4. Modelo de Datos Relacional (Fuente)

El modelo transaccional configurado en **Azure SQL Database** se estructura en las siguientes tablas definidas en [/data-generation/schema_db.sql]

ver '/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf' slide 4

---

## 5. Orquestación y Pipelines de Datos (ADF & Databricks)

El ciclo de vida del dato se implementa bajo el patrón **Medallion Architecture**, orquestado por **Azure Data Factory V2** y ejecutado sobre **Azure Databricks (PySpark)**.

```
                  ┌──────────────┐
                  │  Azure SQL   │
                  │  (Source)    │
                  └──────┬───────┘
                         │ (ADF Ingesta)
                         ▼
                 ┌───────────────┐
                 │  Lake Bronze  │ (Parquet / Raw schema)
                 └───────┬───────┘
                         │ (PySpark: Estructuración & QA)
                         ▼
                 ┌───────────────┐
                 │  Lake Silver  │ (Delta / Tablas limpias + QA metadata)
                 └───────┬───────┘
                         │ (PySpark: Agregación, Estrellas & QA Semántica)
                         ▼
                 ┌───────────────┐
                 │   Lake Gold   │ (Delta / Dimensiones y Hechos para BI)
                 └───────────────┘
```

### 5.1 Capa Bronze (Raw)
* **Ingesta:** Los pipelines de Data Factory leen las tablas desde Azure SQL y las escriben en el contenedor `bronze` en formato Parquet, conservando los datos tal como llegan de la fuente transaccional. Se adicionan 3 columnas para trazabilidad y auditoria.

### 5.2 Capa Silver (Data Quality & Clean)
* **Normalización:** Homogeneización de nombres de columnas a mayúsculas, estandarización de tipos de datos, casteo de marcas de tiempo y fechas.
* **Data Quality Framework (QA):** Se aplica un motor de calidad de datos (clase propia reciclada de proyectos anteriores) desarrollado en PySpark que valida reglas de negocio a nivel de fila y a nivel de volumen. Se evalúan 4 dimensiones críticas:
  1. **Completitud:** Campos clave no nulos (ej. `ESPECIALIDAD_ATENDIDA`, `ID_CIUDAD`, `GENERO`).
  2. **Consistencia (Integridad Referencial):** Validación de huérfanos entre llaves primarias y foráneas (ej. que las sedes existan en la tabla de ciudades).
  3. **Exactitud:** Validación lógica de rangos (ej. edad en rango normal) o coherencia (ej. jornada laboral definida, hora de inicio de atención válida).
  4. **Oportunidad (Frescura):** Validación de frescura transaccional contra un umbral de 48 horas.
* **Manejo de Errores:** Los registros que fallan las validaciones son etiquetados con metadatos de QA detallando el motivo del fallo, permitiendo analizarlos en el tablero analítico sin detener la ejecución del pipeline (enfoque tolerante a fallos). Los resultados se almacenan en formato Delta.

### 5.3 Capa Gold (Dimensional Analítico)
* **Estructura Analítica:** Los datos limpios de la capa Silver se consolidan en un **Modelo Dimensional** idóneo para el consumo de analistas de negocio y herramientas de BI.
* **Modelo Semántico:** Se optimizan las tablas finales en formato Delta con agregaciones previas para simplificar la capa de visualización.

---

## 6. Reporte de Calidad de Datos (Análisis de Ejecución)

El framework de QA genera logs detallados para cada corrida. Los resultados evidenciados en la última entrega muestran los siguientes estados de calidad de datos:

### 6.1 Capa Silver ([/pipelines/log_ejecucion_qa_silver.txt])
* **Total Validaciones Ejecutadas:** 28
  * **Exitosas (PASS):** 19
  * **Fallidas (FAIL):** 9
* **Principales Hallazgos (Inconsistencias Detectadas):**
  * `hce_encuentros | completitud`: Se hallaron 89,686 registros (4.5% del total de 2,000,000) con el campo `ESPECIALIDAD_ATENDIDA` en nulo.
  * `age_citas | exactitud`: Se identificaron 37,313 citas (2.5% de 1,500,000) con una hora de inicio de atención inválida.
  * `hce_encuentros | exactitud`: 6,000 registros (0.3%) presentaron anomalías en el diagnóstico principal con código CIE10 inválido.
  * `hce_encuentros | exactitud`: 5,000 encuentros (0.2%) presentaron un valor facturado menor a cero (inconsistencia financiera).
  * `med_planta | exactitud`: 200 médicos (10% de 2,000) no cuentan con jornada laboral definida.
  * `pac_registro | exactitud`: 7,000 registros de pacientes (7.0% de 100,000) arrojaron un rango de edad anormal o inválido.
  * **Oportunidad (Frescura):** Las tablas transaccionales (`age_citas`, `gcm_camas`, `hce_encuentros`) fallaron el umbral de 48 horas debido a que los datos simulados tienen como fecha máxima de transacción el 2026-07-04 23:59 (4 días de retraso frente al tiempo de ejecución).

### 6.2 Capa Gold ([/pipelines/log_ejecucion_qa_gold.txt])
* **Total Validaciones Ejecutadas:** 13
  * **Exitosas (PASS):** 11
  * **Fallidas (FAIL):** 2
* **Principales Hallazgos:**
  * `fact_consultas | consistencia`: Se detectaron 146,532 registros huérfanos (7.4%) donde el `ID_PACIENTE` no tiene un registro correspondiente en la dimensión de pacientes (`dim_pacientes`) de la zona Gold.
  * `fact_tiempos_espera | consistencia`: Se encontraron 26,531 registros huérfanos (7.1%) con el mismo problema de integridad referencial de `ID_PACIENTE` contra la dimensión de pacientes.

---

## 7. Modelo Dimensional Analítico (Gold)

En la capa Gold, la información se desnormaliza para dar vida a un modelo dimensional compuesto por las entidades requeridas (especificadas en la necesidad de negocio):

ver '/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf' slide 36



---

## 8. Reportes y Dashboards (Power BI)

El entregable analítico final se construyó en **Power BI** ([/pipelines/modelo_dimensional/tablero_pbi/Tablero_Healthnet.pbix]) y cuenta con las siguientes vistas funcionales:

1. **Vista de Ocupación de Camas:** Monitoreo y tendencias de ocupación de camas generales, UCI, cirugía y urgencias por sede y complejidad.
2. **Vista de Gestión de Alertas:** Detección anomalías epidemiológicas y tiempos de espera por sede.
3. **Vista de Gestión de Facturación:** Desglose del valor facturado por diagnostico y datos de facturacion y cartera por ciudad.
4. **Vista de Perfil de Paciente:** Análisis demográfico de la población atendida (edad, género, estrato, distribución geográfica). Clasificacion de complejidad del paciente según historico de atenciones.
5. **Dashboard Maestro de QA:** Resumen ejecutivo de las validaciones de calidad de datos, métricas generales de registros conformes vs. erróneos y distribución de estados PASS/FAIL.
6. **Dashboard Detalle de QA Silver:** Visualización detallada para rastrear registros con fallos de completitud, exactitud y consistencia, útil para auditorías de datos y remediación en la base fuente. Para el ejercicio solo se muestran dos tablas (hce_encuentros y pac_registro).

---

## 9. Instrucciones de Despliegue y Ejecución

### 9.1 Despliegue de Infraestructura

ver [README.md](/infra/README.md)

### 9.2 Inicialización de la Base de Datos Fuente

ver [README.md](/data-generation/README.md)

### 9.3 Importación de Notebooks a Databricks

ver [README.md](/pipelines/README.md)

### 9.4 Configuración de Azure Data Factory

ver [README.md](/orchestration/README.md)
