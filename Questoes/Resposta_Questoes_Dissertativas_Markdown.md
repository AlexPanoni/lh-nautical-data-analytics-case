***Questão 1***



Código:



\-- Resumo geral do dataset - Query única que responde a tudo



SELECT

&#x20;   COUNT(\*) AS total\_linhas,

&#x20;   (SELECT COUNT(\*) 

&#x20;    FROM information\_schema.columns

&#x20;    WHERE table\_name = 'vendas' AND table\_schema = 'public') AS total\_colunas,

&#x20;   MIN(sale\_date) AS data\_minima,

&#x20;   MAX(sale\_date) AS data\_maxima,

&#x20;   MIN(total) AS valor\_minimo,

&#x20;   MAX(total) AS valor\_maximo,

&#x20;   ROUND(AVG(total)::numeric, 2) AS valor\_medio

FROM vendas;



/\*

Observação: a coluna sale\_date está armazenada como texto e possui múltiplos formatos,

portanto os valores mínimo e máximo refletem ordenação textual (lexicográfica),

podendo não representar corretamente o intervalo temporal real.

A validação correta é apresentada na análise detalhada abaixo.

\*/





/\* ============ ANÁLISE DETALHADA E COMENTADA ============== \*/ 



/\* ===== ANÁLISE DO DATASET ==== \*/



\-- Amostra dos dados



SELECT \* 

FROM vendas

LIMIT 10;



\-- Contagem de linhas



SELECT COUNT(\*) AS total\_linhas

FROM vendas;



\-- Contagem de colunas



SELECT COUNT(\*) AS total\_colunas

FROM information\_schema.columns

WHERE table\_name = 'vendas'

&#x20; AND table\_schema = 'public';



/\* A consulta retornou: 6 colunas e 9901 linhas. 

&#x20;\* O arquivo em CSV possui, no total, 9902 linhas, uma vez que inclui uma linha inicial com os nomes das colunas \*/



\-- Contagem de linhas completamente vazias



SELECT COUNT(\*) AS linhas\_vazias

FROM vendas

WHERE id IS NULL

&#x20; AND id\_client IS NULL

&#x20; AND id\_product IS NULL

&#x20; AND qtd IS NULL

&#x20; AND total IS NULL

&#x20; AND sale\_date IS NULL;



/\* A consulta retornou: 6 linhas vazias. O dataset tem, portanto, 9895 linhas válidas \*/



/\* ===== ANÁLISE DA COLUNA DE DATAS (sale\_date) ==== \*/



\-- Amostra da coluna sale\_date



SELECT sale\_date

FROM vendas

LIMIT 20;



\-- Tipo da coluna sale\_date



SELECT column\_name, data\_type

FROM information\_schema.columns

WHERE table\_name = 'vendas'

&#x20; AND column\_name = 'sale\_date';



\-- Contagem por padrão de data



SELECT

&#x20;   CASE 

&#x20;       WHEN sale\_date \~ '^\\d{4}-\\d{2}-\\d{2}$' THEN 'YYYY-MM-DD'

&#x20;       WHEN sale\_date \~ '^\\d{2}-\\d{2}-\\d{4}$' THEN 'DD-MM-YYYY'

&#x20;       ELSE 'OUTROS'

&#x20;   END AS formato\_data,

&#x20;   COUNT(\*) AS quantidade

FROM vendas

GROUP BY formato\_data;



/\*

A coluna sale\_date está armazenada como texto (varchar/text) e apresenta múltiplos formatos

(YYYY-MM-DD e DD-MM-YYYY), conforme evidenciado na análise acima.



Essa inconsistência impede a conversão direta e confiável para o tipo DATE no banco de dados,

comprometendo análises temporais sem padronização prévia.

\*/



\-- Conversão controlada de datas para formato DATE



SELECT

&#x20;   sale\_date,

&#x20;   CASE

&#x20;       WHEN sale\_date \~ '^\\d{4}-\\d{2}-\\d{2}$' 

&#x20;           THEN TO\_DATE(sale\_date, 'YYYY-MM-DD')

&#x20;       WHEN sale\_date \~ '^\\d{2}-\\d{2}-\\d{4}$' 

&#x20;           THEN TO\_DATE(sale\_date, 'DD-MM-YYYY')

&#x20;       ELSE NULL

&#x20;   END AS parsed\_date

FROM vendas;



/\* Coluna auxiliar 'parsed\_date' permite a conversão consistente das datas para o tipo DATE \*/



\-- Intervalo real das datas (após padronização)



SELECT

&#x20;   MIN(parsed\_date) AS data\_minima\_real,

&#x20;   MAX(parsed\_date) AS data\_maxima\_real

FROM (

&#x20;   SELECT

&#x20;       CASE

&#x20;           WHEN sale\_date \~ '^\\d{4}-\\d{2}-\\d{2}$' 

&#x20;               THEN TO\_DATE(sale\_date, 'YYYY-MM-DD')

&#x20;           WHEN sale\_date \~ '^\\d{2}-\\d{2}-\\d{4}$' 

&#x20;               THEN TO\_DATE(sale\_date, 'DD-MM-YYYY')

&#x20;           ELSE NULL

&#x20;       END AS parsed\_date

&#x20;   FROM vendas

) t;



/\*

Para validar o intervalo real das datas, foi realizada uma conversão controlada,

tratando explicitamente os dois formatos identificados (YYYY-MM-DD e DD-MM-YYYY).



Essa abordagem permite obter um intervalo temporal confiável, sem alterar os dados originais,

servindo apenas como diagnóstico da consistência da coluna.



=> Após a padronização, verifica-se que todas as datas estão contidas entre 2023-01-01 e 2024-12-31,

indicando consistência temporal dos registros e integridade dos valores, apesar da inconsistência de formato.

\*/



/\* ===== ANÁLISE DA COLUNA DE VALORES (total) ==== \*/



\-- Tipo da coluna 



SELECT column\_name, data\_type

FROM information\_schema.columns

WHERE table\_name = 'vendas'

&#x20; AND column\_name = 'total';



\-- Verificação de valores nulos e negativos



SELECT

&#x20;   COUNT(\*) FILTER (WHERE total IS NULL) AS valores\_nulos,

&#x20;   COUNT(\*) FILTER (WHERE total < 0) AS valores\_negativos

FROM vendas;



/\* A coluna possui o tipo "real", própria para valores numéricos com casas decimais.

&#x20;\* Não possui valores negativos. 

&#x20;\* Os valores nulos (6 ocorrências) correspondem às linhas completamente vazias identificadas anteriormente. \*/



\-- Estatísticas da coluna total



SELECT

&#x20;   MIN(total) AS valor\_minimo,

&#x20;   MAX(total) AS valor\_maximo,

&#x20;   AVG(total) AS valor\_medio,

&#x20;   PERCENTILE\_CONT(0.5) WITHIN GROUP (ORDER BY total) AS mediana

FROM vendas;



/\*Valores encontrados:

&#x20;\*  Valor Mínimo: 294,50

&#x20;\*  Valor Máximo: 2.222.973,00

&#x20;\*  Valor Médio: 263.797,83

&#x20;\*  Mediana: 82.225,0

&#x20;\*/









***Questão 1.2***



2222973.0



***Questão 1.3***



A análise exploratória inicial mostra que o dataset tem um bom volume de registros e cobre todo o período de 2023 a 2024. No entanto, foram identificadas algumas inconsistências estruturais que impactam sua utilização direta sem tratamento prévio.  



O arquivo original traz linhas completamente vazias, o que indica falhas na geração ou manutenção dos dados. A coluna de datas também aparece em diferentes formatos (DD-MM-YYYY e YYYY-MM-DD), o que impede a conversão direta para datetime e afeta qualquer análise temporal sem padronização. 



A variável "total" apresenta boa consistência estrutural, sem valores nulos ou negativos, e com tipagem adequada para análise. Observa-se, entretanto, uma distribuição assimétrica, com diferença significativa entre valores mínimo, médio, mediano e máximo, indicando a presença de valores elevados. Esses registros podem ser classificados como outliers sob o ponto de vista estatístico, mas exigem análise mais aprofundada para determinar se representam anomalias ou comportamentos legítimos do negócio. 



No geral, o dataset tem bom potencial analítico e os dados fazem sentido para o contexto. No entanto, não pode ser tratado como totalmente confiável em seu formato bruto original. Antes de avançar para análises mais complexas, é necessário limpar as linhas vazias e padronizar o formato das datas.



***Questão 2.1***



Jupyter Notebook - Lighthouse\_Questao2 em anexo







**Questão 2.2**



Total de 7 linhas duplicadas



***Questão 3.1***



Jupyter Notebook - Lighthouse\_Questao3 em anexo





***Questão 3.2***



1260 entradas



***Questão 4.1***



Código:



/\* ===== PRÉ-PREPARAÇÃO ===== \*/



\-- Criando uma tabela de vendas já com a coluna de datas corrigida e as 6 linhas vazias excluídas



CREATE TABLE vendas\_cleaned AS

SELECT

&#x20;   id,

&#x20;   id\_client,

&#x20;   id\_product,

&#x20;   qtd,

&#x20;   total,

&#x20;   CASE

&#x20;       WHEN sale\_date \~ '^\\d{4}-\\d{2}-\\d{2}$'

&#x20;           THEN TO\_DATE(sale\_date, 'YYYY-MM-DD')

&#x20;       WHEN sale\_date \~ '^\\d{2}-\\d{2}-\\d{4}$'

&#x20;           THEN TO\_DATE(sale\_date, 'DD-MM-YYYY')

&#x20;       ELSE NULL

&#x20;   END AS sale\_date

FROM vendas

WHERE id IS NOT NULL;



/\* ===== PREPARAÇÃO DAS BASES PARA ANÁLISE DE PREJUÍZO =====



1\) Tabela de Vendas (vendas\_cleaned)

A base de vendas utilizada na Questão 1 foi carregada e passou por tratamento para correção de inconsistências identificadas na EDA.

Foram removidas linhas completamente vazias e realizada a padronização da coluna de datas, originalmente em múltiplos formatos (DD-MM-YYYY e YYYY-MM-DD), convertendo-a para o tipo DATE.

O resultado é a tabela vendas\_cleaned, contendo apenas registros válidos e prontos para análise.



2\) Tabela de Produtos (produtos\_cleaned)

Foi utilizada a base tratada na Questão 2, onde as categorias foram padronizadas em três grupos principais (eletronicos, propulsao e ancoragem),

os valores foram convertidos para tipo numérico e registros duplicados foram removidos.

Essa base foi importada como produtos\_cleaned.



3\) Tabela de Custos de Importação (custos\_cleaned)

Foi utilizada a base gerada na Questão 3, originalmente em formato JSON e normalizada para estrutura tabular (CSV).

A coluna de datas foi convertida para o tipo DATE e os custos mantidos como valores numéricos.

A tabela resultante, custos\_cleaned, contém o histórico de custos unitários em USD por produto ao longo do tempo.



4\) Tabela de Câmbio (exchange\_rate)

Para viabilizar a conversão dos custos de USD para BRL, foi construída uma base de câmbio diária utilizando a API oficial do Banco Central do Brasil (Série 10813 – Dólar comercial de venda).

Os dados foram coletados via Python e organizados em um DataFrame contendo a cotação diária.



Como a série oficial não contempla finais de semana e feriados, foi aplicado o método de forward fill (preenchimento pelo último valor disponível),

garantindo a existência de uma cotação para todos os dias do período analisado.



O intervalo coletado vai de 2022-12-31 a 2025-01-01, garantindo cobertura completa para todas as vendas de 2023 e 2024.



A base final foi importada como exchange\_rate, contendo:

\- date (DATE)

\- usd\_to\_brl (NUMERIC)



Essa estrutura permite o correto cálculo do custo em BRL no dia da venda, conforme exigido no problema.



\*/



/\* === Calculando custo por transação === \*/



\-- Join entre vendas e câmbio



SELECT

&#x20;   v.\*,

&#x20;   e.usd\_to\_brl

FROM vendas\_cleaned v

LEFT JOIN exchange\_rates e

&#x20;   ON v.sale\_date = e.date;



\-- Join com a tabela de custos

\--    -> O custo utilizado será aquele da data imediatamente anterior a data de venda, sendo entendido como o custo vigente nesta data



SELECT \*

FROM (

&#x20;   SELECT

&#x20;       v.id,

&#x20;       v.id\_product,

&#x20;       v.qtd,

&#x20;       v.total,

&#x20;       v.sale\_date,

&#x20;       e.usd\_to\_brl,

&#x20;       c.usd\_price,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY v.id

&#x20;           ORDER BY c.start\_date DESC

&#x20;       ) AS rn

&#x20;   FROM vendas\_cleaned v

&#x20;   LEFT JOIN exchange\_rates e

&#x20;       ON v.sale\_date = e.date

&#x20;   LEFT JOIN custos\_cleaned c

&#x20;       ON v.id\_product = c.product\_id

&#x20;       AND c.start\_date <= v.sale\_date

) t

WHERE rn = 1;





\-- Tabela com o custo total em R$ calculado



SELECT

&#x20;   id,

&#x20;   id\_product,

&#x20;   qtd,

&#x20;   total,

&#x20;   sale\_date,

&#x20;   usd\_to\_brl,

&#x20;   usd\_price,

&#x20;   ROUND((usd\_price \* usd\_to\_brl)::numeric, 2) AS custo\_unitario\_brl,

&#x20;   ROUND((usd\_price \* usd\_to\_brl \* qtd)::numeric, 2) AS custo\_total\_brl

FROM (

&#x20;   SELECT

&#x20;       v.id,

&#x20;       v.id\_product,

&#x20;       v.qtd,

&#x20;       v.total,

&#x20;       v.sale\_date,

&#x20;       e.usd\_to\_brl,

&#x20;       c.usd\_price,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY v.id

&#x20;           ORDER BY c.start\_date DESC

&#x20;       ) AS rn

&#x20;   FROM vendas\_cleaned v

&#x20;   LEFT JOIN exchange\_rates e

&#x20;       ON v.sale\_date = e.date

&#x20;   LEFT JOIN custos\_cleaned c

&#x20;       ON v.id\_product = c.product\_id

&#x20;       AND c.start\_date <= v.sale\_date

) t

WHERE rn = 1;



\-- Adicionando o lucro por operação (valores negativos indicam o prejuízo)



SELECT

&#x20;   \*,

&#x20;   ROUND((total - custo\_total\_brl)::numeric, 2) AS lucro

FROM (

&#x20;   SELECT

&#x20;   id,

&#x20;   id\_product,

&#x20;   qtd,

&#x20;   total,

&#x20;   sale\_date,

&#x20;   usd\_to\_brl,

&#x20;   usd\_price,

&#x20;   ROUND((usd\_price \* usd\_to\_brl)::numeric, 2) AS custo\_unitario\_brl,

&#x20;   ROUND((usd\_price \* usd\_to\_brl \* qtd)::numeric, 2) AS custo\_total\_brl

FROM (

&#x20;   SELECT

&#x20;       v.id,

&#x20;       v.id\_product,

&#x20;       v.qtd,

&#x20;       v.total,

&#x20;       v.sale\_date,

&#x20;       e.usd\_to\_brl,

&#x20;       c.usd\_price,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY v.id

&#x20;           ORDER BY c.start\_date DESC

&#x20;       ) AS rn

&#x20;   FROM vendas\_cleaned v

&#x20;   LEFT JOIN exchange\_rates e

&#x20;       ON v.sale\_date = e.date

&#x20;   LEFT JOIN custos\_cleaned c

&#x20;       ON v.id\_product = c.product\_id

&#x20;       AND c.start\_date <= v.sale\_date

) t

WHERE rn = 1

) t;



\-- Calculando receita e prejuízo por produto



SELECT

&#x20;   id\_product,



&#x20;   -- Receita total

&#x20;   ROUND(SUM(total)::numeric, 2) AS receita\_total,



&#x20;   -- Prejuízo total (apenas perdas, como valor positivo)

&#x20;   ROUND(SUM(

&#x20;       CASE 

&#x20;           WHEN lucro < 0 THEN -lucro

&#x20;           ELSE 0

&#x20;       END

&#x20;   )::numeric, 2) AS prejuizo\_total,



&#x20;   -- Percentual de perda

&#x20;   ROUND(

&#x20;       SUM(

&#x20;           CASE 

&#x20;               WHEN lucro < 0 THEN -lucro

&#x20;               ELSE 0

&#x20;           END

&#x20;       ) / NULLIF(SUM(total), 0)::numeric

&#x20;   , 4) \* 100 AS percentual\_perda



FROM (

&#x20;   SELECT

&#x20;   \*,

&#x20;   ROUND((total - custo\_total\_brl)::numeric, 2) AS lucro

FROM (

&#x20;   SELECT

&#x20;   id,

&#x20;   id\_product,

&#x20;   qtd,

&#x20;   total,

&#x20;   sale\_date,

&#x20;   usd\_to\_brl,

&#x20;   usd\_price,

&#x20;   ROUND((usd\_price \* usd\_to\_brl)::numeric, 2) AS custo\_unitario\_brl,

&#x20;   ROUND((usd\_price \* usd\_to\_brl \* qtd)::numeric, 2) AS custo\_total\_brl

FROM (

&#x20;   SELECT

&#x20;       v.id,

&#x20;       v.id\_product,

&#x20;       v.qtd,

&#x20;       v.total,

&#x20;       v.sale\_date,

&#x20;       e.usd\_to\_brl,

&#x20;       c.usd\_price,

&#x20;       ROW\_NUMBER() OVER (

&#x20;           PARTITION BY v.id

&#x20;           ORDER BY c.start\_date DESC

&#x20;       ) AS rn

&#x20;   FROM vendas\_cleaned v

&#x20;   LEFT JOIN exchange\_rates e

&#x20;       ON v.sale\_date = e.date

&#x20;   LEFT JOIN custos\_cleaned c

&#x20;       ON v.id\_product = c.product\_id

&#x20;       AND c.start\_date <= v.sale\_date

) t1

WHERE rn = 1

) t2

) t3



GROUP BY id\_product

ORDER BY prejuizo\_total DESC;



***Questão 4.2 - Validação***



72



***Questão 4.3***



Para o cálculo do custo em reais, utilizei a cotação do dólar correspondente à data da venda. Os dados de câmbio foram obtidos via API do Banco Central, utilizando a série de código 10813, que representa o dólar comercial de venda diário — referência adequada para operações de importação.



Como a série não contempla finais de semana e feriados, apliquei um forward fill, utilizando sempre a última cotação disponível para garantir que todas as datas de venda tivessem um valor de câmbio associado.



O prejuízo foi definido como a diferença entre o custo total da venda e o valor faturado. Na prática, calculei o lucro (receita menos custo) e considerei como prejuízo apenas os casos em que esse valor foi negativo, convertendo esses valores para positivo para facilitar a análise agregada.



Em relação ao custo dos produtos, como os dados são históricos, considerei sempre o valor mais recente disponível até a data da venda. Ou seja, para cada transação, utilizei o custo vigente naquele momento, o que faz mais sentido do ponto de vista de negócio.



Por fim, conforme orientado no enunciado, não foram considerados impostos, frete ou outros custos adicionais, mantendo o foco na relação entre preço de venda e custo de aquisição convertido para reais.



***Questão 5.1***



Código:



select \* from customers\_raw cr 



\-- Unindo Vendas, Produtos e Clientes



SELECT

&#x20;   vc.id,

&#x20;   vc.id\_client,

&#x20;   cr.full\_name AS nome\_cliente,

&#x20;   vc.id\_product,

&#x20;   pc.name AS nome\_produto,

&#x20;   pc.actual\_category,

&#x20;   vc.qtd,

&#x20;   vc.total

FROM vendas\_cleaned vc

JOIN produtos\_cleaned pc 

&#x20;   ON vc.id\_product = pc.code

JOIN customers\_raw cr 

&#x20;   ON vc.id\_client = cr.code

LIMIT 10



\-- Calculando Faturamento Total, Frequência, Ticket Médio e Diversidade (categoria e produto)



WITH base AS (

SELECT

&#x09;vc.id,

&#x09;vc.id\_client,

&#x09;cr.full\_name AS nome\_cliente,

&#x09;vc.id\_product,

&#x09;pc.name AS nome\_produto,

&#x09;pc.actual\_category AS category ,

&#x09;vc.qtd,

&#x09;vc.total

FROM

&#x09;vendas\_cleaned vc

JOIN produtos\_cleaned pc 

&#x20;   ON

&#x09;vc.id\_product = pc.code

JOIN customers\_raw cr 

&#x20;   ON

&#x09;vc.id\_client = cr.code

)



SELECT

&#x09;id\_client,

&#x09;nome\_cliente,

&#x09;ROUND(SUM(total)::numeric, 2) AS faturamento\_total,

&#x09;COUNT(id) AS frequencia,

&#x09;ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket\_medio,

&#x09;COUNT(DISTINCT category) AS diversidade\_categoria,

&#x09;COUNT(DISTINCT id\_product) AS diversidade\_produto

FROM

&#x09;base

GROUP BY

&#x09;id\_client, nome\_cliente

ORDER BY

&#x09;ticket\_medio DESC

&#x09;

&#x09;

\-- Filtrando para os 10 principais clientes por ticket médio, entre aqueles que compraram de 3 ou mais categorias

&#x09;

WITH base AS (

&#x20;   SELECT

&#x20;       vc.id,

&#x20;       vc.id\_client,

&#x20;       cr.full\_name AS nome\_cliente,

&#x20;       vc.id\_product,

&#x20;       pc.actual\_category AS category,

&#x20;       vc.qtd,

&#x20;       vc.total

&#x20;   FROM vendas\_cleaned vc

&#x20;   JOIN produtos\_cleaned pc 

&#x20;       ON vc.id\_product = pc.code

&#x20;   JOIN customers\_raw cr 

&#x20;       ON vc.id\_client = cr.code

),



metricas AS (

&#x20;   SELECT

&#x20;       id\_client,

&#x20;       nome\_cliente,

&#x20;       ROUND(SUM(total)::numeric, 2) AS faturamento\_total,

&#x20;       COUNT(id) AS frequencia,

&#x20;       ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket\_medio,

&#x20;       COUNT(DISTINCT category) AS diversidade\_categoria

&#x20;   FROM base

&#x20;   GROUP BY id\_client, nome\_cliente

),



clientes\_fieis AS (

&#x20;   SELECT 

&#x20;   	\*

&#x20;   FROM 

&#x20;   	metricas

&#x20;   WHERE diversidade\_categoria >= 3

&#x20;   ORDER BY ticket\_medio DESC, id\_client ASC

&#x20;   LIMIT 10

)





SELECT 

&#x09;\* 

FROM 

&#x09;clientes\_fieis;



/\* OBSERVAÇÃO

&#x20;\* - Todos os 49 clientes da base apresentam diversidade de categoria 3. Desta forma, este critério não representa um filtro de fato

&#x20;\* - Não houve empate no Ticket Médio

&#x20;\*/



\-- Identificando a Categoria com mais produtos comprados entre os 10 clientes com maior ticket médio



WITH base AS (

&#x20;   SELECT

&#x20;       vc.id,

&#x20;       vc.id\_client,

&#x20;       cr.full\_name AS nome\_cliente,

&#x20;       vc.id\_product,

&#x20;       pc.actual\_category AS category,

&#x20;       vc.qtd,

&#x20;       vc.total

&#x20;   FROM vendas\_cleaned vc

&#x20;   JOIN produtos\_cleaned pc 

&#x20;       ON vc.id\_product = pc.code

&#x20;   JOIN customers\_raw cr 

&#x20;       ON vc.id\_client = cr.code

),



metricas AS (

&#x20;   SELECT

&#x20;       id\_client,

&#x20;       nome\_cliente,

&#x20;       ROUND(SUM(total)::numeric, 2) AS faturamento\_total,

&#x20;       COUNT(id) AS frequencia,

&#x20;       ROUND((SUM(total) / COUNT(id))::numeric, 2) AS ticket\_medio,

&#x20;       COUNT(DISTINCT category) AS diversidade\_categoria

&#x20;   FROM base

&#x20;   GROUP BY id\_client, nome\_cliente

),



clientes\_fieis AS (

&#x20;   SELECT \*

&#x20;   FROM metricas

&#x20;   WHERE diversidade\_categoria >= 3

&#x20;   ORDER BY ticket\_medio DESC, id\_client ASC

&#x20;   LIMIT 10

)



SELECT

&#x20;   b.category,

&#x20;   SUM(b.qtd) AS total\_itens\_vendidos

FROM base b

JOIN clientes\_fieis cf

&#x20;   ON b.id\_client = cf.id\_client

GROUP BY b.category

ORDER BY total\_itens\_vendidos DESC;





***Questão 5.2 - Validação***



Propulsão (6030 itens)



***Questão 5.3***



A limpeza das categorias foi realizada previamente na Questão 2, utilizando Python em ambiente Jupyter Notebook. A coluna original apresentava alta inconsistência, com diversas variações de escrita para as mesmas categorias (aproximadamente 39 formas distintas). Para resolver isso, apliquei uma função de mapeamento que padroniza essas variações nas três categorias principais: eletrônicos, propulsão e ancoragem.



Para o filtro de clientes, calculei a diversidade de categorias como a quantidade de categorias distintas compradas por cada cliente (COUNT(DISTINCT category)). Em seguida, apliquei o critério definido no enunciado, mantendo apenas clientes com diversidade maior ou igual a 3. Durante a análise, observei que todos os clientes da base atendiam a esse critério, o que significa que, neste caso específico, o filtro não atuou como fator de diferenciação, mas foi mantido para garantir aderência à regra proposta.



Por fim, para garantir que a contagem de itens refletisse apenas os Top 10 clientes, utilizei uma abordagem em etapas com CTEs. Primeiro, identifiquei os 10 clientes com maior ticket médio. Em seguida, utilizei esse subconjunto como filtro sobre a base original, garantindo que a soma da quantidade de itens (SUM(qtd)) por categoria considerasse exclusivamente o histórico desses clientes, sem interferência dos demais.



***Questão 6.1***



Código:



\-- Criando tabela calendário



CREATE TABLE calendario AS

SELECT

&#x20;   CAST(TO\_CHAR(datum, 'YYYYMMDD') AS INTEGER) AS date\_id,

&#x20;   datum::DATE AS date,



&#x20;   EXTRACT(DAY FROM datum) AS day,

&#x20;   EXTRACT(MONTH FROM datum) AS month,



&#x20;   CASE EXTRACT(MONTH FROM datum)

&#x20;       WHEN 1 THEN 'Janeiro'

&#x20;       WHEN 2 THEN 'Fevereiro'

&#x20;       WHEN 3 THEN 'Março'

&#x20;       WHEN 4 THEN 'Abril'

&#x20;       WHEN 5 THEN 'Maio'

&#x20;       WHEN 6 THEN 'Junho'

&#x20;       WHEN 7 THEN 'Julho'

&#x20;       WHEN 8 THEN 'Agosto'

&#x20;       WHEN 9 THEN 'Setembro'

&#x20;       WHEN 10 THEN 'Outubro'

&#x20;       WHEN 11 THEN 'Novembro'

&#x20;       WHEN 12 THEN 'Dezembro'

&#x20;   END AS month\_name,



&#x20;   EXTRACT(YEAR FROM datum) AS year,

&#x20;   EXTRACT(QUARTER FROM datum) AS quarter,



&#x20;   EXTRACT(DOW FROM datum) AS day\_of\_week,



&#x20;   CASE EXTRACT(DOW FROM datum)

&#x20;       WHEN 0 THEN 'Domingo'

&#x20;       WHEN 1 THEN 'Segunda-feira'

&#x20;       WHEN 2 THEN 'Terça-feira'

&#x20;       WHEN 3 THEN 'Quarta-feira'

&#x20;       WHEN 4 THEN 'Quinta-feira'

&#x20;       WHEN 5 THEN 'Sexta-feira'

&#x20;       WHEN 6 THEN 'Sábado'

&#x20;   END AS day\_name,



&#x20;   CASE 

&#x20;       WHEN EXTRACT(DOW FROM datum) IN (0, 6) THEN TRUE

&#x20;       ELSE FALSE

&#x20;   END AS is\_weekend



FROM generate\_series(

&#x20;   '2023-01-01'::date,

&#x20;   '2024-12-31'::date,

&#x20;   '1 day'::interval

) AS datum;



\-- Validando



SELECT \* FROM calendario LIMIT 25



\-- Preenchendo os dias vazios na tabela de vendas com 0s



SELECT

&#x20;   d.date,

&#x20;   d.day\_name,

&#x20;   v.venda\_dia,

&#x20;   COALESCE(v.venda\_dia, 0) AS venda\_dia\_ajustada

FROM calendario d

LEFT JOIN (

&#x20;   SELECT

&#x20;       sale\_date,

&#x20;       SUM(total) AS venda\_dia

&#x20;   FROM vendas\_cleaned

&#x20;   GROUP BY sale\_date

) v

&#x20;   ON d.date = v.sale\_date

WHERE v.venda\_dia IS NULL

ORDER BY d.date;



\-- Calculando a média de vendas por dia, já com o controle de contar os dias sem vendas



WITH vendas\_por\_dia AS (

&#x20;   SELECT

&#x20;       sale\_date,

&#x20;       SUM(total) AS venda\_dia

&#x20;   FROM vendas\_cleaned

&#x20;   GROUP BY sale\_date

)



, base AS (

&#x20;   SELECT

&#x20;       d.date,

&#x20;       d.day\_name,

&#x20;       COALESCE(v.venda\_dia, 0) AS venda\_dia

&#x20;   FROM calendario d

&#x20;   LEFT JOIN vendas\_por\_dia v

&#x20;       ON d.date = v.sale\_date

)



SELECT

&#x20;   day\_name,

&#x20;   ROUND(AVG(venda\_dia)::numeric, 2) AS media\_vendas

FROM base

GROUP BY day\_name

ORDER BY media\_vendas ASC;





\-- Checando a consulta sem o controle por dias faltantes, simulando o erro do estagiário



SELECT

&#x20;   CASE EXTRACT(DOW FROM sale\_date)

&#x20;       WHEN 0 THEN 'Domingo'

&#x20;       WHEN 1 THEN 'Segunda-feira'

&#x20;       WHEN 2 THEN 'Terça-feira'

&#x20;       WHEN 3 THEN 'Quarta-feira'

&#x20;       WHEN 4 THEN 'Quinta-feira'

&#x20;       WHEN 5 THEN 'Sexta-feira'

&#x20;       WHEN 6 THEN 'Sábado'

&#x20;   END AS day\_name,

&#x20;   

&#x20;   ROUND(AVG(venda\_dia)::numeric, 2) AS media\_vendas



FROM (

&#x20;   SELECT

&#x20;       sale\_date,

&#x20;       SUM(total) AS venda\_dia

&#x20;   FROM vendas\_cleaned

&#x20;   GROUP BY sale\_date

) t



GROUP BY day\_name

ORDER BY media\_vendas ASC;







***Questão 6.2***



Domingo — R$ 3.319.503,55



***Questão 6.3***



1 - Por que utilizar uma tabela de datas?



A tabela de vendas registra apenas os dias em que houve transações. Dias em que a loja operou normalmente mas não registrou nenhuma venda simplesmente não existem nessa tabela, e um GROUP BY direto sobre ela ignora esses dias silenciosamente.

A dimensão de calendário resolve isso ao garantir que todos os dias do período estejam representados, independentemente de ter havido venda ou não. O cruzamento via LEFT JOIN preserva essas datas, e os dias sem venda recebem valor zero, passando a ser considerados no cálculo da média como deveriam.



2\. O impacto dos dias sem venda na média



Se um determinado dia da semana concentrar muitos dias sem venda, a média calculada diretamente pela tabela de vendas ficará artificialmente inflada, já que o divisor será menor do que deveria. No limite, um dia da semana com poucas vendas registradas, mas valores altos nestes poucos dias, poderia aparecer com média superior a dias muito mais movimentados, levando a conclusões equivocadas.

No dataset analisado, o impacto foi pequeno: apenas 6 dias sem registro no período completo, distribuídos entre Domingo, Segunda e Terça. Mas em cenários com sazonalidade mais acentuada ou períodos de inatividade essa diferença poderia ser significativa o suficiente para comprometer uma decisão de negócio.





***Questão 7.1***



Jupyter Notebook - Lighthouse\_Questao7 em anexo



***Questão 7.2***



0 unidades



***Questão 7.3***



O baseline foi construído utilizando uma média móvel simples de 7 dias sobre a série diária de vendas do produto. Inicialmente, os dados foram agregados por dia (incluindo dias sem venda como zero), e o modelo foi treinado com dados até 31/12/2023. Para o período de teste (janeiro de 2024), a previsão foi feita de forma sequencial, utilizando sempre a média dos 7 dias anteriores.



O data leakage foi evitado ao garantir que, para cada previsão, apenas informações disponíveis até o dia anterior fossem utilizadas. Ou seja, em nenhum momento o valor real do próprio dia previsto foi incluído no cálculo da média.



Uma limitação importante do modelo é sua baixa capacidade de lidar com demanda intermitente. Como o produto apresenta longos períodos sem vendas, a média móvel tende a convergir para zero, especialmente após sequências recentes sem transações. Isso faz com que o modelo não apenas falhe em antecipar picos de demanda, mas também subestime sistematicamente períodos em que há vendas relevantes. O MAE de 0.99 unidades por dia, num produto que vende em média menos de 1 unidade diária, e o fato dele ter gerado previsões nulas para a primeira semana evindeciam que o modelo não captura bem a dinâmica do produto.



***Questão 8.1***



Jupyter Notebook - Lighthouse\_Questao8 em anexo





***Questão 8.2***



id = 94 (Motor de Popa Volvo Magnum 276HP)



***Questão 8.3***



A matriz foi construída no formato usuário × produto, onde cada linha representa um cliente (id\_cliente) e cada coluna um produto (id\_produto). O valor da célula é binário: 1 quando o cliente realizou ao menos uma compra do produto e 0 caso contrário. Para o cálculo da similaridade entre produtos, essa matriz foi transposta, permitindo que cada produto fosse representado como um vetor baseado nos clientes que o compraram.



A similaridade de cosseno, nesse contexto, mede o grau de semelhança entre dois produtos com base no padrão de compra dos clientes. Quanto maior a similaridade, maior a proporção de clientes em comum que compraram ambos os itens, indicando que esses produtos tendem a ser consumidos conjuntamente.



Uma limitação desse método é que ele considera apenas a presença ou ausência de compra, ignorando fatores como quantidade adquirida, frequência ou contexto temporal. Além disso, não diferencia compras ocasionais de padrões consistentes, podendo gerar recomendações menos precisas em cenários com comportamento de consumo mais complexo. Além disso, o modelo apresenta o problema de cold start: produtos novos ou com poucas transações tendem a gerar vetores muito esparsos, resultando em similaridades artificialmente baixas ou até nulas, independentemente do seu real potencial de complementaridade. Essa limitação se torna ainda mais relevante neste caso, já que a base conta com apenas 49 clientes. Com um volume de dados reduzido, a similaridade calculada pode ser instável, e a entrada de novos clientes ou produtos pode alterar significativamente o ranking de recomendações.













