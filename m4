    USE Ventas_Tech_DB;


    -- CONSULTA 1: RESUMEN EJECUTIVO MENSUAL

    SELECT
	    MONTH(fecha_venta) AS mes,
	    SUM(cantidad * precio_unitario) AS total_facturado,
	    COUNT(id_venta) AS cantidad_pedidos,
	    AVG(cantidad * precio_unitario) AS ticket_promedio

	    FROM VENTAS
	    GROUP BY MONTH(fecha_venta);

	
	    -- CONSULTA 2: RANKING DE PRODUCTOS

    SELECT TOP 5
        id_producto,
        SUM(cantidad) AS unidades_vendidas,
        SUM(cantidad * precio_unitario) AS total_facturado

	    FROM ventas
	    GROUP BY id_producto
	    ORDER BY total_facturado DESC;


	    -- CONSULTA 3: CLIENTES RECURRENTES

    SELECT
        id_cliente,
        COUNT(*) AS cantidad_pedidos,
        SUM(cantidad * precio_unitario) AS total_gastado

	    FROM ventas
	    GROUP BY id_cliente
	    HAVING COUNT(*) > 1
	    ORDER BY total_gastado DESC;


	    /*
    Nota sobre los datos:
    La base Ventas_Tech_DB contiene registros únicamente del mes de marzo de 2024.
    Por ese motivo, el total facturado de marzo coincide con el promedio mensual
    general. Se incluye la etiqueta "Igual al promedio" para conservar una
    comparación matemáticamente correcta.
    */

    -- CONSULTA 4: MESES POR ENCIMA O POR DEBAJO DEL PROMEDIO

    WITH ventas_mensuales AS (
        SELECT
            MONTH(fecha_venta) AS mes,
            SUM(cantidad * precio_unitario) AS total_facturado
        FROM ventas
        GROUP BY MONTH(fecha_venta)
    )
    SELECT
        mes,
        total_facturado,
        CASE
            WHEN total_facturado > (SELECT AVG(total_facturado) FROM ventas_mensuales)
                THEN 'Por encima'
            WHEN total_facturado < (SELECT AVG(total_facturado) FROM ventas_mensuales)
                THEN 'Por debajo'
            ELSE 'Igual al promedio'
        END AS performance_mensual
    FROM ventas_mensuales;

    -- HALLAZGOS DE NEGOCIO
    /*  1. El producto 1 generó $3.600 de los $6.444 facturados en marzo
        (aproximadamente el 56%). RetailPro debería revisar la disponibilidad
        de este producto y priorizar acciones comerciales para sostener su aporte.

        2. El producto 2 fue el de mayor volumen, con 13 unidades vendidas, pero
        generó solo $364 de facturación. Existe una oportunidad de ofrecerlo
        junto a productos de mayor valor mediante estrategias de venta cruzada.

        3. El cliente 1 acumuló $2.644 en dos pedidos, el mayor gasto entre los
        clientes recurrentes. RetailPro debería priorizar acciones de fidelización
        para este tipo de cliente de alto valor.*/
