import streamlit as st
import pandas as pd
import pyodbc

# ==============================================================================
# CONFIGURACIÓN DE CONEXIÓN A SQL SERVER 2022
# ==============================================================================
# IP de tu servidor Ubuntu donde corre el contenedor Docker
SERVER = 'tcp:192.168.18.16,1433'
DATABASE = 'CrediCoreDB'
USERNAME = 'admin_credicore'
PASSWORD = 'CrediCore2026*'

# Cadena de conexión usando el driver ODBC nativo
conn_str = (
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={SERVER};'
    f'DATABASE={DATABASE};'
    f'UID={USERNAME};'
    f'PWD={PASSWORD};'
    f'TrustServerCertificate=yes;'
)

st.set_page_config(page_title="CrediCore - Módulo de Caja", layout="centered", page_icon="🏦")

st.title("🏦 CrediCore - Módulo de Caja")
st.caption("Arquitectura conectada a Microsoft SQL Server 2022 (Docker)")

# ==============================================================================
# 1. LEER LA VISTA SEGURA (ABSTRACCIÓN FÍSICA)
# ==============================================================================
st.subheader("📋 Estado de Cartera (Vista Segura)")

conn = None
try:
    conn = pyodbc.connect(conn_str)
    # Consultamos exclusivamente la vista creada en Fase 4
    query = "SELECT * FROM Operaciones.vw_AtencionAlCliente"
    df = pd.read_sql(query, conn)
    st.dataframe(df, use_container_width=True)
except Exception as e:
    st.error(f"Error de conexión con la base de datos: {e}")

st.divider()

# ==============================================================================
# 2. PROCESAR PAGO (CONSUMO DE STORED PROCEDURE)
# ==============================================================================
st.subheader("💳 Procesar Pago de Cuota")

with st.form("form_pago", clear_on_submit=True):
    id_credito = st.number_input("Número de Crédito (ID)", min_value=1, step=1, value=2)
    monto_pago = st.number_input("Monto a Abonar (Q)", min_value=1.0, step=100.0, value=500.0)
    btn_pagar = st.form_submit_button("Ejecutar Transacción")
    
    if btn_pagar:
        if conn is not None:
            try:
                cursor = conn.cursor()
                # Invocamos el procedimiento almacenado transaccional
                sql_exec = "EXEC Operaciones.SP_ProcesarPago @IdCredito = ?, @MontoPago = ?"
                cursor.execute(sql_exec, (id_credito, monto_pago))
                cursor.commit()
                st.success(f"¡Transacción exitosa! Pago de Q{monto_pago:,.2f} aplicado al Crédito #{id_credito}.")
                st.rerun()
            except Exception as e:
                # Captura el RAISERROR programado en el TRY...CATCH de SQL Server
                error_msg = str(e)
                st.error(f"❌ Transacción Rechazada por el Motor:\n\n{error_msg}")
        else:
            st.error("No se pudo establecer conexión con la base de datos.")
            