-- Motor utilizado: SQL Server (SQL Server Management Studio - SSMS)
-- =====================================================================
-- Proyecto  : RetailPro
-- Entrega   : Pre-entrega 5 - Consultas con JOINs para el proyecto
-- Título    : Cruzando tablas para enriquecer el análisis
-- Archivo   : m5_consultas_joins.sql
-- Base      : Ventas_Tech_DB (esquema del Checkpoint del Módulo 3)
--
-- Esquema utilizado (claves foráneas que usan los JOINs):
--   categorias (1) ──── (N) productos (1) ──── (N) ventas (N) ──── (1) clientes
--   ventas.id_cliente     -> clientes.id_cliente
--   ventas.id_producto    -> productos.id_producto
--   productos.id_categoria -> categorias.id_categoria
--
-- Alias de tablas: v = ventas, c = clientes, p = productos,
--                  cat = categorias
-- =====================================================================

USE Ventas_Tech_DB;
GO


-- =====================================================================
-- CONSULTA 1 — Vista base del proyecto (INNER JOIN)
-- Propósito: armar la vista enriquecida que va a ser la fuente de datos
-- principal en Power BI. Cada fila es una venta con el nombre del
-- cliente, su ciudad (dimensión geográfica), el producto, su categoría,
-- la cantidad, el precio unitario y el total de la venta.
--   - Columnas para AGRUPAR : nombre_categoria, ciudad_cliente
--   - Columnas para FILTRAR : fecha_venta, nombre_categoria, ciudad_cliente
-- Se usa INNER JOIN porque cada venta tiene obligatoriamente un cliente
-- y un producto válidos (integridad referencial definida en el M3).
-- =====================================================================
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                           AS nombre_cliente,
    c.ciudad                           AS ciudad_cliente,
    p.id_producto,
    p.nombre_producto,
    cat.nombre_categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario     AS total_venta
FROM ventas AS v
INNER JOIN clientes   AS c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
ORDER BY
    v.fecha_venta,
    v.id_venta;
GO
-- Hallazgo: la vista devuelve las 10 ventas de marzo 2024 (no se pierde
-- ninguna en el cruce) por $6444.00. La categoría Computación (Laptop
-- Pro 15 + Monitor 4K 27) concentra $4950.00 = 76,8% de la facturación.


-- =====================================================================
-- CONSULTA 2 — Clientes sin ventas (LEFT JOIN + IS NULL)
-- Propósito (área de CRM): detectar clientes registrados que todavía no
-- hicieron ninguna compra, para orientar campañas de activación.
-- El LEFT JOIN conserva a TODOS los clientes; si un cliente no tiene
-- ventas, las columnas de ventas vienen en NULL y el WHERE ... IS NULL
-- deja solo esos casos. Se filtra por v.id_venta porque es la clave
-- primaria de ventas (nunca es NULL cuando la venta existe).
-- =====================================================================
SELECT
    c.id_cliente,
    c.nombre          AS nombre_cliente,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;
GO
-- Hallazgo: aparecen 0 registros: los 5 clientes registrados compraron
-- al menos una vez (100% de conversión). Para CRM no hay clientes para
-- activar hoy; el foco pasa a fidelizar y a sumar clientes nuevos.


-- =====================================================================
-- CONSULTA 3 — Productos sin ventas (LEFT JOIN + IS NULL)
-- Propósito (área de producto): identificar artículos del catálogo sin
-- ningún movimiento, para decidir promociones, descuentos o bajas.
-- productos es la tabla izquierda (se conservan todos); se suma
-- categorias con INNER JOIN para mostrar el nombre de la categoría, y
-- el WHERE ... IS NULL aísla los productos sin ventas.
-- =====================================================================
SELECT
    p.id_producto,
    p.nombre_producto,
    cat.nombre_categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS cat
    ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas AS v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.nombre_producto;
GO
-- Hallazgo: aparecen 0 registros: los 6 productos del catálogo tuvieron
-- ventas en marzo 2024. Producto no tiene stock inmovilizado; aun así,
-- Auriculares BT Pro ($360.00) es el de menor facturación y conviene
-- seguirlo.


-- =====================================================================
-- CONSULTA 4 — Consolidado por canal (UNION ALL)
-- Propósito: comparar la facturación de dos canales de venta.
-- La columna canal NO existe en las tablas: se CREA como valor literal
-- en cada SELECT.
-- Criterio de separación (según la ciudad del cliente):
--   'Local Buenos Aires' -> ventas a clientes de Buenos Aires
--   'Envío al interior'  -> ventas a clientes de otras ciudades
-- Las dos partes devuelven las mismas 3 columnas, en el mismo orden y
-- con los mismos tipos: fecha_venta (DATE), total (DECIMAL), canal
-- (texto). Se usa UNION ALL y no UNION para no eliminar filas
-- repetidas: cada venta se cuenta una sola vez.
-- Control: entre los dos canales tienen que sumar las 10 ventas y el
-- total general de $6444.00.
-- =====================================================================
SELECT
    canal,
    COUNT(*)    AS cantidad_ventas,
    SUM(total)  AS total_canal
FROM (
    SELECT
        v.fecha_venta,
        v.cantidad * v.precio_unitario  AS total,
        'Local Buenos Aires'            AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON v.id_cliente = c.id_cliente
    WHERE c.ciudad = 'Buenos Aires'

    UNION ALL

    SELECT
        v.fecha_venta,
        v.cantidad * v.precio_unitario  AS total,
        'Envío al interior'             AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON v.id_cliente = c.id_cliente
    WHERE c.ciudad <> 'Buenos Aires'
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
GO
-- Hallazgo: el canal "Envío al interior" vende más: $3804.00 (59,0%, 8
-- ventas) contra $2640.00 (41,0%, 2 ventas) del canal "Local Buenos
-- Aires", aunque este último tiene un ticket promedio mucho más alto
-- ($1320.00 contra $475.50).
