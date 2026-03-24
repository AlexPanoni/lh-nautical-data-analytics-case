
/* ===== PRÉ-PREPARAÇÃO ===== */

-- Criando uma tabela de vendas já com a coluna de datas corrigida e as 6 linhas vazias excluídas

CREATE TABLE vendas_cleaned AS
SELECT
    id,
    id_client,
    id_product,
    qtd,
    total,
    CASE
        WHEN sale_date ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TO_DATE(sale_date, 'YYYY-MM-DD')
        WHEN sale_date ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(sale_date, 'DD-MM-YYYY')
        ELSE NULL
    END AS sale_date
FROM vendas
WHERE id IS NOT NULL;

/* ===== PREPARAÇÃO DAS BASES PARA ANÁLISE DE PREJUÍZO =====

1) Tabela de Vendas (vendas_cleaned)
A base de vendas utilizada na Questão 1 foi carregada e passou por tratamento para correção de inconsistências identificadas na EDA.
Foram removidas linhas completamente vazias e realizada a padronização da coluna de datas, originalmente em múltiplos formatos (DD-MM-YYYY e YYYY-MM-DD), convertendo-a para o tipo DATE.
O resultado é a tabela vendas_cleaned, contendo apenas registros válidos e prontos para análise.

2) Tabela de Produtos (produtos_cleaned)
Foi utilizada a base tratada na Questão 2, onde as categorias foram padronizadas em três grupos principais (eletronicos, propulsao e ancoragem),
os valores foram convertidos para tipo numérico e registros duplicados foram removidos.
Essa base foi importada como produtos_cleaned.

3) Tabela de Custos de Importação (custos_cleaned)
Foi utilizada a base gerada na Questão 3, originalmente em formato JSON e normalizada para estrutura tabular (CSV).
A coluna de datas foi convertida para o tipo DATE e os custos mantidos como valores numéricos.
A tabela resultante, custos_cleaned, contém o histórico de custos unitários em USD por produto ao longo do tempo.

4) Tabela de Câmbio (exchange_rate)
Para viabilizar a conversão dos custos de USD para BRL, foi construída uma base de câmbio diária utilizando a API oficial do Banco Central do Brasil (Série 10813 – Dólar comercial de venda).
Os dados foram coletados via Python e organizados em um DataFrame contendo a cotação diária.

Como a série oficial não contempla finais de semana e feriados, foi aplicado o método de forward fill (preenchimento pelo último valor disponível),
garantindo a existência de uma cotação para todos os dias do período analisado.

O intervalo coletado vai de 2022-12-31 a 2025-01-01, garantindo cobertura completa para todas as vendas de 2023 e 2024.

A base final foi importada como exchange_rate, contendo:
- date (DATE)
- usd_to_brl (NUMERIC)

Essa estrutura permite o correto cálculo do custo em BRL no dia da venda, conforme exigido no problema.

*/

/* === Calculando custo por transação === */

-- Join entre vendas e câmbio

SELECT
    v.*,
    e.usd_to_brl
FROM vendas_cleaned v
LEFT JOIN exchange_rates e
    ON v.sale_date = e.date;

-- Join com a tabela de custos
--    -> O custo utilizado será aquele da data imediatamente anterior a data de venda, sendo entendido como o custo vigente nesta data

SELECT *
FROM (
    SELECT
        v.id,
        v.id_product,
        v.qtd,
        v.total,
        v.sale_date,
        e.usd_to_brl,
        c.usd_price,
        ROW_NUMBER() OVER (
            PARTITION BY v.id
            ORDER BY c.start_date DESC
        ) AS rn
    FROM vendas_cleaned v
    LEFT JOIN exchange_rates e
        ON v.sale_date = e.date
    LEFT JOIN custos_cleaned c
        ON v.id_product = c.product_id
        AND c.start_date <= v.sale_date
) t
WHERE rn = 1;


-- Tabela com o custo total em R$ calculado

SELECT
    id,
    id_product,
    qtd,
    total,
    sale_date,
    usd_to_brl,
    usd_price,
    ROUND((usd_price * usd_to_brl)::numeric, 2) AS custo_unitario_brl,
    ROUND((usd_price * usd_to_brl * qtd)::numeric, 2) AS custo_total_brl
FROM (
    SELECT
        v.id,
        v.id_product,
        v.qtd,
        v.total,
        v.sale_date,
        e.usd_to_brl,
        c.usd_price,
        ROW_NUMBER() OVER (
            PARTITION BY v.id
            ORDER BY c.start_date DESC
        ) AS rn
    FROM vendas_cleaned v
    LEFT JOIN exchange_rates e
        ON v.sale_date = e.date
    LEFT JOIN custos_cleaned c
        ON v.id_product = c.product_id
        AND c.start_date <= v.sale_date
) t
WHERE rn = 1;

-- Adicionando o lucro por operação (valores negativos indicam o prejuízo)

SELECT
    *,
    ROUND((total - custo_total_brl)::numeric, 2) AS lucro
FROM (
    SELECT
    id,
    id_product,
    qtd,
    total,
    sale_date,
    usd_to_brl,
    usd_price,
    ROUND((usd_price * usd_to_brl)::numeric, 2) AS custo_unitario_brl,
    ROUND((usd_price * usd_to_brl * qtd)::numeric, 2) AS custo_total_brl
FROM (
    SELECT
        v.id,
        v.id_product,
        v.qtd,
        v.total,
        v.sale_date,
        e.usd_to_brl,
        c.usd_price,
        ROW_NUMBER() OVER (
            PARTITION BY v.id
            ORDER BY c.start_date DESC
        ) AS rn
    FROM vendas_cleaned v
    LEFT JOIN exchange_rates e
        ON v.sale_date = e.date
    LEFT JOIN custos_cleaned c
        ON v.id_product = c.product_id
        AND c.start_date <= v.sale_date
) t
WHERE rn = 1
) t;

-- Calculando receita e prejuízo por produto

SELECT
    id_product,

    -- Receita total
    ROUND(SUM(total)::numeric, 2) AS receita_total,

    -- Prejuízo total (apenas perdas, como valor positivo)
    ROUND(SUM(
        CASE 
            WHEN lucro < 0 THEN -lucro
            ELSE 0
        END
    )::numeric, 2) AS prejuizo_total,

    -- Percentual de perda
    ROUND(
        SUM(
            CASE 
                WHEN lucro < 0 THEN -lucro
                ELSE 0
            END
        ) / NULLIF(SUM(total), 0)::numeric
    , 4) * 100 AS percentual_perda

FROM (
    SELECT
    *,
    ROUND((total - custo_total_brl)::numeric, 2) AS lucro
FROM (
    SELECT
    id,
    id_product,
    qtd,
    total,
    sale_date,
    usd_to_brl,
    usd_price,
    ROUND((usd_price * usd_to_brl)::numeric, 2) AS custo_unitario_brl,
    ROUND((usd_price * usd_to_brl * qtd)::numeric, 2) AS custo_total_brl
FROM (
    SELECT
        v.id,
        v.id_product,
        v.qtd,
        v.total,
        v.sale_date,
        e.usd_to_brl,
        c.usd_price,
        ROW_NUMBER() OVER (
            PARTITION BY v.id
            ORDER BY c.start_date DESC
        ) AS rn
    FROM vendas_cleaned v
    LEFT JOIN exchange_rates e
        ON v.sale_date = e.date
    LEFT JOIN custos_cleaned c
        ON v.id_product = c.product_id
        AND c.start_date <= v.sale_date
) t1
WHERE rn = 1
) t2
) t3

GROUP BY id_product
ORDER BY prejuizo_total DESC;