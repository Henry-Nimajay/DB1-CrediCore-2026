-- ============================================================================
-- PROYECTO CREDICORE - FASE 4: PROGRAMABILIDAD, AUTOMATIZACIÓN Y AUDITORÍA
-- MOTOR: Microsoft SQL Server 2022 (Docker) | CLIENTE: DBeaver
-- AUTOR: Henry
-- ============================================================================

USE CrediCoreDB;
GO

-- ============================================================================
-- PARTE 1: LA CAPA DE SEGURIDAD (VISTAS)
-- ============================================================================

-- Vista que oculta DPI, teléfono y placas para atención al cliente
CREATE OR ALTER VIEW Operaciones.vw_AtencionAlCliente AS
SELECT 
    CONCAT(CL.Nombres, ' ', CL.Apellidos) AS NombreCliente,
    CR.IdCredito AS NumeroCredito,
    CR.Estado AS EstadoCredito,
    CR.MontoCapital AS SaldoActual
FROM Operaciones.Creditos CR
INNER JOIN Operaciones.Clientes CL ON CR.IdCliente = CL.IdCliente;
GO


-- ============================================================================
-- PARTE 2: LÓGICA TRANSACCIONAL (PROCEDIMIENTOS ALMACENADOS)
-- ============================================================================

-- Tabla histórica para registrar abonos
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HistorialPagos' AND schema_id = SCHEMA_ID('Operaciones'))
BEGIN
    CREATE TABLE Operaciones.HistorialPagos (
        IdPago INT IDENTITY(1,1) PRIMARY KEY,
        IdCredito INT NOT NULL,
        MontoPagado DECIMAL(12,2) NOT NULL,
        FechaPago DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_HistorialPagos_Creditos 
            FOREIGN KEY (IdCredito) REFERENCES Operaciones.Creditos(IdCredito)
    );
END
GO

-- Stored Procedure transaccional con TRY...CATCH y control de sobrepago
CREATE OR ALTER PROCEDURE Operaciones.SP_ProcesarPago
    @IdCredito INT,
    @MontoPago DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @SaldoActual DECIMAL(12,2);
        
        -- Bloqueo de fila para consistencia atómica
        SELECT @SaldoActual = MontoCapital 
        FROM Operaciones.Creditos WITH (UPDLOCK)
        WHERE IdCredito = @IdCredito;
        
        -- Validación de existencia
        IF @SaldoActual IS NULL
        BEGIN
            RAISERROR('Error: El crédito especificado no existe.', 16, 1);
        END
        
        -- Validación de monto vs saldo
        IF @MontoPago > @SaldoActual
        BEGIN
            RAISERROR('Error: El monto a pagar excede el saldo deudor actual.', 16, 1);
        END
        
        -- Validación de monto positivo
        IF @MontoPago <= 0
        BEGIN
            RAISERROR('Error: El monto de pago debe ser mayor a cero.', 16, 1);
        END

        -- 1. Insertar abono en historial
        INSERT INTO Operaciones.HistorialPagos (IdCredito, MontoPagado, FechaPago)
        VALUES (@IdCredito, @MontoPago, GETDATE());

        -- 2. Actualizar saldo y estado
        UPDATE Operaciones.Creditos
        SET MontoCapital = MontoCapital - @MontoPago,
            Estado = CASE WHEN (MontoCapital - @MontoPago) = 0 THEN 'Pagado' ELSE Estado END
        WHERE IdCredito = @IdCredito;

        COMMIT TRANSACTION;
        
        SELECT 
            'PAGO PROCESADO CON ÉXITO' AS MensajeConfirmacion,
            @IdCredito AS Credito,
            @MontoPago AS MontoAbonado,
            (@SaldoActual - @MontoPago) AS NuevoSaldo;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

EXEC Operaciones.SP_ProcesarPago @IdCredito = 2, @MontoPago = 1000.00;

-- ============================================================================
-- PARTE 3: EL AUDITOR SILENCIOSO (TRIGGERS)
-- ============================================================================

-- Esquema de Auditoría
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Auditoria')
BEGIN
    EXEC('CREATE SCHEMA Auditoria');
END
GO

-- Tabla de Logs de Auditoría
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Logs_Creditos' AND schema_id = SCHEMA_ID('Auditoria'))
BEGIN
    CREATE TABLE Auditoria.Logs_Creditos (
        IdRegistro INT IDENTITY(1,1) PRIMARY KEY,
        Accion VARCHAR(100) NOT NULL,
        DatoViejo VARCHAR(255) NOT NULL,
        DatoNuevo VARCHAR(255) NOT NULL,
        FechaHora DATETIME DEFAULT GETDATE(),
        UsuarioEjecutor VARCHAR(100) DEFAULT SUSER_SNAME()
    );
END
GO

-- Trigger AFTER UPDATE para detectar cambios manuales en créditos
CREATE OR ALTER TRIGGER Operaciones.TR_Auditoria_Creditos
ON Operaciones.Creditos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Auditoría de tasa de interés
    IF UPDATE(TasaInteresMensual)
    BEGIN
        INSERT INTO Auditoria.Logs_Creditos (Accion, DatoViejo, DatoNuevo, FechaHora, UsuarioEjecutor)
        SELECT 
            CONCAT('MODIFICACIÓN TASA INTERÉS (Crédito ID: ', i.IdCredito, ')'),
            CONCAT('Tasa Anterior: ', d.TasaInteresMensual, '%'),
            CONCAT('Tasa Nueva: ', i.TasaInteresMensual, '%'),
            GETDATE(),
            SUSER_SNAME()
        FROM inserted i
        INNER JOIN deleted d ON i.IdCredito = d.IdCredito
        WHERE i.TasaInteresMensual <> d.TasaInteresMensual;
    END

    -- Auditoría de capital
    IF UPDATE(MontoCapital)
    BEGIN
        INSERT INTO Auditoria.Logs_Creditos (Accion, DatoViejo, DatoNuevo, FechaHora, UsuarioEjecutor)
        SELECT 
            CONCAT('MODIFICACIÓN MONTO CAPITAL (Crédito ID: ', i.IdCredito, ')'),
            CONCAT('Capital Anterior: Q', d.MontoCapital),
            CONCAT('Capital Nuevo: Q', i.MontoCapital),
            GETDATE(),
            SUSER_SNAME()
        FROM inserted i
        INNER JOIN deleted d ON i.IdCredito = d.IdCredito
        WHERE i.MontoCapital <> d.MontoCapital;
    END
END;
GO

UPDATE Operaciones.Creditos
SET TasaInteresMensual = 4.75
WHERE IdCredito = 2;

SELECT * FROM Auditoria.Logs_Creditos;
