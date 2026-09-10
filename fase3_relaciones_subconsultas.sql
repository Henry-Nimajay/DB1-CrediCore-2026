-- ============================================================================
-- PROYECTO CREDICORE - FASE 3: INTEGRIDAD REFERENCIAL Y SUBCONSULTAS ESTRATÉGICAS
-- MOTOR: SQL Server 2022 (Docker) | CLIENTE: DBeaver
-- AUTOR: Henry
-- ============================================================================

USE CrediCoreDB;
GO

-- ============================================================================
-- PARTE 1: EL ESCUDO RELACIONAL (DDL / DML)
-- ============================================================================

-- 1.1 Llaves Foráneas (FOREIGN KEY)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Creditos_Clientes')
BEGIN
    ALTER TABLE Operaciones.Creditos
    ADD CONSTRAINT FK_Creditos_Clientes
    FOREIGN KEY (IdCliente) REFERENCES Operaciones.Clientes(IdCliente);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Creditos_Vehiculos')
BEGIN
    ALTER TABLE Operaciones.Creditos
    ADD CONSTRAINT FK_Creditos_Vehiculos
    FOREIGN KEY (IdVehiculo) REFERENCES Garantias.Vehiculos(IdVehiculo);
END
GO

-- 1.2 Prueba de Destrucción (Error Obligatorio Msg 547)
-- Intento de eliminación de registro padre con hijos dependientes
DELETE FROM Operaciones.Clientes
WHERE IdCliente = 1;
GO


-- ============================================================================
-- PARTE 2: RECONSTRUCCIÓN DE LA REALIDAD (JOINS)
-- ============================================================================

-- 2.1 El Reporte Maestro (INNER JOIN entre 3 tablas)
SELECT 
    CONCAT(C.Nombres, ' ', C.Apellidos) AS Cliente,
    C.Telefono,
    V.Marca AS MarcaVehiculo,
    V.Placa,
    FORMAT(CR.MontoCapital, 'C', 'es-GT') AS MontoCredito,
    CR.Estado AS EstadoCredito
FROM Operaciones.Creditos CR
INNER JOIN Operaciones.Clientes C ON CR.IdCliente = C.IdCliente
INNER JOIN Garantias.Vehiculos V ON CR.IdVehiculo = V.IdVehiculo;
GO

-- 2.2 Minería de Clientes Potenciales (LEFT JOIN detectando NULLs)
SELECT 
    C.IdCliente,
    CONCAT(C.Nombres, ' ', C.Apellidos) AS ClienteProspecto,
    C.Telefono,
    C.Correo,
    CR.IdCredito AS CreditoAsociado
FROM Operaciones.Clientes C
LEFT JOIN Operaciones.Creditos CR ON C.IdCliente = CR.IdCliente
WHERE CR.IdCredito IS NULL;
GO


-- ============================================================================
-- PARTE 3: EL CEREBRO ANALÍTICO (SUBCONSULTAS)
-- ============================================================================

-- 3.1 Subconsulta Dinámica en el WHERE (Monto mayor al promedio histórico)
SELECT 
    CONCAT(CL.Nombres, ' ', CL.Apellidos) AS Cliente,
    FORMAT(CR.MontoCapital, 'C', 'es-GT') AS MontoOtorgado,
    FORMAT((SELECT AVG(MontoCapital) FROM Operaciones.Creditos), 'C', 'es-GT') AS PromedioHistorico
FROM Operaciones.Creditos CR
INNER JOIN Operaciones.Clientes CL ON CR.IdCliente = CL.IdCliente
WHERE CR.MontoCapital > (SELECT AVG(MontoCapital) FROM Operaciones.Creditos)
ORDER BY CR.MontoCapital DESC;
GO

-- 3.2 Subconsulta con Operador IN (Garantías de 2010 hacia atrás)
SELECT 
    CONCAT(C.Nombres, ' ', C.Apellidos) AS Cliente,
    C.Telefono
FROM Operaciones.Clientes C
WHERE C.IdCliente IN (
    SELECT CR.IdCliente
    FROM Operaciones.Creditos CR
    INNER JOIN Garantias.Vehiculos V ON CR.IdVehiculo = V.IdVehiculo
    WHERE V.Anio <= 2010
);
GO
