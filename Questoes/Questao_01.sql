create database exercicio

-- Resumo geral do dataset - Query única que responde a tudo

SELECT
    COUNT(*) AS total_linhas,
    (SELECT COUNT(*) 
     FROM information_schema.columns
     WHERE table_name = 'vendas' AND table_schema = 'public') AS total_colunas,
    MIN(sale_date) AS data_minima,
    MAX(sale_date) AS data_maxima,
    MIN(total) AS valor_minimo,
    MAX(total) AS valor_maximo,
    ROUND(AVG(total)::numeric, 2) AS valor_medio
FROM vendas;

/*
Observação: a coluna sale_date está armazenada como texto e possui múltiplos formatos,
portanto os valores mínimo e máximo refletem ordenação textual (lexicográfica),
podendo não representar corretamente o intervalo temporal real.
A validação correta é apresentada na análise detalhada abaixo.
*/


/* ============ ANÁLISE DETALHADA E COMENTADA ============== */ 

/* ===== ANÁLISE DO DATASET ==== */

-- Amostra dos dados

SELECT * 
FROM vendas
LIMIT 10;

-- Contagem de linhas

SELECT COUNT(*) AS total_linhas
FROM vendas;

-- Contagem de colunas

SELECT COUNT(*) AS total_colunas
FROM information_schema.columns
WHERE table_name = 'vendas'
  AND table_schema = 'public';

/* A consulta retornou: 6 colunas e 9901 linhas. 
 * O arquivo em CSV possui, no total, 9902 linhas, uma vez que inclui uma linha inicial com os nomes das colunas */

-- Contagem de linhas completamente vazias

SELECT COUNT(*) AS linhas_vazias
FROM vendas
WHERE id IS NULL
  AND id_client IS NULL
  AND id_product IS NULL
  AND qtd IS NULL
  AND total IS NULL
  AND sale_date IS NULL;

/* A consulta retornou: 6 linhas vazias. O dataset tem, portanto, 9895 linhas válidas */

/* ===== ANÁLISE DA COLUNA DE DATAS (sale_date) ==== */

-- Amostra da coluna sale_date

SELECT sale_date
FROM vendas
LIMIT 20;

-- Tipo da coluna sale_date

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vendas'
  AND column_name = 'sale_date';

-- Contagem por padrão de data

SELECT
    CASE 
        WHEN sale_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN sale_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'DD-MM-YYYY'
        ELSE 'OUTROS'
    END AS formato_data,
    COUNT(*) AS quantidade
FROM vendas
GROUP BY formato_data;

/*
A coluna sale_date está armazenada como texto (varchar/text) e apresenta múltiplos formatos
(YYYY-MM-DD e DD-MM-YYYY), conforme evidenciado na análise acima.

Essa inconsistência impede a conversão direta e confiável para o tipo DATE no banco de dados,
comprometendo análises temporais sem padronização prévia.
*/

-- Conversão controlada de datas para formato DATE

SELECT
    sale_date,
    CASE
        WHEN sale_date ~ '^\d{4}-\d{2}-\d{2}$' 
            THEN TO_DATE(sale_date, 'YYYY-MM-DD')
        WHEN sale_date ~ '^\d{2}-\d{2}-\d{4}$' 
            THEN TO_DATE(sale_date, 'DD-MM-YYYY')
        ELSE NULL
    END AS parsed_date
FROM vendas;

/* Coluna auxiliar 'parsed_date' permite a conversão consistente das datas para o tipo DATE */

-- Intervalo real das datas (após padronização)

SELECT
    MIN(parsed_date) AS data_minima_real,
    MAX(parsed_date) AS data_maxima_real
FROM (
    SELECT
        CASE
            WHEN sale_date ~ '^\d{4}-\d{2}-\d{2}$' 
                THEN TO_DATE(sale_date, 'YYYY-MM-DD')
            WHEN sale_date ~ '^\d{2}-\d{2}-\d{4}$' 
                THEN TO_DATE(sale_date, 'DD-MM-YYYY')
            ELSE NULL
        END AS parsed_date
    FROM vendas
) t;

/*
Para validar o intervalo real das datas, foi realizada uma conversão controlada,
tratando explicitamente os dois formatos identificados (YYYY-MM-DD e DD-MM-YYYY).

Essa abordagem permite obter um intervalo temporal confiável, sem alterar os dados originais,
servindo apenas como diagnóstico da consistência da coluna.

=> Após a padronização, verifica-se que todas as datas estão contidas entre 2023-01-01 e 2024-12-31,
indicando consistência temporal dos registros e integridade dos valores, apesar da inconsistência de formato.
*/

/* ===== ANÁLISE DA COLUNA DE VALORES (total) ==== */

-- Tipo da coluna 

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vendas'
  AND column_name = 'total';

-- Verificação de valores nulos e negativos

SELECT
    COUNT(*) FILTER (WHERE total IS NULL) AS valores_nulos,
    COUNT(*) FILTER (WHERE total < 0) AS valores_negativos
FROM vendas;

/* A coluna possui o tipo "real", própria para valores numéricos com casas decimais.
 * Não possui valores negativos. 
 * Os valores nulos (6 ocorrências) correspondem às linhas completamente vazias identificadas anteriormente. */

-- Estatísticas da coluna total

SELECT
    MIN(total) AS valor_minimo,
    MAX(total) AS valor_maximo,
    AVG(total) AS valor_medio,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total) AS mediana
FROM vendas;

/*Valores encontrados:
 *  Valor Mínimo: 294,50
 *  Valor Máximo: 2.222.973,00
 *  Valor Médio: 263.797,83
 *  Mediana: 82.225,0
 */




