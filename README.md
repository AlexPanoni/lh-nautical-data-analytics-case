# LH Nautical — Projeto de Dados e Business Intelligence

Projeto desenvolvido como parte do processo seletivo do programa Lighthouse (Dados e IA), com foco na construção de uma solução completa de dados — desde a ingestão e modelagem até a geração de insights estratégicos.

---

## Contexto do Desafio

A LH Nautical é uma empresa de varejo de peças e acessórios para embarcações, com operação híbrida (loja física + e-commerce).

A empresa enfrenta um cenário de **“caos de dados”**, caracterizado por:

- Dados desorganizados e não padronizados  
- Sistemas desconectados (e-commerce e financeiro)  
- Dificuldade em consolidar informações básicas  
- Tomada de decisão baseada em intuição  

A diretoria busca evoluir para uma operação orientada por dados, com potencial uso de IA — mas atualmente não possui base estruturada para isso.

---

## Objetivo do Projeto

Atuar como o profissional de dados responsável por:

> Estruturar, organizar e transformar dados brutos em informações confiáveis, capazes de gerar valor real para o negócio.

---

## Abordagem

O projeto por mim desenvolvido seguiu uma abordagem **end-to-end**, cobrindo toda a jornada de dados:

1. Engenharia de Dados  
2. Modelagem e estruturação  
3. Análise exploratória (EDA)  
4. Geração de insights  
5. Construção de dashboard  

Com foco em:
- Clareza de raciocínio  
- Organização  
- Aplicabilidade de negócio  

---

## Engenharia de Dados

Foi construído um **Data Warehouse** utilizando o modelo Medallion:

- **Bronze** → Ingestão de dados brutos  
- **Silver** → Limpeza, padronização e validação  
- **Gold** → Modelo analítico (star schema)  

### Ao final do pipeline, temos prontas para consumo as tabelas:
- Vendas (`fact_sales`)
- Custos (`fact_costs`)
- Clientes (`dim_customer`)
- Produtos (`dim_product`)
- Datas (`dim_date`)
- Câmbio (`dim_exchange_rate`)

---

## Tratamento e Regras de Negócio

Para viabilizar a análise de lucratividade:

- Associação de custo histórico por produto (último custo válido antes da venda)  
- Conversão de moeda (USD → BRL)  
- Cálculo de custo por transação  
- Cálculo de lucro por venda  

Essas regras foram fundamentais para transformar dados brutos em métricas confiáveis.

---

## Análise Exploratória (EDA)

A análise identificou padrões relevantes:

- Receita estável ao longo do tempo  
- Queda significativa na margem e no lucro em 2024  
- Forte relação inversa entre câmbio e margem  
- Produtos de alto valor concentram prejuízo  
- **~85% dos produtos apresentam margem negativa**  
- Receita distribuída (sem forte concentração)  
- Base de clientes diversificada  

---

## Análise de Negócio

### Produtos
- Prejuízo muito mais impactado por categoria específica (Propulsão)  
- Grande parte do portfólio opera com margem negativa  

### Clientes
- Nenhum cliente se destaca como principal gerador de lucro  
- O prejuízo é distribuído pela base  

---

## Insight Principal

> O problema central não está na demanda ou nos clientes, mas em uma **ineficiência estrutural de margem**.

Principais drivers:
- Custos elevados e impactados pelo câmbio 
- Precificação inadequada  
- Mix de produtos pouco eficiente  

---

## Dashboard (Power BI)

Foi desenvolvido um dashboard com foco em comunicação clara para stakeholders. O link público para visualizá-lo é: [Dashboard](eyJrIjoiYTRmYzg5MTQtZTNhMi00NTMyLWIxZmItZjRlYzNkMGVhZDY5IiwidCI6ImEzNGM1MTliLTQ0ZDEtNGRlNi1iNTVlLWQ0NmNmZWFhODJhNSJ9)



### 1. Visão Geral do Desempenho
- Receita, Lucro, Margem e Custos  
- Análise temporal  
- Relação entre câmbio e rentabilidade  

### 2. Análise de Produtos e Clientes
- Receita por cliente e produto  
- Prejuízo por produto  
- Margem por categoria  
- Indicadores estruturais do problema  

### Diferenciais:
- KPIs dinâmicos  
- Filtros interativos   

---

## Implicações de Negócio

- Necessidade de revisão da estratégia de preços  
- Redução da exposição ao câmbio  
- Reavaliação do portfólio de produtos  
- Foco em rentabilidade, não apenas crescimento  

---

## Respostas ao Questionário do Desafio

Como parte do processo seletivo, o desafio inclui um questionário com perguntas estruturadas que devem ser respondidas com base nas análises realizadas ao longo do projeto.

As respostas foram organizadas de forma clara e documentada na pasta:

📁 `Questoes/`

Nessa pasta, é possível encontrar:

- Arquivos individuais com respostas específicas por questão, o que inclui tanto códigos em SQL quanto em Python  
- Um **Jupyter Notebook consolidado**, contendo todas as respostas agregadas
- Um **arquivo de texto completo**, reunindo todas as respostas de forma contínua e contendo também as respostas das perguntas dissertativas

---

## Ferramentas Utilizadas

- **SQL (PostgreSQL)** → Modelagem e transformação de dados  
- **Python (Pandas, , Matplotlib, Numpy, Seaborn)** → EDA e análise  
- **Power BI** → Visualização e dashboard  
- **DAX** → Cálculo de métricas  

---

## 📁 Estrutura do Projeto

```
├── Projeto Data Warehouse/
├── EDA/
├── Dashboard/
├── Questoes/
└── README.md
```

---

## Materiais Complementares

- Relatórios completos em PDF, tanto da construção do Data Warehouse quanto da Análise Exploratória de Dados, incluindo insights e recomendações acionáveis  
- Dashboard em Power BI (.pbix)  

---

## Considerações Finais

Este projeto foi desenvolvido com foco não apenas em execução técnica, mas principalmente em:

- Organização da solução  
- Clareza na comunicação  
- Conexão entre dados e decisão de negócio  

Alinhado com a premissa do desafio:

> “Mais importante do que o código é a capacidade de explicar e estruturar o raciocínio.”
