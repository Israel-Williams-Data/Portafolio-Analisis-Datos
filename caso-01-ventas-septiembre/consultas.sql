USE tienda_tech;

-- ==========================================
-- 1. VENTAS TOTALES REALES
-- ==========================================
SELECT 
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)), 2) AS ventas_totales_reales
FROM ventas_septiembre
WHERE es_atipico = 0 
  AND es_cantidad_negativa = 0
  AND estado = 'Entregado';


-- ==========================================
-- 2. VENTAS POR CATEGORÍA
-- ==========================================
SELECT 
    categoria,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)), 2) AS total_ventas_categoria,
    COUNT(*) AS total_pedidos,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)) / COUNT(*), 2) AS ticket_promedio
FROM ventas_septiembre
WHERE es_atipico = 0 
  AND es_cantidad_negativa = 0
  AND estado = 'Entregado'
GROUP BY categoria
ORDER BY total_ventas_categoria DESC;


-- ==========================================
-- 3. VENTAS POR VENDEDOR
-- ==========================================
SELECT 
    vendedor,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)), 2) AS total_ventas_vendedor,
    COUNT(*) AS total_pedidos,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)) / COUNT(*), 2) AS ticket_promedio
FROM ventas_septiembre
WHERE es_atipico = 0 
  AND es_cantidad_negativa = 0
  AND estado = 'Entregado'
GROUP BY vendedor
ORDER BY total_ventas_vendedor DESC;


-- ==========================================
-- 4. VENTAS POR CIUDAD
-- ==========================================
SELECT 
    ciudad,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)), 2) AS total_ventas_ciudad,
    COUNT(*) AS total_pedidos,
    ROUND(SUM(cantidad * precio_unitario * (1 - descuento_pct / 100)) / COUNT(*), 2) AS ticket_promedio
FROM ventas_septiembre
WHERE es_atipico = 0 
  AND es_cantidad_negativa = 0
  AND estado = 'Entregado'
GROUP BY ciudad
ORDER BY total_ventas_ciudad DESC;