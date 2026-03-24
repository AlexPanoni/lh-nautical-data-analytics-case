select * from customers_raw cr 

-- Unindo Vendas, Produtos e Clientes

SELECT
    vc.id,
    vc.id_client,
    cr.full_name AS nome_cliente,
    vc.id_product,
    pc.name AS nome_produto,
    pc.actual_category,
    vc.qtd,
    vc.total
FROM vendas_cleaned vc
JOIN produtos_cleaned pc 
    ON vc.id_product = pc.code
JOIN customers_raw cr 
    ON vc.id_client = cr.code
LIMIT 10

-- Calculando Faturamento Total, Frequência, Ticket Médio e Diversidade (categoria e produto)

WITH base AS (
SELECT
	vc.id,
	vc.id_client,
	cr.full_name AS nome_cliente,
	vc.id_product,
	pc.name AS nome_produto,
	pc.actual_category AS category ,
	vc.qtd,
	vc.total
FROM
	vendas_cleaned vc
JOIN produtos_cleaned pc 
    ON
	vc.id_product = pc.code
JOIN customers_raw cr 
    ON
	vc.id_client = cr.code
)

SELECT
	id_client,
	nome_cliente,
	ROUND(SUM(total)::numeric, 2) AS faturamento_total,
	COUNT(id) AS frequencia,
	ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket_medio,
	COUNT(DISTINCT category) AS diversidade_categoria,
	COUNT(DISTINCT id_product) AS diversidade_produto
FROM
	base
GROUP BY
	id_client, nome_cliente
ORDER BY
	ticket_medio DESC
	
	
-- Filtrando para os 10 principais clientes por ticket médio, entre aqueles que compraram de 3 ou mais categorias
	
WITH base AS (
    SELECT
        vc.id,
        vc.id_client,
        cr.full_name AS nome_cliente,
        vc.id_product,
        pc.actual_category AS category,
        vc.qtd,
        vc.total
    FROM vendas_cleaned vc
    JOIN produtos_cleaned pc 
        ON vc.id_product = pc.code
    JOIN customers_raw cr 
        ON vc.id_client = cr.code
),

metricas AS (
    SELECT
        id_client,
        nome_cliente,
        ROUND(SUM(total)::numeric, 2) AS faturamento_total,
        COUNT(id) AS frequencia,
        ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket_medio,
        COUNT(DISTINCT category) AS diversidade_categoria
    FROM base
    GROUP BY id_client, nome_cliente
),

clientes_fieis AS (
    SELECT 
    	*
    FROM 
    	metricas
    WHERE diversidade_categoria >= 3
    ORDER BY ticket_medio DESC, id_client ASC
    LIMIT 10
)


SELECT 
	* 
FROM 
	clientes_fieis;

/* OBSERVAÇÃO
 * - Todos os 49 clientes da base apresentam diversidade de categoria 3. Desta forma, este critério não representa um filtro de fato
 * - Não houve empate no Ticket Médio
 */

-- Identificando a Categoria com mais produtos comprados entre os 10 clientes com maior ticket médio

WITH base AS (
    SELECT
        vc.id,
        vc.id_client,
        cr.full_name AS nome_cliente,
        vc.id_product,
        pc.actual_category AS category,
        vc.qtd,
        vc.total
    FROM vendas_cleaned vc
    JOIN produtos_cleaned pc 
        ON vc.id_product = pc.code
    JOIN customers_raw cr 
        ON vc.id_client = cr.code
),

metricas AS (
    SELECT
        id_client,
        nome_cliente,
        ROUND(SUM(total)::numeric, 2) AS faturamento_total,
        COUNT(id) AS frequencia,
        ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket_medio,
        COUNT(DISTINCT category) AS diversidade_categoria
    FROM base
    GROUP BY id_client, nome_cliente
),

clientes_fieis AS (
    SELECT *
    FROM metricas
    WHERE diversidade_categoria >= 3
    ORDER BY ticket_medio DESC, id_client ASC
    LIMIT 10
)

SELECT
    b.category,
    SUM(b.qtd) AS total_itens_vendidos
FROM base b
JOIN clientes_fieis cf
    ON b.id_client = cf.id_client
GROUP BY b.category
ORDER BY total_itens_vendidos DESC;