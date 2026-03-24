-- Criando tabela calendário

CREATE TABLE calendario AS
SELECT
    CAST(TO_CHAR(datum, 'YYYYMMDD') AS INTEGER) AS date_id,
    datum::DATE AS date,

    EXTRACT(DAY FROM datum) AS day,
    EXTRACT(MONTH FROM datum) AS month,

    CASE EXTRACT(MONTH FROM datum)
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END AS month_name,

    EXTRACT(YEAR FROM datum) AS year,
    EXTRACT(QUARTER FROM datum) AS quarter,

    EXTRACT(DOW FROM datum) AS day_of_week,

    CASE EXTRACT(DOW FROM datum)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
    END AS day_name,

    CASE 
        WHEN EXTRACT(DOW FROM datum) IN (0, 6) THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM generate_series(
    '2023-01-01'::date,
    '2024-12-31'::date,
    '1 day'::interval
) AS datum;

-- Validando

SELECT * FROM calendario LIMIT 25

-- Preenchendo os dias vazios na tabela de vendas com 0s

SELECT
    d.date,
    d.day_name,
    v.venda_dia,
    COALESCE(v.venda_dia, 0) AS venda_dia_ajustada
FROM calendario d
LEFT JOIN (
    SELECT
        sale_date,
        SUM(total) AS venda_dia
    FROM vendas_cleaned
    GROUP BY sale_date
) v
    ON d.date = v.sale_date
WHERE v.venda_dia IS NULL
ORDER BY d.date;

-- Calculando a média de vendas por dia, já com o controle de contar os dias sem vendas

WITH vendas_por_dia AS (
    SELECT
        sale_date,
        SUM(total) AS venda_dia
    FROM vendas_cleaned
    GROUP BY sale_date
)

, base AS (
    SELECT
        d.date,
        d.day_name,
        COALESCE(v.venda_dia, 0) AS venda_dia
    FROM calendario d
    LEFT JOIN vendas_por_dia v
        ON d.date = v.sale_date
)

SELECT
    day_name,
    ROUND(AVG(venda_dia)::numeric, 2) AS media_vendas
FROM base
GROUP BY day_name
ORDER BY media_vendas ASC;


-- Checando a consulta sem o controle por dias faltantes, simulando o erro do estagiário

SELECT
    CASE EXTRACT(DOW FROM sale_date)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
    END AS day_name,
    
    ROUND(AVG(venda_dia)::numeric, 2) AS media_vendas

FROM (
    SELECT
        sale_date,
        SUM(total) AS venda_dia
    FROM vendas_cleaned
    GROUP BY sale_date
) t

GROUP BY day_name
ORDER BY media_vendas ASC;