# Orquestacion y Pipelines en Azure Data Factory

**Autor:** John Alexander Sánchez Rengifo
**Fecha de Documentación:** 09/07/2026

Documento de Referencia Principal: Para una explicación detallada de todo el proceso y diseño de la solución, ver [/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf].

Este componente contiene las definiciones y plantillas de los flujos de orquestación diseñados en Azure Data Factory (ADF) para automatizar el ciclo de vida de los datos del proyecto.

---

## Contenido de la Carpeta

Las plantillas de los pipelines de Azure Data Factory se entregan empaquetadas en formato comprimido (.zip) para facilitar su importación:

1. **PIPELINE_000_ORQ_CARGA_DATOS_DUMMY.zip:** 
   Pipeline orquestador encargado de automatizar la carga de los archivos Parquet generados hacia las tablas físicas de la base de datos Azure SQL (fuente transaccional). Este proceso complementa la fase detallada en la carpeta de generación de datos.

2. **PIPELINE_000_ORQ_GENERAL_DATAKNOW_PROJECT.zip:** 
   Pipeline principal end-to-end que orquesta el procesamiento global en la arquitectura Medallón:
   * **Extracción (Capa Bronze):** Copia los datos desde Azure SQL Database hacia el contenedor bronze en ADLS Gen2.
   * **Procesamiento Silver (Limpieza y QA):** Dispara la ejecución de los notebooks de Databricks para la estructuración y validación de reglas de calidad de datos en la capa Silver.
   * **Procesamiento Gold (Analítico y QA Semántico):** Dispara la ejecución de los notebooks de Databricks para construir las dimensiones y tablas de hechos en la capa Gold y las evaluaciones de calidad de esta capa.

---

## Requisitos de Conectividad (Linked Services)

Antes de realizar la importación de las plantillas en Azure Data Factory, asegúrese de tener creadas y probadas las siguientes conexiones (Servicios Vinculados o Linked Services) en su entorno de ADF:

* **LS_AzureSQLDatabase:** Conexión segura hacia la base de datos Azure SQL Serverless (fuente de datos).
* **LS_AzureBlobStorage_ADLSGen2:** Conexión hacia el Storage Account Gen2 con autenticación basada en Identidad Administrada o clave de acceso.
* **LS_AzureDatabricks:** Conexión hacia el Workspace de Azure Databricks con autenticación mediante Access Token o Identidad Administrada, configurada para interactuar con su clúster de procesamiento.
* **LS_AzureKeyVault:** Conexión al Key Vault para la resolución de secretos en tiempo de ejecución.

---

## Instrucciones para la Importación de Pipelines

Siga este procedimiento simplificado para importar las plantillas en Azure Data Factory Studio:

1. **Importar Plantilla:** En la sección **Author** de ADF Studio, haga clic en el botón **+** y seleccione **Pipeline -> Importar desde plantilla** para cargar el archivo ZIP del pipeline.
2. **Asociar Conexiones:** En el formulario de importación, asocie las conexiones requeridas (Linked Services) con los servicios correspondientes creados en su entorno local.
3. **Publicar Cambios:** Confirme la carga con **Use this template** y presione **Publish all** para guardar de forma definitiva los pipelines.

---

## Pruebas y Validación de Ejecución

* Puede ejecutar pruebas parciales utilizando la funcionalidad de **Debug** en el diseñador visual de ADF.
* Las evidencias gráficas de las ejecuciones exitosas de estos pipelines en un entorno real se encuentran disponibles en los archivos de captura:
  * Evidencia de carga de datos dummy: [/orchestration/evidencia_ejecucion_pipeline_datos_dummy.png]
  * Evidencia de flujo general de procesamiento (vista 1): [/orchestration/evidencia_ejecucion_pipeline_dataknow_project_1.png]
  * Evidencia de flujo general de procesamiento (vista 2): [/orchestration/evidencia_ejecucion_pipeline_dataknow_project_2.png]
