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

-- ============================================================================
-- 1. ELIMINACIÓN DE TABLAS (En orden inverso de dependencias para evitar Error 3726)
-- ============================================================================
IF OBJECT_ID(N'Operaciones.Creditos', N'U') IS NOT NULL
    DROP TABLE Operaciones.Creditos;
GO

IF OBJECT_ID(N'Operaciones.Clientes', N'U') IS NOT NULL
    DROP TABLE Operaciones.Clientes;
GO

IF OBJECT_ID(N'Garantias.Vehiculos', N'U') IS NOT NULL
    DROP TABLE Garantias.Vehiculos;
GO

-- ============================================================================
-- 2. CREACIÓN DE TABLAS
-- ============================================================================

-- Tabla Padre 1
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

-- Tabla Padre 2
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

-- Tabla Hija (Depende de Clientes y Vehiculos)
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

USE CrediCoreDB;

-- Insertar cliente base (generará IdCliente = 1)
INSERT INTO Operaciones.Clientes (DPI, Nombres, Apellidos, Telefono, Correo)
VALUES ('1234567890101', 'Henry', 'Gómez', '55551234', 'henry@credicore.com');

-- Insertar vehículo base (generará IdVehiculo = 1)
INSERT INTO Garantias.Vehiculos (Modelo, Marca, Anio, Color, NumeroTitulo, Placa, NumeroChasis)
VALUES ('Yaris', 'Toyota', 2018, 'Gris', 'TIT-9090', 'P-888CCC', 'CHS999888777');

SELECT * FROM Garantias.Vehiculos;

INSERT INTO Garantias.Vehiculos (Modelo, Marca, Anio, Color, NumeroTitulo, Placa, NumeroChasis)
VALUES ('Corolla', 'Toyota', 1990, 'Azul', 'TIT-1010', 'P-111AAA', 'CHS111222333');

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
VALUES (1, 1, 5000.00, -2.50);

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
VALUES (1, 1, 500.00, 3.00);

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
VALUES (1, 1, 15000.00, 2.50);

SELECT * FROM Operaciones.Creditos;