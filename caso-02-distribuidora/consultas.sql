USE caso2_distribuidora;

-- 1. Ventas netas totales por mes con su fila de gran total al final
SELECT 
    DATE_FORMAT(p.fecha, '%Y-%m') AS anio_mes,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_reales
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    DATE_FORMAT(p.fecha, '%Y-%m')

UNION ALL

-- Fila final con el Gran Total General de todos los meses
SELECT 
    'TOTAL GENERAL' AS anio_mes,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_reales
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado';

-- 2. Ventas netas totales por categoría y tipo de cliente 
SELECT 
    pr.categoria AS categoria_producto,
    COALESCE(c.tipo_cliente, 'Sin cliente registrado') AS tipo_cliente,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_reales
FROM 
    pedidos p
LEFT JOIN 
    clientes c ON p.id_cliente = c.id_cliente
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
JOIN 
    productos pr ON d.id_producto = pr.id_producto
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    pr.categoria,
    c.tipo_cliente

UNION ALL

-- Fila final con el Gran Total General
SELECT 
    'TOTAL GENERAL' AS categoria_producto,
    '' AS tipo_cliente,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_reales
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado'

ORDER BY 
    categoria_producto ASC, 
    ventas_netas_reales DESC;

-- 3. Identificar los 5 mejores clientes basándonos en las ventas netas reales
SELECT 
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.tipo_cliente,
    c.departamento,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_totales
FROM 
    pedidos p
JOIN 
    clientes c ON p.id_cliente = c.id_cliente
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    c.id_cliente,
    c.nombre,
    c.tipo_cliente,
    c.departamento
ORDER BY 
    ventas_netas_totales DESC
LIMIT 5; 

-- 4.1 Calcular el margen por proveedor uniendo la tabla proveedores para mostrar su nombre
SELECT 
    prv.id_proveedor,
    prv.nombre AS nombre_proveedor,
    SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS ingresos_netos_totales,
    SUM(d.cantidad * pr.costo) AS costo_total_adquisicion,
    (SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) - SUM(d.cantidad * pr.costo)) AS margen_dinero,
    ROUND(
        ((SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) - SUM(d.cantidad * pr.costo)) / 
         NULLIF(SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))), 0)) * 100, 
    2) AS margen_porcentaje
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
JOIN 
    productos pr ON d.id_producto = pr.id_producto
JOIN 
    proveedores prv ON pr.id_proveedor = prv.id_proveedor
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    prv.id_proveedor,
    prv.nombre
ORDER BY 
    margen_dinero DESC;

-- 4.2 Auditar líneas vendidas por debajo del costo 
SELECT 
    d.id_pedido,
    d.id_producto,
    pr.nombre AS nombre_producto,
    pr.costo AS costo_unitario_compra,
    pr.precio_lista AS precio_lista_oficial_producto,
    d.precio_unitario AS precio_unitario_venta,
    COALESCE(d.descuento_pct, 0) AS descuento_aplicado_pct,
    -- Precio real de venta ya con el descuento aplicado
    (d.precio_unitario * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS precio_venta_real,
    -- Margen unitario resultante
    ((d.precio_unitario * (1 - (COALESCE(d.descuento_pct, 0) / 100))) - pr.costo) AS margen_unitario
FROM 
    detalle_pedidos d
JOIN 
    pedidos p ON d.id_pedido = p.id_pedido
JOIN 
    productos pr ON d.id_producto = pr.id_producto
WHERE 
    p.estado = 'Entregado'
    -- Condición de pérdida: el precio real de venta es menor estrictamente que el costo
    AND (d.precio_unitario * (1 - (COALESCE(d.descuento_pct, 0) / 100))) < pr.costo
ORDER BY 
    margen_unitario ASC;

-- 5.1 Ventas netas por vendedor y zona (con nombres descriptivos y fila de total limpia al final)
SELECT 
    v.id_vendedor,
    COALESCE(v.nombre, 'Sin vendedor registrado') AS nombre_vendedor,
    COALESCE(v.zona, 'Sin zona asignada') AS zona,
    SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS ventas_netas_totales
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
LEFT JOIN 
    vendedores v ON p.id_vendedor = v.id_vendedor
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    v.id_vendedor, 
    v.nombre, 
    v.zona

UNION ALL

-- Fila final con el Gran Total General 
SELECT 
    NULL AS id_vendedor,
    'TOTAL GENERAL' AS nombre_vendedor,
    '' AS zona,
    SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS ventas_netas_totales
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado';

-- 5.2 Ventas netas totales agrupadas por Zona
SELECT 
    COALESCE(v.zona, 'Sin zona registrada') AS zona,
    SUM(
        ((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) 
    ) AS ventas_netas_reales
FROM 
    pedidos p
LEFT JOIN 
    vendedores v ON p.id_vendedor = v.id_vendedor
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.estado = 'Entregado'
GROUP BY 
    v.zona
ORDER BY 
    ventas_netas_reales DESC;

-- 6.1 Auditar clientes registrados que nunca han concretado una compra (Sin pedidos Entregados ni En ruta)
SELECT 
    c.id_cliente,
    c.nombre,
    c.tipo_cliente,
    c.departamento
FROM 
    clientes c
LEFT JOIN (
    SELECT DISTINCT id_cliente 
    FROM pedidos 
    WHERE estado IN ('Entregado', 'En ruta')
) p ON c.id_cliente = p.id_cliente
WHERE 
    p.id_cliente IS NULL;

-- 6.2 Auditar productos que jamás han aparecido en una línea de detalle de pedido 
SELECT 
    pr.id_producto,
    pr.nombre AS nombre_producto,
    pr.categoria,
    pr.precio_lista
FROM 
    productos pr
LEFT JOIN (
    SELECT DISTINCT id_producto 
    FROM detalle_pedidos
) d ON pr.id_producto = d.id_producto
WHERE 
    d.id_producto IS NULL;

-- 7. Calcular el total cobrado en costos de envío para todos los pedidos entregados
SELECT 
    SUM(costo_envio) AS total_cobrado_envios
FROM 
    pedidos
WHERE 
    estado = 'Entregado';

-- 8.1 Líneas de detalle que apuntan a un id_pedido inexistente (Detalles huérfanos)
SELECT 
    COUNT(d.id_detalle) AS cantidad_detalles_huerfanos,
    SUM(d.cantidad * d.precio_unitario) AS monto_total_afectado
FROM 
    detalle_pedidos d
LEFT JOIN 
    pedidos p ON d.id_pedido = p.id_pedido
WHERE 
    p.id_pedido IS NULL;


-- 8.2 Desglose por categoría y total general con conteo de pedidos y suma exacta
SELECT 
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    COUNT(d.id_detalle) AS cantidad_lineas,
    SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS monto_total_afectado
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
LEFT JOIN 
    clientes c ON p.id_cliente = c.id_cliente
WHERE 
    c.id_cliente IS NULL 
    AND p.estado = 'Entregado';

-- 8.3 Pedidos con vendedor sin registrar: cantidad y monto total
SELECT 
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    SUM((d.cantidad * d.precio_unitario) * (1 - (COALESCE(d.descuento_pct, 0) / 100))) AS monto_total_afectado
FROM 
    pedidos p
JOIN 
    detalle_pedidos d ON p.id_pedido = d.id_pedido
WHERE 
    p.id_vendedor IS NULL 
    AND p.estado = 'Entregado';

-- 8.4 Pérdida monetaria total en las líneas de detalle afectadas por productos con costo > precio_lista
SELECT 
    COUNT(d.id_detalle) AS cantidad_lineas_afectadas,
    SUM((pr.costo - (d.precio_unitario * (1 - COALESCE(d.descuento_pct, 0) / 100))) * d.cantidad) AS perdida_total_monetaria
FROM 
    detalle_pedidos d
JOIN 
    pedidos p ON d.id_pedido = p.id_pedido
JOIN 
    productos pr ON d.id_producto = pr.id_producto
WHERE 
    p.estado = 'Entregado'
    AND (d.precio_unitario * (1 - COALESCE(d.descuento_pct, 0) / 100)) < pr.costo;

