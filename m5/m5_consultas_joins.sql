USE Ventas_Tech_DB;


-- PREPARACIÓN DEL MODELO PARA M5


    -- Se crea la tabla territorios para incorporar la región requerida

CREATE TABLE territorios (
    id_territorio INT PRIMARY KEY,
    region VARCHAR(50) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    zona VARCHAR(50) NOT NULL
);


    -- Validación previa: ciudades disponibles para asignar territorios.

SELECT *
FROM clientes;


    -- Carga de territorios para relacionar la ubicación de cada cliente

INSERT INTO territorios (
    id_territorio,
    region,
    pais,
    zona
)
VALUES
    (1, 'Centro', 'Argentina', 'AMBA'),
    (2, 'Centro', 'Argentina', 'Centro'),
    (3, 'Centro', 'Argentina', 'Litoral'),
    (4, 'Cuyo', 'Argentina', 'Oeste'),
    (5, 'Norte', 'Argentina', 'NOA');


    -- Se agregan segmento e id_territorio a clientes.
    -- id_territorio vincula cada cliente con la tabla territorios.

ALTER TABLE clientes
ADD
    segmento VARCHAR(50),
    id_territorio INT;

ALTER TABLE clientes
ADD CONSTRAINT fk_clientes_territorios
    FOREIGN KEY (id_territorio)
    REFERENCES territorios(id_territorio);


    -- Segmentación derivada del gasto acumulado de cada cliente.
    -- La regla permite incluir segmento en la vista base sin inventar datos.

WITH gasto_cliente AS (
    SELECT
        c.id_cliente,
        COALESCE(SUM(v.cantidad * v.precio_unitario), 0) AS total_gastado
    FROM clientes AS c
    LEFT JOIN ventas AS v
        ON c.id_cliente = v.id_cliente
    GROUP BY
        c.id_cliente
)
UPDATE c
SET segmento = CASE
    WHEN g.total_gastado >= 2000.00 THEN 'Alto valor'
    WHEN g.total_gastado >= 500.00 THEN 'Valor medio'
    ELSE 'Bajo valor'
END
FROM clientes AS c
INNER JOIN gasto_cliente AS g
    ON c.id_cliente = g.id_cliente;


    -- Validación previa para crear un producto sin ventas.

SELECT *
FROM categorias;

SELECT *
FROM productos;


    -- Casos de prueba para identificar registros sin ventas.
    -- La clienta y el producto se insertan sin filas relacionadas en ventas.

INSERT INTO clientes (
    id_cliente,
    nombre,
    email,
    ciudad,
    fecha_registro,
    segmento,
    id_territorio
)
VALUES (
    6,
    'Sofía Morales',
    'sofia@mail.com',
    'Buenos Aires',
    '2024-03-15',
    'Sin compras',
    1
);

INSERT INTO productos (
    id_producto,
    nombre_producto,
    id_categoria,
    precio,
    stock,
    activo
)
VALUES (
    7,
    'Webcam',
    2,
    85.00,
    30,
    1
);


-- CONSULTA 1: Vista base enriquecida para Power BI.

    -- Combina ventas con clientes, productos, categorías y territorios.

SELECT
    v.fecha_venta AS fecha,
    c.nombre AS nombre_cliente,
    c.segmento,
    t.region,
    p.nombre_producto,
    ca.nombre_categoria AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario AS total_venta,
    v.canal
FROM ventas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto
INNER JOIN categorias AS ca
    ON p.id_categoria = ca.id_categoria
INNER JOIN territorios AS t
    ON c.id_territorio = t.id_territorio
ORDER BY
    v.fecha_venta,
    v.id_venta;


-- CONSULTA 2: Clientes registrados sin ventas.

    -- LEFT JOIN conserva todos los clientes y el filtro IS NULL identifica aquellos que no tienen compras relacionadas.

SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;


-- CONSULTA 3: Productos del catálogo sin ventas.

    -- LEFT JOIN conserva todos los productos y el filtro IS NULL identifica los que todavía no tienen movimiento comercial.

SELECT
    p.nombre_producto,
    ca.nombre_categoria AS categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS ca
    ON p.id_categoria = ca.id_categoria
LEFT JOIN ventas AS v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL;


-- CONSULTA 4: Consolidado de ventas por canal con UNION ALL.

    -- UNION ALL conserva todas las ventas de Online y Presencial.

WITH ventas_por_canal AS (
    SELECT
        'Online' AS canal,
        cantidad * precio_unitario AS total_venta
    FROM ventas
    WHERE canal = 'Online'

    UNION ALL

    SELECT
        'Presencial' AS canal,
        cantidad * precio_unitario AS total_venta
    FROM ventas
    WHERE canal = 'Presencial'
)
SELECT
    canal,
    SUM(total_venta) AS total_facturado
FROM ventas_por_canal
GROUP BY
    canal
ORDER BY
    canal;


-- HALLAZGOS CLAVE

        -- 1. En los datos de práctica, el canal Online factura $4.560, frente a $1.884 del canal Presencial. Conviene priorizar el análisis de la experiencia digital y las acciones comerciales de ese canal.

        -- 2. Sofía Morales está registrada pero no realizó compras. CRM puede activar una campaña de bienvenida o un incentivo de primera compra.

        -- 3. El producto Webcam no registra ventas. Conviene revisar su visibilidad, precio o estrategia de lanzamiento dentro de la categoría Accesorios.
