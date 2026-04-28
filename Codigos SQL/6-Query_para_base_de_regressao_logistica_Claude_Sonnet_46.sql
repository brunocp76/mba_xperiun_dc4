-- =========================================================================
-- Base de Modelagem — Regressão Logística de Churn
-- Seguradora Xperiun · Data Challenge 4
-- Unidade de análise: APÓLICE
-- Erros-padrão serão clusterizados por cliente_id no Python.
-- =========================================================================

-- Etapa A: Universo base com variável resposta e filtros
WITH universo AS (
 SELECT f_apolice.apolice_id
      , f_apolice.cliente_id
      , f_apolice.produto_id
      , f_apolice.canal_id
      , f_apolice.data_inicio
      , f_apolice.vigencia_meses
      , f_apolice.premio_mensal
      , f_apolice.receita_esperada
      , f_apolice.comissao
      , f_apolice.forma_pagamento
      -- Variável resposta: churn GERENCIÁVEL
      , CASE
            WHEN f_apolice.status = 'Cancelada'
             AND f_apolice.motivo_cancelamento NOT IN (
                 'Falecimento do segurado'
                ,'Venda do bem segurado'
             )
            THEN 1
            ELSE 0
        END AS indicador_churn
   FROM f_apolice
  WHERE f_apolice.status != 'Suspensa'
    -- Exclui cancelamentos estruturais do conjunto
    AND NOT (
            f_apolice.status = 'Cancelada'
        AND f_apolice.motivo_cancelamento IN (
            'Falecimento do segurado'
           ,'Venda do bem segurado'
        )
    )
    -- Exclui datas inconsistentes
    AND (
            f_apolice.data_cancelamento IS NULL
         OR TRIM(f_apolice.data_cancelamento) = ''
         OR f_apolice.data_cancelamento >= f_apolice.data_inicio
    )
    -- Exclui apólices muito recentes (exposição insuficiente)
    AND f_apolice.data_inicio < '2024-10-01'
)
-- Etapa B: Portfólio cronológico por cliente
-- Conta TODAS as apólices do cliente com data_inicio < data da apólice atual.
-- Inclui suspensas, falecimentos, venda do bem — pois representavam
-- o histórico real do cliente no momento da emissão.
, portfolio_historico AS (
 SELECT universo.apolice_id
      , universo.cliente_id
      , universo.data_inicio
      -- Quantidade de apólices anteriores (histórico completo)
      , (
            SELECT COUNT(f_apolice.apolice_id)
              FROM f_apolice
             WHERE f_apolice.cliente_id   = universo.cliente_id
               AND f_apolice.data_inicio  < universo.data_inicio
        ) AS qtd_apolices_anteriores
      -- Ramos distintos em apólices anteriores
      , (
            SELECT COUNT(DISTINCT d_produto.ramo)
              FROM f_apolice
              JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
             WHERE f_apolice.cliente_id  = universo.cliente_id
               AND f_apolice.data_inicio < universo.data_inicio
        ) AS qtd_ramos_anteriores
      -- Coberturas distintas em apólices anteriores
      , (
            SELECT COUNT(DISTINCT d_produto.cobertura)
              FROM f_apolice
              JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
             WHERE f_apolice.cliente_id  = universo.cliente_id
               AND f_apolice.data_inicio < universo.data_inicio
        ) AS qtd_coberturas_anteriores
      -- Dummy: já tinha apólice de Automóvel antes desta
      , (
            SELECT COUNT(f_apolice.apolice_id)
              FROM f_apolice
              JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
             WHERE f_apolice.cliente_id  = universo.cliente_id
               AND f_apolice.data_inicio < universo.data_inicio
               AND d_produto.ramo        = 'Automóvel'
        ) > 0 AS tinha_auto
      -- Dummy: já tinha apólice de Vida antes desta
      , (
            SELECT COUNT(f_apolice.apolice_id)
              FROM f_apolice
              JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
             WHERE f_apolice.cliente_id  = universo.cliente_id
               AND f_apolice.data_inicio < universo.data_inicio
               AND d_produto.ramo        = 'Vida'
        ) > 0 AS tinha_vida
      -- Dummy: já tinha apólice Residencial antes desta
      , (
            SELECT COUNT(f_apolice.apolice_id)
              FROM f_apolice
              JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
             WHERE f_apolice.cliente_id  = universo.cliente_id
               AND f_apolice.data_inicio < universo.data_inicio
               AND d_produto.ramo        = 'Residencial'
        ) > 0 AS tinha_residencial
   FROM universo
)
-- Query principal
 SELECT universo.apolice_id
      , universo.cliente_id
      -- === VARIÁVEL RESPOSTA ===
      , universo.indicador_churn
      -- === FEATURES DA APÓLICE ===
      , universo.vigencia_meses
      , universo.premio_mensal
      , universo.receita_esperada
      , universo.comissao
      , universo.forma_pagamento
      -- Sazonalidade: mês e trimestre de início
      , CAST(strftime('%m', universo.data_inicio) AS INTEGER) AS mes_inicio
      , CASE
            WHEN CAST(strftime('%m', universo.data_inicio) AS INTEGER) <= 3  THEN 1
            WHEN CAST(strftime('%m', universo.data_inicio) AS INTEGER) <= 6  THEN 2
            WHEN CAST(strftime('%m', universo.data_inicio) AS INTEGER) <= 9  THEN 3
            ELSE 4
        END AS trimestre_inicio
      -- === FEATURES DO CLIENTE ===
      , d_cliente.tipo_cliente
      -- Gênero: 'Não Aplicável' para Pessoa Jurídica (PJ não tem gênero)
      , CASE
            WHEN d_cliente.tipo_cliente = 'Pessoa Jurídica' THEN 'Não Aplicável'
            ELSE d_cliente.genero
        END AS genero
      , d_cliente.tempo_cliente_meses
      , CASE
            WHEN d_cliente.faixa_etaria = '18-25' THEN '1) 18-25'
            WHEN d_cliente.faixa_etaria = '26-35' THEN '2) 26-35'
            WHEN d_cliente.faixa_etaria = '36-45' THEN '3) 36-45'
            WHEN d_cliente.faixa_etaria = '46-55' THEN '4) 46-55'
            WHEN d_cliente.faixa_etaria = '56-65' THEN '5) 56-65'
            ELSE '6) 65+'
        END AS faixa_etaria
      , CASE
            WHEN d_cliente.tempo_cliente_meses <= 12                         THEN '1) 0-12 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 13 AND 48             THEN '2) 13-48 meses'
            ELSE '3) >48 meses'
        END AS faixa_tempo_casa
      -- === FEATURES GEOGRÁFICAS ===
      , d_regiao.regiao
      -- === FEATURES DO PRODUTO ===
      , d_produto.ramo
      , d_produto.cobertura
      , d_produto.premio_medio_mensal
      , d_produto.franquia_media
      -- Razão: prêmio do cliente vs. prêmio médio do produto
      , ROUND(universo.premio_mensal / NULLIF(d_produto.premio_medio_mensal, 0), 4) AS ratio_premio
      -- === FEATURES DO CANAL ===
      , d_canal.tipo                         AS tipo_canal
      , d_canal.nome_canal
      , d_canal.comissao_percentual / 100.0  AS comissao_percentual
      -- === PORTFÓLIO CRONOLÓGICO DO CLIENTE ===
      , portfolio_historico.qtd_apolices_anteriores
      , portfolio_historico.qtd_ramos_anteriores
      , portfolio_historico.qtd_coberturas_anteriores
      , CAST(portfolio_historico.tinha_auto        AS INTEGER) AS tinha_auto
      , CAST(portfolio_historico.tinha_vida        AS INTEGER) AS tinha_vida
      , CAST(portfolio_historico.tinha_residencial AS INTEGER) AS tinha_residencial
      -- Cross-sell: cliente já tinha apólice de pelo menos 2 ramos distintos
      , CASE
            WHEN portfolio_historico.qtd_ramos_anteriores >= 2 THEN 1
            ELSE 0
        END AS tinha_cross_sell
   FROM universo
   JOIN d_cliente          ON universo.cliente_id  = d_cliente.cliente_id
   JOIN d_regiao           ON d_cliente.regiao_id  = d_regiao.regiao_id
   JOIN d_produto          ON universo.produto_id  = d_produto.produto_id
   JOIN d_canal            ON universo.canal_id    = d_canal.canal_id
   JOIN portfolio_historico ON universo.apolice_id = portfolio_historico.apolice_id
  ORDER BY universo.apolice_id;