---------------------------------------------------------------------------
-- BASE DE MODELAGEM — Regressão Logística de Churn
-- Seguradora Xperiun
---------------------------------------------------------------------------
-- Autor:    Bruno Cesar Pasquini (com assistência de IA)
-- Objetivo: Gerar tabela flat para modelo explicativo de churn voluntário
-- Unidade:  Apólice
-- Período:  data_inicio < '2024-10-01'
---------------------------------------------------------------------------
-- FILTROS APLICADOS:
--   1. Exclui status = 'Suspensa'
--   2. Exclui Canceladas por 'Falecimento do segurado'
--      ou 'Venda do bem segurado'
--   3. Exclui data_cancelamento < data_inicio (inconsistências)
--   4. Exclui data_inicio >= '2024-10-01' (exposição insuficiente)
---------------------------------------------------------------------------
-- VARIÁVEIS EXCLUÍDAS (data leakage):
--   status, motivo_cancelamento, data_cancelamento,
--   receita_total, parcelas_pagas, gap_receita,
--   dias_ate_churn, janela_retencao, cac_perdido,
--   taxa_adimplencia
---------------------------------------------------------------------------
-- NOTA SOBRE ALIASES:
--   O padrão deste projeto é indexar por nome da tabela (sem aliases).
--   Exceção: subqueries correlacionadas do Bloco 8 usam aliases
--   ("todas" / "prod") por necessidade técnica — a mesma tabela
--   aparece nos escopos externo e interno.
---------------------------------------------------------------------------
-- RECOMENDAÇÃO DE PERFORMANCE:
--   As subqueries do Bloco 8 serão executadas ~119.500 vezes cada.
--   Criar índices ANTES de rodar esta query:
--
--   CREATE INDEX IF NOT EXISTS idx_apolice_cliente_data
--       ON f_apolice(cliente_id, data_inicio);
--   CREATE INDEX IF NOT EXISTS idx_apolice_produto
--       ON f_apolice(produto_id);
---------------------------------------------------------------------------

SELECT
---------------------------------------------------------------------------
-- BLOCO 1: Identificadores (não entram no modelo, mantidos para rastreio)
---------------------------------------------------------------------------
      f_apolice.apolice_id
    , f_apolice.cliente_id
    , f_apolice.produto_id
    , f_apolice.canal_id
    , f_apolice.data_inicio
---------------------------------------------------------------------------
-- BLOCO 2: Variável resposta
---------------------------------------------------------------------------
    , CASE
          WHEN f_apolice.status = 'Cancelada' THEN 1
          ELSE 0
      END AS indicador_churn
---------------------------------------------------------------------------
-- BLOCO 3: Variáveis do cliente
---------------------------------------------------------------------------
    , d_cliente.tipo_cliente
    , CASE
          WHEN d_cliente.tipo_cliente = 'Pessoa Juridica'
          THEN 'Não Aplicável'
          ELSE d_cliente.genero
      END AS genero
    , CASE
          WHEN d_cliente.faixa_etaria = '18-25' THEN '1) 18-25'
          WHEN d_cliente.faixa_etaria = '26-35' THEN '2) 26-35'
          WHEN d_cliente.faixa_etaria = '36-45' THEN '3) 36-45'
          WHEN d_cliente.faixa_etaria = '46-55' THEN '4) 46-55'
          WHEN d_cliente.faixa_etaria = '56-65' THEN '5) 56-65'
          ELSE '6) 65+'
      END AS faixa_etaria
    , d_cliente.tempo_cliente_meses
    , d_regiao.regiao
---------------------------------------------------------------------------
-- BLOCO 4: Variáveis do produto
---------------------------------------------------------------------------
    , d_produto.ramo
    , d_produto.cobertura
--     , d_produto.premio_medio_mensal
    , d_produto.franquia_media
---------------------------------------------------------------------------
-- BLOCO 5: Variáveis do canal
---------------------------------------------------------------------------
    , d_canal.nome_canal
    , d_canal.tipo AS tipo_canal
    , d_canal.comissao_percentual / 100.0 AS comissao_percentual
---------------------------------------------------------------------------
-- BLOCO 6: Variáveis financeiras da apólice
---------------------------------------------------------------------------
    , f_apolice.vigencia_meses
--     , f_apolice.premio_mensal
--     , f_apolice.comissao
--     , f_apolice.receita_esperada
    , f_apolice.forma_pagamento
    , ROUND(
          f_apolice.premio_mensal
          / NULLIF(d_produto.premio_medio_mensal, 0)
      , 4) AS ratio_premio_vs_medio
---------------------------------------------------------------------------
-- BLOCO 7: Variáveis temporais / sazonais
---------------------------------------------------------------------------
--     , CAST(strftime('%Y', f_apolice.data_inicio) AS INTEGER) AS ano_inicio
    , CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) AS mes_inicio
    , CASE
          WHEN CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) <= 3
          THEN 1
          WHEN CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) <= 6
          THEN 2
          WHEN CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) <= 9
          THEN 3
          ELSE 4
      END AS trimestre_inicio
    , d_calendario.is_fim_semana
    , d_calendario.is_feriado
---------------------------------------------------------------------------
-- BLOCO 8: Variáveis de cross-sell (acumuladas cronologicamente)
---------------------------------------------------------------------------
-- Contagens sobre TODA a base f_apolice (sem filtros),
-- acumuladas até a data_inicio da apólice corrente.
-- Evita leakage temporal: não conta apólices futuras.
---------------------------------------------------------------------------
    , (SELECT COUNT(*)
         FROM f_apolice AS todas
        WHERE todas.cliente_id = f_apolice.cliente_id
          AND todas.data_inicio <= f_apolice.data_inicio
      ) AS qtd_apolices_acumuladas
    , (SELECT COUNT(DISTINCT prod.ramo)
         FROM f_apolice AS todas
        INNER JOIN d_produto AS prod
           ON todas.produto_id = prod.produto_id
        WHERE todas.cliente_id = f_apolice.cliente_id
          AND todas.data_inicio <= f_apolice.data_inicio
      ) AS qtd_ramos_distintos
    , (SELECT COUNT(DISTINCT prod.cobertura)
         FROM f_apolice AS todas
        INNER JOIN d_produto AS prod
           ON todas.produto_id = prod.produto_id
        WHERE todas.cliente_id = f_apolice.cliente_id
          AND todas.data_inicio <= f_apolice.data_inicio
      ) AS qtd_coberturas_distintas
    , CASE
          WHEN (SELECT COUNT(*)
                  FROM f_apolice AS todas
                 INNER JOIN d_produto AS prod
                    ON todas.produto_id = prod.produto_id
                 WHERE todas.cliente_id = f_apolice.cliente_id
                   AND todas.data_inicio <= f_apolice.data_inicio
                   AND prod.ramo = 'Auto'
               ) > 0 THEN 1
          ELSE 0
      END AS tem_auto
    , CASE
          WHEN (SELECT COUNT(*)
                  FROM f_apolice AS todas
                 INNER JOIN d_produto AS prod
                    ON todas.produto_id = prod.produto_id
                 WHERE todas.cliente_id = f_apolice.cliente_id
                   AND todas.data_inicio <= f_apolice.data_inicio
                   AND prod.ramo = 'Vida'
               ) > 0 THEN 1
          ELSE 0
      END AS tem_vida
    , CASE
          WHEN (SELECT COUNT(*)
                  FROM f_apolice AS todas
                 INNER JOIN d_produto AS prod
                    ON todas.produto_id = prod.produto_id
                 WHERE todas.cliente_id = f_apolice.cliente_id
                   AND todas.data_inicio <= f_apolice.data_inicio
                   AND prod.ramo = 'Residencial'
               ) > 0 THEN 1
          ELSE 0
      END AS tem_residencial
    , CASE
          WHEN (SELECT COUNT(DISTINCT prod.ramo)
                  FROM f_apolice AS todas
                 INNER JOIN d_produto AS prod
                    ON todas.produto_id = prod.produto_id
                 WHERE todas.cliente_id = f_apolice.cliente_id
                   AND todas.data_inicio <= f_apolice.data_inicio
               ) > 1 THEN 1
          ELSE 0
      END AS tem_cross_sell
---------------------------------------------------------------------------
-- BLOCO 9: Variáveis para estratificação (não entram no modelo)
---------------------------------------------------------------------------
    , CASE
          WHEN d_cliente.tempo_cliente_meses <= 12 THEN '1) 0-12 meses'
          WHEN d_cliente.tempo_cliente_meses BETWEEN 13 AND 48
          THEN '2) 13-48 meses'
          ELSE '3) >48 meses'
      END AS faixa_tempo_casa
---------------------------------------------------------------------------
-- BLOCO 10: Relação de Tabelas
---------------------------------------------------------------------------
  FROM f_apolice
  LEFT JOIN d_cliente
    ON f_apolice.cliente_id = d_cliente.cliente_id
  LEFT JOIN d_regiao
    ON d_cliente.regiao_id = d_regiao.regiao_id
  LEFT JOIN d_produto
    ON f_apolice.produto_id = d_produto.produto_id
  LEFT JOIN d_canal
    ON f_apolice.canal_id = d_canal.canal_id
  LEFT JOIN d_calendario
    ON f_apolice.data_inicio = d_calendario."data"
---------------------------------------------------------------------------
-- BLOCO 11: FILTROS
---------------------------------------------------------------------------
 WHERE f_apolice.status != 'Suspensa'
   AND NOT (
       f_apolice.status = 'Cancelada'
       AND f_apolice.motivo_cancelamento IN (
           'Falecimento do segurado'
         , 'Venda do bem segurado'
       )
   )
   AND (
       f_apolice.data_cancelamento IS NULL
       OR TRIM(f_apolice.data_cancelamento) = ''
       OR f_apolice.data_cancelamento >= f_apolice.data_inicio
   )
   AND f_apolice.data_inicio < '2024-10-01'
---------------------------------------------------------------------------
-- BLOCO 12: ORDER BY
---------------------------------------------------------------------------
 ORDER BY f_apolice.data_inicio
        , f_apolice.apolice_id
;