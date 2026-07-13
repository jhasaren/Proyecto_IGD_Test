# Changelog (Historial de Cambios)

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y este proyecto se adhiere a [SemVer (Direccionamiento de Versiones Semánticas)](https://semver.org/lang/es/).

---

## [Unreleased] (No Publicado)

### Added (Añadido)
* Redacción de la guía completa de gobierno de datos y seguridad en la raíz del proyecto (`guia_gobierno_seguridad_azure.md`), incluyendo políticas de mínimo privilegio y auditoría de accesos.

### Changed (Cambiado)
* Reestructuración del perfil de **Ingeniero de Datos** y **Analista** en la guía de seguridad para utilizar **Roles Personalizados (Custom Roles)** de Azure RBAC, simplificando la administración de permisos recurrentes a nivel de grupo de recursos y contenedores.
* Modificación de la configuración de la cuenta de almacenamiento en la guía para habilitar **OAuth (Azure AD) por defecto** en el Portal de Azure, solucionando el error 403 al listar contenedores con accesos restringidos.

---

## [1.0.0] - 2026-07-09

### Added (Añadido)
* Documentación de la infraestructura en Bicep y guía de despliegue en `infra/README.md`.
* Documentación y empaquetado de pipelines y notebooks de procesamiento (capas Bronze, Silver y Gold) en `pipelines/README.md`.
* Configuración de la orquestación y plantillas de flujo en Azure Data Factory (`orchestration/README.md`).
* Entregables del modelo dimensional (esquema estrella y reportes de calidad en Power BI).

---

## [0.1.0] - 2026-07-03

### Added (Añadido)
* Definición de infraestructura como código (IaC) con plantillas de Azure Bicep (`main.bicep` y `dev.bicepparam`).
* Aprovisionamiento base de recursos en Azure: Storage Account (Data Lake Gen2 con contenedores medallón), Azure Key Vault, Azure SQL Database, Azure Data Factory y Azure Databricks.
* Script de base de datos relacional fuente (`schema_db.sql`) y carga inicial de datos maestros e históricos.
