# README — Camada Semântica de Vendas

# Visão Geral

Este projeto implementa uma **camada semântica de dados de vendas a nível SKU**, projetada para:

* Consumo para self-BI
* Integração com IA
* Padronização de métricas de negócio

---

# Arquitetura de Dados

A tabela semântica é particionada, clusterizada e contém limpeza nas principais dimensões, além de separar as granularidades de tempo (dia, mês, ano, semana, hora). Pensado nas responsabilidades entre transformação, modelagem e consumo.

# Camada Base (Raw)

* Dados brutos provenientes dos sistemas de origem
* Sem tratamento semântico
* Pode conter inconsistências

---

# Camada Semântica — (`tb_vendas_semantica`)

Granularidade: **1 linha por pedido e SKU vendidos**

Contém:

* Dimensões limpas (id_pedido, id_sku, id_sku_pai, marca, submarca, categoria)
* Dimensões enriquecidas (tempo, produto, cliente, marketing)
* Flags operacionais
* Métricas bases (receita, quantidade, desconto)
* Estrutura preparada para consumo por IA

---

# Modelagem Semântica

A modelagem foi estruturada em quatro pilares:

# 1. Dimensões

Representam o contexto analítico:

* Tempo (ano, mês, semana, dia, hora)
* Produto (marca, categoria, submarca)
* Cliente
* Marketing (origem, mídia)
* Geografia (UF, cidade, região)

---

# 2. Métricas Bases

Podem ser somadas em qualquer nível:

* `receita_liquida`
* `receita_bruta`
* `valor_desconto`
* `quantidade_item`

---

# 3. Métricas Calculadas

Calculadas dinamicamente para garantir consistência:

Exemplos:

* Ticket médio
* Taxas (%)
* Share
* Itens por pedido

Essas métricas evitam erros como:

* média de média
* soma de percentuais

---

# 4. Time Intelligence

Permite análises temporais:

* Comparação com ano anterior (LY)
* Crescimento percentual
* Análises por semana, mês e dia

---

# Princípios de Modelagem

# 1. Separação de responsabilidades

* SQL → dados estruturados e performance
* YAML → regras de negócio e semântica

---

# 2. Métricas calculadas NÃO devem estar no SQL

* definir como métrica derivada no YAML

---

# 3. Preparação para IA

O modelo foi projetado para permitir que sistemas de IA:

* interpretem perguntas em linguagem natural
* utilizem sinônimos (ex: faturamento = receita)
* gerem queries automaticamente
* retornem respostas consistentes
* não respondam se não souberem a resposta
* pensem nos porquês

---

# Exemplos de Perguntas Suportadas

* Qual foi o faturamento ontem vs o mesmo dia do ano passado?
* Qual categoria tem o maior ticket médio?
* Quem são os clientes que mais compraram no último mês?
* Qual região performa melhor?
* Qual período do dia possui mais vendas?

---

# Limitações Atuais

O modelo ainda não contempla:

* Custos de mídia (ROI completo)
* Dados de funil (visitas, sessões, conversão)
* Estoque / ruptura
* Margem e lucro (CMV)
* Tráfegos de buscadores de IA
---

# Roadmap de Evolução

Camadas futuras recomendadas:

* Tabela de custos de marketing → ROI e CAC
* Tabela de estoque → disponibilidade e ruptura

---

# Guia de Uso

# Para Self-BI

* Utilizar métricas definidas na camada semântica
* Evitar recriação de KPIs
* Preferir `pedidos` ao invés de `COUNT DISTINCT`

---

# Para IA

Exemplo de pergunta:

> "Qual o ticket médio por categoria no último mês?"

A IA irá:

1. Identificar a métrica correta (`ticket_medio_pedido`)
2. Aplicar filtro temporal
3. Agrupar por categoria

---

# Para Analistas

* Sempre utilizar métricas derivadas para taxas e médias
* Evitar cálculos manuais em dashboards
* Confiar na camada semântica como fonte única de verdade

---

# Conclusão

Essa tabela transforma os dados brutos da raw em um **produto de dados confiável, escalável e preparado para IA utilizar**, garantindo consistência analítica e reduzindo esforço operacional.
