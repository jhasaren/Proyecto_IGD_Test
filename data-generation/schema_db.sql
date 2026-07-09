-- =========================================================================
-- ESTRUCTURACIÓN DE BASE DE DATOS TRANSACCIONAL - MODELO RELACIONAL
-- Proyecto: Pruebas IGD - Escenario C (Salud y Servicios Médicos)
-- Descripción: Creación de tablas de catálogo y transaccionales para
--              fuente de datos clínicos en Azure SQL Database.
-- Orden de Ejecución: Diseñado secuencialmente para evitar conflictos de FK.
-- =========================================================================

-- =========================================================================
-- SECCIÓN 1: TABLAS DE CATÁLOGO (MAESTRAS)
-- =========================================================================

-- 1.1. PAIS
CREATE TABLE dbo.PAIS (
    id_pais INTEGER IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- 1.2. DEPARTAMENTO
CREATE TABLE dbo.DEPARTAMENTO (
    id_depto INTEGER IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_pais INTEGER NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES PAIS(id_pais)
);

-- 1.3. CIUDAD
CREATE TABLE dbo.CIUDAD (
    id_ciudad INTEGER IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_depto INTEGER NOT NULL,
    FOREIGN KEY (id_depto) REFERENCES DEPARTAMENTO(id_depto)
);

-- 1.4. EPS
CREATE TABLE dbo.EPS (
    id_eps INTEGER IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    id_pais INTEGER NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES dbo.PAIS(id_pais)
);


-- =========================================================================
-- SECCIÓN 2: TABLAS BASE (ENTIDADES PRINCIPALES)
-- =========================================================================

-- 2.1. RED_SEDES
CREATE TABLE dbo.RED_SEDES (
    id_sede INTEGER IDENTITY(1,1) PRIMARY KEY,
    nom_sede VARCHAR(150) NOT NULL,
    tip_sede VARCHAR(50) NOT NULL,
    id_ciudad INTEGER NOT NULL,
    id_pais INTEGER NOT NULL,
    cap_camas_gen INTEGER NOT NULL DEFAULT 0,
    cap_camas_uci INTEGER NOT NULL DEFAULT 0,
    cap_camas_cirugia INTEGER NOT NULL DEFAULT 0,
    cap_camas_urg INTEGER NOT NULL DEFAULT 0,
    nivel_complejidad VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_ciudad) REFERENCES CIUDAD(id_ciudad),
    FOREIGN KEY (id_pais) REFERENCES PAIS(id_pais)
);

-- 2.2. PAC_REGISTRO
CREATE TABLE dbo.PAC_REGISTRO (
    pac_id INTEGER IDENTITY(1,1) PRIMARY KEY,
    tip_doc VARCHAR(10) NOT NULL,
    num_doc_hash VARCHAR(64) NOT NULL, -- Almacenará hashes SHA-256
    fec_nac DATE NOT NULL,
    genero VARCHAR(20) NOT NULL,
    id_ciudad_res INTEGER NOT NULL,
    tip_aseguradora VARCHAR(50) NOT NULL,
    id_eps INTEGER NULL,
    estrato_socioec INTEGER NOT NULL,
    fec_primer_atencion DATE NULL,
    activo CHAR(1) NOT NULL DEFAULT 'S',
    CONSTRAINT chk_pac_activo CHECK (activo IN ('S', 'N')),
    FOREIGN KEY (id_ciudad_res) REFERENCES CIUDAD(id_ciudad),
    FOREIGN KEY (id_eps) REFERENCES EPS(id_eps)
);

-- 2.3. MED_PLANTA
CREATE TABLE dbo.MED_PLANTA (
    med_id INTEGER IDENTITY(1,1) PRIMARY KEY,
    esp_principal VARCHAR(150) NOT NULL,
    esp_secundaria VARCHAR(150) NULL,
    id_sede INTEGER NOT NULL,
    fec_ingreso DATE NOT NULL,
    tip_contrato VARCHAR(50) NULL,
    jornada VARCHAR(30) NULL,
    estado_activo CHAR(1) NOT NULL DEFAULT 'S',
    CONSTRAINT chk_med_estado_activo CHECK (estado_activo IN ('S', 'N')),
    FOREIGN KEY (id_sede) REFERENCES RED_SEDES(id_sede)
);


-- =========================================================================
-- SECCIÓN 3: TABLAS TRANSACCIONALES (REGISTROS CLÍNICOS Y AGENDAMIENTO)
-- =========================================================================

-- 3.1. HCE_ENCUENTROS
CREATE TABLE dbo.HCE_ENCUENTROS (
    id_encuentro INTEGER IDENTITY(1,1) PRIMARY KEY,
    pac_id INTEGER NOT NULL,
    med_id INTEGER NOT NULL,
    id_sede INTEGER NOT NULL,
    fec_registro DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_inicio_atencion DATETIME2(0) NULL,
    fec_egreso DATETIME2(0) NULL,
    tip_consulta VARCHAR(50) NOT NULL,
    esp_atendida VARCHAR(150) NULL,
    diag_principal_cie10 VARCHAR(10) NOT NULL,
    diag_sec1_cie10 VARCHAR(10) NULL,
    cod_procedimientos VARCHAR(250) NULL,
    vr_facturado DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    estado_factura VARCHAR(30) NOT NULL,
    FOREIGN KEY (pac_id) REFERENCES PAC_REGISTRO(pac_id),
    FOREIGN KEY (med_id) REFERENCES MED_PLANTA(med_id),
    FOREIGN KEY (id_sede) REFERENCES RED_SEDES(id_sede)
);

-- 3.2. GCM_CAMAS
CREATE TABLE dbo.GCM_CAMAS (
    id_registro_cama INTEGER IDENTITY(1,1) PRIMARY KEY,
    id_sede INTEGER NOT NULL,
    tip_unidad VARCHAR(50) NOT NULL,
    fec_hora_registro DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    num_camas_ocupadas INTEGER NOT NULL DEFAULT 0,
    num_camas_disp INTEGER NOT NULL DEFAULT 0,
    num_camas_mant INTEGER NOT NULL DEFAULT 0,
    motivo_indisponibilidad VARCHAR(250) NULL,
    FOREIGN KEY (id_sede) REFERENCES RED_SEDES(id_sede)
);

-- 3.3. FAR_DISPENSACION
CREATE TABLE dbo.FAR_DISPENSACION (
    id_dispensacion INTEGER IDENTITY(1,1) PRIMARY KEY,
    id_encuentro INTEGER NOT NULL,
    pac_id INTEGER NOT NULL,
    id_sede INTEGER NOT NULL,
    fec_dispensacion DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cod_medicamento VARCHAR(50) NOT NULL,
    nom_medicamento VARCHAR(150) NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    vr_unitario DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    tip_prescripcion VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_encuentro) REFERENCES HCE_ENCUENTROS(id_encuentro),
    FOREIGN KEY (pac_id) REFERENCES PAC_REGISTRO(pac_id),
    FOREIGN KEY (id_sede) REFERENCES RED_SEDES(id_sede)
);

-- 3.4. AGE_CITAS
CREATE TABLE dbo.AGE_CITAS (
    id_cita INTEGER IDENTITY(1,1) PRIMARY KEY,
    pac_id INTEGER NOT NULL,
    med_id INTEGER NOT NULL,
    id_sede INTEGER NOT NULL,
    fec_agendamiento DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_cita_programada DATE NOT NULL,
    hra_cita_programada TIME NOT NULL,
    hra_llegada_paciente TIME NULL,
    hra_inicio_atencion TIME NULL,
    esp_solicitada VARCHAR(150) NOT NULL,
    tip_cita VARCHAR(50) NOT NULL,
    estado_cita VARCHAR(30) NOT NULL,
    FOREIGN KEY (pac_id) REFERENCES PAC_REGISTRO(pac_id),
    FOREIGN KEY (med_id) REFERENCES MED_PLANTA(med_id),
    FOREIGN KEY (id_sede) REFERENCES RED_SEDES(id_sede)
);
