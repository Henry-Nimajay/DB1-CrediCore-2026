-- ============================================================================
-- PROYECTO CREDICORE - FASE 2: INGESTA MULTIFORMATO Y BUSINESS INTELLIGENCE
-- AUTOR: Henry
-- DBMS: SQL SERVER 2022 (DOCKER) | CLIENTE: DBEAVER
-- ============================================================================

USE CrediCoreDB;
GO

-- ----------------------------------------------------------------------------
-- PARTE 1.1: SOLUCION AL LIMITE DE 1,000 FILAS (INGESTA POR LOTES / BATCHES)
-- ----------------------------------------------------------------------------
INSERT INTO Garantias.Vehiculos (Modelo, Marca, Anio, Color, NumeroTitulo, Placa, NumeroChasis)
SELECT TOP (750)
    'Corolla', 'Toyota', 2017, 'Blanco',
    CONCAT('TIT-A', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
    CONCAT('P-A', RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(5)), 5)),
    CONCAT('CHSA', RIGHT('00000000000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(11)), 11))
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO

INSERT INTO Garantias.Vehiculos (Modelo, Marca, Anio, Color, NumeroTitulo, Placa, NumeroChasis)
SELECT TOP (750)
    'Civic', 'Honda', 2019, 'Negro',
    CONCAT('TIT-B', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
    CONCAT('P-B', RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(5)), 5)),
    CONCAT('CHSB', RIGHT('00000000000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(11)), 11))
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO

-- ----------------------------------------------------------------------------
-- PARTE 1.2: INGESTA MEDIANTE CONCATENACION DE EXCEL
-- ----------------------------------------------------------------------------
INSERT INTO Operaciones.Clientes (DPI, Nombres, Apellidos, Telefono, Correo) 
VALUES ('1000000000101', 'Carlos', 'Gomez', '55010001', 'carlos.gomez@email.com');
GO

-- ----------------------------------------------------------------------------
-- PARTE 1.3: INGESTA MASIVA MEDIANTE BULK INSERT DESDE ARCHIVO PLANO
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Operaciones.vw_CargaCreditos AS
SELECT 
    IdCliente,
    IdVehiculo,
    MontoCapital,
    TasaInteresMensual,
    Estado,
    FechaDesembolso
FROM Operaciones.Creditos;
GO

BULK INSERT Operaciones.vw_CargaCreditos
FROM '/var/opt/mssql/data/prestamos_bulk.txt'
WITH (
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    FIRSTROW = 1,
    TABLOCK
);
GO

-- ----------------------------------------------------------------------------
-- PARTE 2: REPORTES DE INTELIGENCIA DE NEGOCIOS
-- ----------------------------------------------------------------------------
-- Reporte 1: Riesgo Financiero
SELECT 
    Estado,
    COUNT(IdCredito) AS TotalCreditos,
    FORMAT(SUM(MontoCapital), 'C', 'es-GT') AS TotalCapitalPrestado,
    CAST(AVG(TasaInteresMensual) AS DECIMAL(5,2)) AS PromedioTasaInteres
FROM Operaciones.Creditos
GROUP BY Estado;
GO

-- Reporte 2: Concentracion de Cartera Vehicular
SELECT 
    V.Marca,
    COUNT(C.IdCredito) AS CantidadPrestamos,
    FORMAT(SUM(C.MontoCapital), 'C', 'es-GT') AS CapitalColocado
FROM Operaciones.Creditos C
INNER JOIN Garantias.Vehiculos V ON C.IdVehiculo = V.IdVehiculo
GROUP BY V.Marca
HAVING COUNT(C.IdCredito) > 0
ORDER BY CantidadPrestamos DESC;
GO

-- Reporte 3: Extremos Financieros
SELECT 
    FORMAT(MAX(MontoCapital), 'C', 'es-GT') AS PrestamoMaximoOtorgado,
    FORMAT(MIN(MontoCapital), 'C', 'es-GT') AS PrestamoMinimoOtorgado,
    FORMAT(MAX(MontoCapital) - MIN(MontoCapital), 'C', 'es-GT') AS BrechaCapital
FROM Operaciones.Creditos;
GO