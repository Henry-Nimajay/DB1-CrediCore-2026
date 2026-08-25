-- ============================================================================
-- PROYECTO CREDICORE - FASE 1: CIEMENTOS DE TITANIO (DDL Y DOMINIOS)
-- MOTOR: MICROSOFT SQL SERVER | CLIENTE: DBEAVER
-- USUARIO: admin_credicore
-- ============================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'CrediCoreDB')
BEGIN
    CREATE DATABASE CrediCoreDB;
END
GO

USE CrediCoreDB;
GO

-- 2. ESQUEMAS DE SEGURIDAD Y NEGOCIO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Operaciones')
BEGIN
    EXEC('CREATE SCHEMA Operaciones;');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Garantias')
BEGIN
    EXEC('CREATE SCHEMA Garantias;');
END
GO

-- 3. TABLA: Operaciones.Clientes
IF OBJECT_ID(N'Operaciones.Clientes', N'U') IS NOT NULL
    DROP TABLE Operaciones.Clientes;
GO

CREATE TABLE Operaciones.Clientes (
    IdCliente      INT IDENTITY(1,1)   NOT NULL,
    DPI            VARCHAR(13)         NOT NULL,
    Nombres        VARCHAR(100)        NOT NULL,
    Apellidos      VARCHAR(100)        NOT NULL,
    Telefono       VARCHAR(15)         NOT NULL,
    Correo         VARCHAR(150)        NOT NULL,
    
    CONSTRAINT PK_Clientes_IdCliente PRIMARY KEY CLUSTERED (IdCliente),
    CONSTRAINT UQ_Clientes_DPI UNIQUE (DPI)
);
GO

-- 4. TABLA: Garantias.Vehiculos
IF OBJECT_ID(N'Garantias.Vehiculos', N'U') IS NOT NULL
    DROP TABLE Garantias.Vehiculos;
GO

CREATE TABLE Garantias.Vehiculos (
    IdVehiculo         INT IDENTITY(1,1)   NOT NULL,
    Modelo             VARCHAR(50)         NOT NULL,
    Marca              VARCHAR(50)         NOT NULL,
    Anio               INT                 NOT NULL,
    Color              VARCHAR(30)         NOT NULL,
    NumeroTitulo       VARCHAR(30)         NOT NULL,
    Placa              VARCHAR(15)         NOT NULL,
    NumeroChasis       VARCHAR(30)         NOT NULL,

    CONSTRAINT PK_Vehiculos_IdVehiculo PRIMARY KEY CLUSTERED (IdVehiculo),
    CONSTRAINT CHK_Vehiculos_AnioAntiguedad CHECK (Anio >= 2011),
    CONSTRAINT UQ_Vehiculos_Placa UNIQUE (Placa),
    CONSTRAINT UQ_Vehiculos_Chasis UNIQUE (NumeroChasis)
);
GO

-- 5. TABLA: Operaciones.Creditos
IF OBJECT_ID(N'Operaciones.Creditos', N'U') IS NOT NULL
    DROP TABLE Operaciones.Creditos;
GO

CREATE TABLE Operaciones.Creditos (
    IdCredito          INT IDENTITY(1,1)   NOT NULL,
    IdCliente          INT                 NOT NULL,
    IdVehiculo         INT                 NOT NULL,
    MontoCapital       DECIMAL(18,2)       NOT NULL,
    TasaInteresMensual DECIMAL(5,2)        NOT NULL,
    Estado             VARCHAR(20)         NOT NULL CONSTRAINT DF_Creditos_Estado DEFAULT 'Activo',
    FechaDesembolso    DATETIME2(0)        NOT NULL CONSTRAINT DF_Creditos_FechaDesembolso DEFAULT GETDATE(),

    CONSTRAINT PK_Creditos_IdCredito PRIMARY KEY CLUSTERED (IdCredito),
    CONSTRAINT FK_Creditos_Clientes FOREIGN KEY (IdCliente) REFERENCES Operaciones.Clientes(IdCliente),
    CONSTRAINT FK_Creditos_Vehiculos FOREIGN KEY (IdVehiculo) REFERENCES Garantias.Vehiculos(IdVehiculo),
    CONSTRAINT CHK_Creditos_MontoMinimo CHECK (MontoCapital > 1000.00),
    CONSTRAINT CHK_Creditos_TasaNoNegativa CHECK (TasaInteresMensual >= 0.00)
);
GO