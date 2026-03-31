CREATE OR REPLACE PROCEDURE `nome-projeto.nome-dataset.build_tb_semantica_vendas`()
BEGIN


-- =============================================================================================
-- INSTRUÇÕES DE EXECUÇÃO:

-- 1. PARA A PRIMEIRA VEZ (CRIAR A TABELA): 
-- Descomente as linhas da "OPÇÃO 1" até "FIM DA OPÇÃO 1" e o ";" antes do "END;"
-- Comente o "FILTRO PARA MERGE" no final da primeira CTE
-- Comente as linhas do "INÍCIO DA PRIMEIRA PARTE DA OPÇÃO 2" até o "FIM DA PRIMEIRA PARTE DA OPÇÃO 2" no início da query
-- Comente as linhas do "INÍCIO DA SEGUNDA PARTE DA OPÇÃO 2" até a "FIM DA SEGUNDA PARTE DA OPÇÃO 2" no final da query

-- 2. PARA A ROTINA DIÁRIA (ACUMULAR HISTÓRICO): 
-- Comente as linhas da "OPÇÃO 1" até "FIM DA OPÇÃO 1" e o ";" antes do "END;"
-- Descomente o "FILTRO PARA MERGE" no final da primeira CTE
-- Descomente as linhas do "INÍCIO DA PRIMEIRA PARTE DA OPÇÃO 2" até o "FIM DA PRIMEIRA PARTE DA OPÇÃO 2" no início da query
-- Descomente as linhas do "INÍCIO DA SEGUNDA PARTE DA OPÇÃO 2" até a "FIM DA SEGUNDA PARTE DA OPÇÃO 2" no final da query

--  ================ OPÇÃO 1:
  CREATE OR REPLACE TABLE `nome-projeto.nome-dataset.tb_vendas_semantica`
  PARTITION BY data_venda
  CLUSTER BY id_cliente, id_sku, id_pedido
  AS 
--  ================ FIM DA OPÇÃO 1
-- =============================================================================================

--  ================ INÍCIO DA PRIMEIRA PARTE DA OPÇÃO 2

  -- MERGE `nome-projeto.nome-dataset.tb_vendas_semantica` T
  -- USING (

--  ================ FIM DA PRIMEIRA PARTE DA OPÇÃO 2

  WITH

  tb_vendas AS (
    SELECT
    -- Atualização
      CURRENT_DATE() AS dt_atualizacao,

      -- IDs gerais
      LPAD(CAST(REPLACE(cod_pedido,'PED-','') AS STRING), 20, '0') AS id_pedido,
      cpf_hash AS id_cliente,
      LPAD(CAST(REPLACE(cod_material,'SKU-','') AS STRING), 20, '0') AS id_sku,
      LPAD(CAST(REPLACE(cod_material_pai,'PAI-','') AS STRING), 20, '0') AS id_sku_pai,

      -- caracteristicas do produto
      REPLACE(cod_un_negocio, 'UN-', '') AS marca,
      REPLACE(marca_ind, 'MARCA-', '') AS submarca,
      REPLACE(categoria_final_nivel1, 'CAT-', '') AS categoria,

      -- ciclo
      cod_ciclo,
      UPPER(des_ciclo) AS tipo_ciclo,

      -- datas
      DATE(dt_venda) AS data_venda,
      EXTRACT(TIME FROM dt_hora_venda) AS hora_venda,
      CASE
        WHEN EXTRACT(HOUR FROM dt_hora_venda) BETWEEN 0 AND 5 THEN 'MADRUGADA'
        WHEN EXTRACT(HOUR FROM dt_hora_venda) BETWEEN 6 AND 11 THEN 'MANHÃ'
        WHEN EXTRACT(HOUR FROM dt_hora_venda) BETWEEN 12 AND 17 THEN 'TARDE'
        ELSE 'NOITE'
      END AS faixa_horaria,
      EXTRACT(YEAR FROM dt_venda) AS ano_venda,
      EXTRACT(MONTH FROM dt_venda) AS numero_mes,
      FORMAT_DATE('%Y-%m', dt_venda) AS ano_mes,
      CASE EXTRACT(MONTH FROM dt_venda)
        WHEN 1 THEN 'JANEIRO'
        WHEN 2 THEN 'FEVEREIRO'
        WHEN 3 THEN 'MARÇO'
        WHEN 4 THEN 'ABRIL'
        WHEN 5 THEN 'MAIO'
        WHEN 6 THEN 'JUNHO'
        WHEN 7 THEN 'JULHO'
        WHEN 8 THEN 'AGOSTO'
        WHEN 9 THEN 'SETEMBRO'
        WHEN 10 THEN 'OUTUBRO'
        WHEN 11 THEN 'NOVEMBRO'
        WHEN 12 THEN 'DEZEMBRO'
      END AS nome_mes,
      -- semana
      EXTRACT(DAYOFWEEK FROM dt_venda) AS dia_semana_numero,
      FORMAT('%d-W%02d', EXTRACT(ISOYEAR FROM dt_venda), EXTRACT(ISOWEEK FROM dt_venda)) AS ano_semana_formatado,
      EXTRACT(ISOYEAR FROM dt_venda) AS ano_semana,
      EXTRACT(ISOWEEK FROM dt_venda) AS numero_semana,
      EXTRACT(DAYOFWEEK FROM dt_venda) AS dia_numero_semana,
      CASE EXTRACT(DAYOFWEEK FROM dt_venda)
        WHEN 1 THEN 'DOMINGO'
        WHEN 2 THEN 'SEGUNDA-FEIRA'
        WHEN 3 THEN 'TERÇA-FEIRA'
        WHEN 4 THEN 'QUARTA-FEIRA'
        WHEN 5 THEN 'QUINTA-FEIRA'
        WHEN 6 THEN 'SEXTA-FEIRA'
        WHEN 7 THEN 'SÁBADO'
      END AS nome_dia_semana,

      -- marketing
      TRIM(SPLIT(COALESCE(fonte_de_trafego_nivel_1, '0. DESCONHECIDO'), '.')[SAFE_OFFSET(0)]) AS id_origem_trafego,
      UPPER(TRIM(SPLIT(COALESCE(fonte_de_trafego_nivel_1, '0. DESCONHECIDO'), '.')[SAFE_OFFSET(1)])) AS origem_trafego,
      CASE WHEN
        UPPER(fonte_de_trafego_nivel_1) = '2. NÃO PAGOS' AND UPPER(des_midia_canal) = 'GOOGLE' THEN "google_organico"
        ELSE UPPER(COALESCE(des_midia_canal, 'DESCONHECIDO'))
      END AS midia,

      -- localidade
      uf,
      UPPER(des_cidade) AS cidade,
      regiao,

      -- status
      COALESCE(flg_faturada, 0) AS flag_faturada,
      COALESCE(flg_aprovada, 0) AS flag_aprovada,
      COALESCE(flg_pedidos_cd, 0) AS flag_atendido_cd, 
      COALESCE(flg_pedidos_pickup, 0) AS flag_retirada,
      CASE 
        WHEN UPPER(apresentacao_combo) = "COMBO" THEN 1
        ELSE 0 
      END AS flag_combo,
      CASE
        WHEN COALESCE(des_cupom,'SEM_CUPOM') = 'SEM_CUPOM' THEN 0
        ELSE 1
      END AS flag_cupom,

      -- sobre as vendas
      COALESCE(REPLACE(des_cupom,'CUPOM-',''),'SEM_CUPOM') AS cupom,
      TRIM(SPLIT(status_oms, '.')[SAFE_OFFSET(0)]) AS id_status_venda,
      UPPER(TRIM(SPLIT(status_oms, '.')[SAFE_OFFSET(1)])) AS status_venda,
      UPPER(des_canal_venda_final) AS canal_venda,


      -- métricas base
      COALESCE(vlr_receita_faturada, 0) AS receita_liquida,
      COALESCE(vlr_venda_pago, vlr_receita_faturada, 0) AS receita_bruta,
      COALESCE(vlr_venda_desconto, 0) AS valor_desconto,
      1 AS quantidade_item

    FROM `nome-projeto.nome-dataset.tb_vendas_raw`


--  ================ FILTRO PARA MERGE
    -- WHERE
    -- dt_venda >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
  )

  SELECT
  *
  FROM tb_vendas

--  ================ Necessário comentar ou descomentar o ";"" abaixo
  ;

--  ================ INÍCIO DA SEGUNDA PARTE DA OPÇÃO 2

-- ) S

-- ON T.id_pedido = S.id_pedido
--   AND T.id_sku = S.id_sku
--   AND T.id_sku_pai = S.id_sku_pai
--   AND T.data_venda >= DATE_SUB(CURRENT_DATE(), INTERVAL 10 DAY)

--   WHEN MATCHED THEN
--     UPDATE SET
--       dt_atualizacao = S.dt_atualizacao,
--       receita_liquida = S.receita_liquida,
--       receita_bruta = S.receita_bruta,
--       valor_desconto = S.valor_desconto,
--       flag_faturada = S.flag_faturada,
--       flag_aprovada = S.flag_aprovada,
--       status_venda = S.status_venda

--   WHEN NOT MATCHED THEN
--     INSERT ROW;

-- ================ FIM DA SEGUNDA PARTE DA OPÇÃO 2

END;