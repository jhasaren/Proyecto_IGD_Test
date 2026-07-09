# Pipelines de Procesamiento de Datos y Calidad (Medallon Architecture)

**Autor:** John Alexander Sánchez Rengifo
**Fecha de Documentación:** 09/07/2026

Documento de Referencia Principal: Para una explicación detallada de todo el proceso y diseño de la solución, ver [/docs/Arquitectura_Solucion_Analitica_Test_DataKnow.pdf].

Este componente contiene el código de procesamiento distribuido desarrollado en Python y Sppark y las reglas del Framework de Calidad de Datos (QA) para la transformación de datos entre las capas Bronze, Silver y Gold, así como los entregables del modelo dimensional.

---

## Contenido de la Carpeta

En este directorio se agrupan las evidencias de ejecución, logs de auditoría, conjuntos de datos de salida y el paquete de código para importar en Azure Databricks:

* **modelo_dimensional/:** Directorio que contiene el diseño del modelo analítico estrella y el archivo origen de Power BI (.pbix) con el tablero Healthnet y los reportes de calidad de datos.
* **dataknow_project.dbc:** Paquete comprimido en formato nativo de Databricks (Databricks Archive) listo para ser importado en el Workspace. Contiene los notebooks estructurados del pipeline.
* **dataknow_project.zip:** Paquete comprimido con los archivos fuente de los notebooks en formato Python plano (.py).
* **dataknow_project_html.zip:** Respaldo comprimido de las ejecuciones de los notebooks exportadas en formato HTML, permitiendo auditar visualmente los comandos y sus salidas correspondientes sin necesidad de un clúster activo.
* **evidencia_ejecucion_exitosa.png:** Imagen que certifica el correcto funcionamiento y ejecución secuencial del pipeline en Azure Databricks.
* **log_ejecucion_qa_silver.txt:** Log de salida con el consolidado y detalle de las 28 reglas de calidad de datos (completitud, consistencia, exactitud y oportunidad) aplicadas sobre las entidades de la capa Silver.
* **log_ejecucion_qa_gold.txt:** Log de salida con las validaciones de calidad (integridad referencial, consistencia de negocio y unicidad) aplicadas sobre el modelo dimensional en la capa Gold. En total 13 validaciones.
* **vistas_silver_qa_parquet.zip:** Archivos generados de la capa Silver con la estructura de metadatos de QA adjunta en formato Parquet.
* **vistas_gold_parquet.zip:** Archivos resultantes de la capa Gold estructurados como dimensiones y hechos listos para análisis en formato Parquet.

---

## Descripcion de los Notebooks (dataknow_project.dbc)

Al realizar la importación del archivo DBC en Azure Databricks, se cargarán los siguientes cuatro notebooks de procesamiento estructurado, los cuales deben ejecutarse de manera secuencial:

### 01_Procesamiento_Silver_Entidades
* **Objetivo:** Tomar los datos crudos depositados en la capa Bronze, realizar transformaciones básicas de normalización (estandarización de nombres de columnas a mayúsculas, casteo de formatos de fecha y marcas temporales) y guardar los datasets limpios en el contenedor Silver.

### 02_Procesamiento_Silver_QA
* **Objetivo:** Aplicar las reglas del Framework de Calidad de Datos sobre las entidades en la capa Silver. Cada registro es evaluado en términos de completitud, exactitud, consistencia y oportunidad, añadiendo columnas de metadatos con el estado (PASS/FAIL) y los códigos de error encontrados para auditoría.

### 03_Procesamiento_Gold_Entidades
* **Objetivo:** Aplicar las reglas de negocio complejas y agregaciones para estructurar el modelo dimensional estrella (Capa Gold). Genera las dimensiones y tablas de hechos.

### 04_Procesamiento_Gold_QA
* **Objetivo:** Ejecutar las evaluaciones de calidad de datos específicas de la capa Gold. Valida la unicidad de las llaves primarias de negocio de las dimensiones, la consistencia lógica de las métricas de hecho y la ausencia de registros huérfanos (integridad referencial entre tablas de hechos y dimensiones).

---

## Instrucciones de Replicacion en Databricks

1. Ingrese a su entorno de **Azure Databricks**.
2. Diríjase a la sección **Workspace**, haga clic secundario sobre su carpeta de usuario y seleccione **Import**.
3. Seleccione el archivo local [dataknow_project.dbc] para cargar la estructura de notebooks.
4. Asegúrese de tener el clúster activo con acceso al Data Lake (ADLS Gen2) antes de proceder con las ejecuciones manuales o la configuración de triggers en Azure Data Factory.
