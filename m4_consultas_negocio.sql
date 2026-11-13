-- Motor utilizado: SQL Server (SQL Server Management Studio - SSMS)
-- =====================================================================
-- Proyecto  : RetailPro
-- Entrega   : Pre-entrega 4 - Consultas SQL de negocio
-- Título    : Extrayendo métricas clave con SQL
-- Archivo   : m4_consultas_negocio.sql
-- Base      : Ventas_Tech_DB (creada y cargada en el Módulo 3)
-- Tabla     : ventas (id_venta, id_cliente, id_producto, cantidad,
--                     precio_unitario, fecha_venta)
--
-- Criterio general: el importe de cada venta se calcula siempre como
--                   cantidad * precio_unitario.
-- Por ahora trabajamos solo con IDs; los nombres de productos y
-- clientes se van a traer con JOIN en el Módulo 5.
-- =====================================================================

USE Ventas_Tech_DB;
GO


-- =====================================================================
-- CONSULTA 1 — Resumen ejecutivo mensual
-- Pregunta de negocio: ¿cuánto facturamos, cuántos pedidos hubo y cuál
-- fue el ticket promedio en cada mes?
--   - total_facturado  : SUM(cantidad * precio_unitario)
--   - cantidad_pedidos : COUNT(*)  (cada fila de ventas es un pedido)
--   - ticket_promedio  : AVG(cantidad * precio_unitario) = total / pedidos
-- Se agrupa por MONTH(fecha_venta). También se incluye YEAR(fecha_venta)
-- para que, cuando haya datos de más de un año, marzo 2024 no se mezcle
-- con marzo 2025.
-- Resultado esperado con los datos del M3 (todas las ventas son de
-- marzo de 2024): UNA sola fila -> 2024 | 3 | 6444.00 | 10 | 644.40
-- =====================================================================
SELECT
    YEAR(fecha_venta)                                       AS anio,
    MONTH(fecha_venta)                                      AS mes,
    SUM(cantidad * precio_unitario)                         AS total_facturado,
    COUNT(*)                                                AS cantidad_pedidos,
    CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2))  AS ticket_promedio
FROM ventas
GROUP BY
    YEAR(fecha_venta),
    MONTH(fecha_venta)
ORDER BY
    anio,
    mes;
GO


-- =====================================================================
-- CONSULTA 2 — Ranking de productos (Top 5 por total facturado)
-- Pregunta de negocio: ¿qué productos generan más facturación?
--   - unidades_vendidas : SUM(cantidad)
--   - total_facturado   : SUM(cantidad * precio_unitario)
-- Se agrupa por id_producto, se ordena de mayor a menor facturación y
-- se limita el resultado a 5 filas con TOP 5.
-- Resultado esperado:
--   id_producto | unidades_vendidas | total_facturado
--        1      |         3         |     3600.00
--        3      |         3         |     1350.00
--        5      |         3         |      390.00
--        6      |         4         |      380.00
--        2      |        13         |      364.00
--   (queda afuera el producto 4 con 360.00)
-- =====================================================================
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
GO


-- =====================================================================
-- CONSULTA 3 — Clientes recurrentes
-- Pregunta de negocio: ¿qué clientes compraron más de una vez y cuánto
-- gastaron en total?
--   - cantidad_pedidos : COUNT(*)
--   - total_gastado    : SUM(cantidad * precio_unitario)
-- WHERE no sirve para filtrar sobre un COUNT, por eso el filtro de
-- "más de un pedido" va en HAVING, después del GROUP BY.
-- Resultado esperado (los 5 clientes tienen 2 pedidos cada uno):
--   id_cliente | cantidad_pedidos | total_gastado
--       1      |        2         |    2640.00
--       5      |        2         |    2100.00
--       3      |        2         |     674.00
--       2      |        2         |     520.00
--       4      |        2         |     510.00
-- =====================================================================
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
GO


-- =====================================================================
-- CONSULTA 4 — Productos por encima / por debajo del promedio
-- Pregunta de negocio: ¿qué productos facturan más que el producto
-- "promedio" del catálogo vendido?
-- Paso 1 (CTE con WITH): total facturado por id_producto.
-- Paso 2 (subconsulta): promedio de ESOS totales por producto
--         -> AVG sobre totales_por_producto (6 filas), NO sobre las
--            10 filas de ventas.
--         Promedio correcto: 6444.00 / 6 = 1074.00
--         (el promedio por fila de ventas sería 644.40, que NO es el
--          que se pide)
-- Paso 3 (CASE WHEN): etiqueta cada producto como 'Por encima' o
--         'Por debajo' de ese promedio.
-- Resultado esperado:
--   id_producto | total_facturado | promedio_por_producto | comparacion_promedio
--        1      |     3600.00     |        1074.00        | Por encima
--        3      |     1350.00     |        1074.00        | Por encima
--        5      |      390.00     |        1074.00        | Por debajo
--        6      |      380.00     |        1074.00        | Por debajo
--        2      |      364.00     |        1074.00        | Por debajo
--        4      |      360.00     |        1074.00        | Por debajo
-- =====================================================================
WITH totales_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    CAST((SELECT AVG(total_facturado) FROM totales_por_producto)
         AS DECIMAL(10,2))                                  AS promedio_por_producto,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado)
                                FROM totales_por_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END                                                     AS comparacion_promedio
FROM totales_por_producto
ORDER BY total_facturado DESC;
GO


-- =====================================================================
-- BLOQUE DE CIERRE — 3 HALLAZGOS CONCRETOS
-- (Base: 10 ventas de marzo de 2024, facturación total $6444.00)
-- =====================================================================
--
-- HALLAZGO 1 — Facturación muy concentrada en dos productos.
--   El producto 1 (Laptop Pro 15) factura $3600.00, el 55,9% del total
--   de marzo 2024, y junto con el producto 3 (Monitor 4K 27, $1350.00)
--   suman $4950.00 = 76,8%. Son los únicos 2 de 6 productos por encima
--   del promedio por producto ($1074.00).
--   Acción: priorizar el stock de ambos (el producto 3 tiene solo 12
--   unidades) y vigilarlos, porque una caída en su venta impacta en
--   casi 8 de cada 10 pesos facturados.
--
-- HALLAZGO 2 — El producto que más se vende no es el que más factura.
--   El producto 2 (Mouse Inalámbrico) es el más vendido en unidades:
--   13 de 29 (44,8%), pero aporta solo $364.00 (5,6% de la
--   facturación) y queda 5.º en el ranking. Los productos 2, 4, 5 y 6
--   facturan entre $360.00 y $390.00 cada uno: el 5.º y el 6.º puesto
--   se separan por apenas $4.00.
--   Acción: usar los accesorios de bajo precio (2, 4, 6) en combos o
--   venta cruzada con la laptop y el monitor para subir el ticket
--   promedio, hoy de $644.40.
--
-- HALLAZGO 3 — Todos los clientes son recurrentes, pero 2 concentran
--   la facturación.
--   Los 5 clientes hicieron exactamente 2 pedidos cada uno (100% de
--   recurrencia en el mes). Sin embargo, el cliente 1 ($2640.00) y el
--   cliente 5 ($2100.00) suman $4740.00 = 73,6% del total, y ambos
--   compraron el producto 1. Los clientes 2, 3 y 4 gastaron entre
--   $510.00 y $674.00.
--   Acción: armar un programa de fidelización para los clientes 1 y 5
--   (alto valor) y ofrecer upgrades de equipos a los clientes 2, 3 y 4.
--
-- Nota: con una base de un solo mes (10 ventas) estos hallazgos son
-- una foto inicial; habrá que validarlos al sumar más períodos.
-- =====================================================================
