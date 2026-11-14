# 📊 RetailPro - Análisis de Ventas Tecnológicas (ventas_tech_db)

Proyecto integrador desarrollado en el marco del curso de Data Analytics. El objetivo principal es diseñar, poblar y consultar una base de datos relacional en SQL Server para una empresa ficticia del sector tecnológico (RetailPro), culminando con el modelado dimensional y la visualización de indicadores clave de negocio en Power BI.

## 📁 Estructura del Repositorio

El repositorio está organizado de manera progresiva según los módulos del curso:

```
ventas_tech_db/
├── M8/
│   └── Silva_Josefina_Checkpoint2.pbix   # Modelo estrella, tabla calendario y medidas DAX en Power BI
├── ventas_tech_db.sql                    # Script DDL y DML (creación de BD, tablas y carga de datos)
├── m4_consultas_negocio.sql              # Consultas analíticas y métricas de negocio
├── m5_consultas_joins.sql                # Consultas relacionales avanzadas (JOINs y UNION ALL)
└── README.md                             # Documentación del proyecto
```

### Detalle de los archivos

1. **`ventas_tech_db.sql`**:
   - Crea la base de datos `Ventas_Tech_DB`.
   - Define la estructura relacional compuesta por 4 tablas: `categorias`, `clientes`, `productos` y `ventas` (incluyendo claves primarias y foráneas).
   - Inserta 25 registros de ejemplo distribuidos entre las tablas para simular operaciones comerciales reales.
2. **`m4_consultas_negocio.sql`** (todas trabajan sobre la tabla `ventas`; el importe de cada venta es `cantidad * precio_unitario`):
   - **Consulta 1 — Resumen ejecutivo mensual:** total facturado, cantidad de pedidos y ticket promedio por año y mes.
   - **Consulta 2 — Ranking de productos:** Top 5 de `id_producto` por total facturado, con las unidades vendidas.
   - **Consulta 3 — Clientes recurrentes:** clientes con más de un pedido (`GROUP BY` + `HAVING COUNT(*) > 1`), con su cantidad de pedidos y total gastado.
   - **Consulta 4 — Productos por encima/por debajo del promedio:** compara el total facturado de cada producto con el promedio de los totales por producto (no con el promedio de las filas de ventas), usando `WITH` y `CASE WHEN`.
   - Al final del archivo hay un bloque con 3 hallazgos de negocio.
3. **`m5_consultas_joins.sql`**:
   - **INNER JOIN:** vista base que une `ventas` con `clientes`, `productos` y `categorias` (fecha, cliente, ciudad, producto, categoría, cantidad, precio y total). Es la fuente pensada para Power BI.
   - **LEFT JOIN + `IS NULL`:** clientes registrados que nunca compraron y productos del catálogo sin ninguna venta.
   - **UNION ALL:** consolidado de ventas por canal (“Local Buenos Aires” vs. “Envío al interior”, según la ciudad del cliente), con una columna `canal` creada como valor literal en cada `SELECT`.
4. **`M8/Silva_Josefina_Checkpoint2.pbix`**:
   - Archivo de Power BI Desktop construido sobre el pipeline ETL del Módulo 6: los datos se cargan desde `Pipeline_ETL_Dataset.xlsx` y se limpian en Power Query (`Dim_Clientes`, `Dim_Productos`, `Dim_Categorias` y `Fact_Ventas`).
   - Esquema en estrella con 4 relaciones 1:N activas y de dirección única, más la tabla calendario `Dim_Fechas` (creada con `CALENDAR` y marcada como tabla de fechas).
   - Tabla `_Medidas` con 5 medidas DAX: `Total Ventas`, `Ventas Online`, `Ventas YTD`, `Ventas LY` y `% Crecimiento Anual`, más una página `Validación` con la matriz de control.

## 🛠️ Herramientas Utilizadas

- **Motor de Base de Datos:** Microsoft SQL Server
- **Entorno de Desarrollo SQL:** SQL Server Management Studio (SSMS) / Azure Data Studio
- **Business Intelligence y Visualización:** Microsoft Power BI Desktop (Power Query, Modelado Dimensional, DAX)
- **Control de Versiones:** Git & GitHub

## 🚀 Cómo Ejecutar los Scripts SQL

Para reproducir la base de datos y ejecutar las consultas en tu entorno local, seguí estos pasos:

### Requisitos previos

- Tener instalado SQL Server (Express, Developer o superior).
- Contar con un cliente SQL como SQL Server Management Studio (SSMS).

### Pasos de ejecución

1. **Clonar el repositorio** (o descargar los archivos `.sql`):
   ```bash
   git clone https://github.com/silvajd/ventas_tech_db.git
   ```
2. **Abrir SSMS** y conectarse a tu instancia local de SQL Server.
3. **Crear la base de datos y cargar los datos:**
   - Abrí el archivo `ventas_tech_db.sql` (File > Open > File...).
   - Ejecutá el script completo presionando `F5` o haciendo clic en **Execute**.
   - Verificá en el **Object Explorer** (actualizando con `F5`) que la base `Ventas_Tech_DB` y sus 4 tablas se hayan creado correctamente.
4. **Ejecutar las consultas de análisis:**
   - Asegurate de tener seleccionada la base de datos `Ventas_Tech_DB` en el menú desplegable superior (o ejecutá `USE Ventas_Tech_DB;`).
   - Abrí y ejecutá `m4_consultas_negocio.sql` y luego `m5_consultas_joins.sql` para visualizar los resultados en la pestaña **Results**.
5. **Explorar el reporte en Power BI (Opcional):**
   - Abrí el archivo `M8/Silva_Josefina_Checkpoint2.pbix` con Power BI Desktop para inspeccionar el modelo de datos, las fórmulas DAX y las visualizaciones.

## 👩‍💻 Autoría

- **Josefina Silva** – Proyecto RetailPro - Curso de Data Analytics

> README generado con asistencia de IA (Google Gemini) y revisado y corregido manualmente contra el contenido real del repositorio.
