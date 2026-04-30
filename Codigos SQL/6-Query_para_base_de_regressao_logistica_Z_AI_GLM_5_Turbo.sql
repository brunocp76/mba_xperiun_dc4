------------------------------------------------------------------------------
--> Etapa 1 — Base de Modelagem (Regressão Logística)
------------------------------------------------------------------------------
--> Objetivo: Gerar tabela flat para importação no Python.
--> Unidade de análise: apólice.
--> Observações não independentes: tratadas com erros-padrão clusterizados
-->   por cliente no Python (statsmodels cov_type='cluster').
------------------------------------------------------------------------------
--> Filtros aplicados:
-->   1. Excluir apólices com data_inicio >= 2024-10-01 (baixa exposição)
-->   2. Excluir 4 registros com data_cancelamento < data_inicio (inconsistentes)
-->   3. Excluir apólices Suspensas (pré-cancelamento, não churn consumado)
-->   4. Excluir cancelamentos por Falecimento ou Venda do bem (estruturais)
------------------------------------------------------------------------------
--> Variáveis de leakage EXCLUÍDAS do output:
-->   motivo_cancelamento, data_cancelamento, status, receita_total,
-->   parcelas_pagas, gap_receita, dias_ate_churn, janela_retencao, cac_perdido
------------------------------------------------------------------------------
--> Nota técnica: SQLite não suporta COUNT(DISTINCT) em window functions.
-->   Solução: qtde_ramos_cliente = tem_auto + tem_vida + tem_residencial
-->   (idem para coberturas, com indicadores intermediários internos).
------------------------------------------------------------------------------
--> Autor: Bruno César Pasquini
--> Auxiliar: IA
------------------------------------------------------------------------------


WITH base_com_window AS (
------------------------------------------------------------------------------
--> CTE 1: Variáveis derivadas com window functions CRONOLÓGICAS.
--> As window functions consideram TODAS as apólices do cliente (incluindo
-->   suspensas e cancelamentos estruturais) porque representam a carteira
-->   real do cliente no momento da emissão de cada apólice.
--> Filtros aqui: apenas data_inicio e inconsistência de datas.
------------------------------------------------------------------------------
     SELECT f_apolice.apolice_id
          , f_apolice.cliente_id
          , f_apolice.produto_id
          , f_apolice.canal_id
          , f_apolice.vigencia_meses
          , f_apolice.premio_mensal
--           , f_apolice.comissao  // Correlação Linear perfeita, como produto de receita esperada e comissao_percentual
          , f_apolice.forma_pagamento
          , f_apolice.data_inicio
          , f_apolice.status
          , f_apolice.motivo_cancelamento
------------------------------------------------------------------------------
--> Variável resposta (binária)
------------------------------------------------------------------------------
          , CASE
                WHEN f_apolice.status = 'Cancelada'
                 AND f_apolice.motivo_cancelamento NOT IN (
                      'Falecimento do segurado'
                    , 'Venda do bem segurado'
                 )
                THEN 1
                ELSE 0
            END AS indicador_churn
------------------------------------------------------------------------------
--> Dimensão Cliente — com tratamento de gênero para PJ
------------------------------------------------------------------------------
          , CASE
                WHEN d_cliente.tipo_cliente = 'Pessoa Jurídica' THEN 'Não aplicável'
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
          , CASE
                WHEN d_cliente.tempo_cliente_meses <= 12 THEN '1) 0-12 meses'
                WHEN d_cliente.tempo_cliente_meses BETWEEN 13 AND 48 THEN '2) 13-48 meses'
                ELSE '3) >48 meses'
            END AS faixa_tempo_casa
          , d_cliente.tipo_cliente
------------------------------------------------------------------------------
--> Dimensão Região (desnormalizada de d_cliente + d_regiao)
------------------------------------------------------------------------------
          , d_regiao.regiao
------------------------------------------------------------------------------
--> Dimensão Produto
------------------------------------------------------------------------------
          , d_produto.ramo
          , d_produto.cobertura
          , d_produto.premio_medio_mensal
          , d_produto.franquia_media
------------------------------------------------------------------------------
--> Dimensão Canal
------------------------------------------------------------------------------
          , d_canal.tipo AS tipo_canal
          , d_canal.nome_canal
          , d_canal.comissao_percentual
------------------------------------------------------------------------------
--> Razão prêmio vs média do produto
------------------------------------------------------------------------------
          , CASE
                WHEN d_produto.premio_medio_mensal = 0 THEN NULL
                ELSE ROUND(f_apolice.premio_mensal / NULLIF(d_produto.premio_medio_mensal, 0), 4)
            END AS razao_premio_vs_media
------------------------------------------------------------------------------
--> Variáveis sazonais extraídas de data_inicio
------------------------------------------------------------------------------
          , CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) AS mes_inicio
          , CAST(
                (CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) + 2) / 3
                AS INTEGER
            ) AS trimestre_inicio
------------------------------------------------------------------------------
--> Indicadores binários de RAMO (window functions cronológicas)
--> Cada um indica se o cliente já teve apólice daquele ramo até esta data.
--> A soma dos 3 equivale a COUNT(DISTINCT ramo) — workaround para limitação
-->   do SQLite, que não suporta DISTINCT em window functions.
------------------------------------------------------------------------------
          , MAX(CASE WHEN d_produto.ramo = 'Automóvel' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS tem_auto
          , MAX(CASE WHEN d_produto.ramo = 'Vida' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS tem_vida
          , MAX(CASE WHEN d_produto.ramo = 'Residencial' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS tem_residencial
------------------------------------------------------------------------------
--> Indicadores binários de COBERTURA (window functions cronológicas)
--> Prefixo _ porque são variáveis de uso interno deste CTE.
--> Não vão para o CSV — servem apenas para derivar qtde_coberturas_cliente.
------------------------------------------------------------------------------
          , MAX(CASE WHEN d_produto.cobertura = 'Básica' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS _tem_basica
          , MAX(CASE WHEN d_produto.cobertura = 'Completa' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS _tem_completa
          , MAX(CASE WHEN d_produto.cobertura = 'Premium' THEN 1 ELSE 0 END) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS _tem_premium
------------------------------------------------------------------------------
--> Contagem de apólices por cliente (window function cronológica)
------------------------------------------------------------------------------
          , COUNT(*) OVER (
                PARTITION BY f_apolice.cliente_id
                ORDER BY f_apolice.data_inicio
                ROWS UNBOUNDED PRECEDING
            ) AS qtde_apolices_cliente
       FROM f_apolice
       LEFT JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
       LEFT JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
       LEFT JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
       LEFT JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
------------------------------------------------------------------------------
--> Filtros PRÉ-window: apenas exposição e consistência de dados.
------------------------------------------------------------------------------
      WHERE f_apolice.data_inicio < '2024-10-01'
        AND (
            f_apolice.data_cancelamento IS NULL
            OR f_apolice.data_cancelamento > f_apolice.data_inicio
            OR TRIM(f_apolice.data_cancelamento) = ''
        )
)
------------------------------------------------------------------------------
--> CTE 2: Deriva variáveis que dependem de outras window functions.
--> No SQLite, não é possível referenciar uma window function dentro de
-->   outra expressão na mesma SELECT — por isso este CTE intermediário.
------------------------------------------------------------------------------
, base_cross_sell AS (
     SELECT base_com_window.apolice_id
          , base_com_window.cliente_id
          , base_com_window.produto_id
          , base_com_window.canal_id
          , base_com_window.vigencia_meses
          , base_com_window.premio_mensal
--           , base_com_window.comissao  // Correlação Linear perfeita, como produto de receita esperada e comissao_percentual
          , base_com_window.forma_pagamento
          , base_com_window.data_inicio
          , base_com_window.status
          , base_com_window.motivo_cancelamento
          , base_com_window.indicador_churn
          , base_com_window.genero
          , base_com_window.faixa_etaria
          , base_com_window.tempo_cliente_meses
          , base_com_window.faixa_tempo_casa
          , base_com_window.tipo_cliente
          , base_com_window.regiao
          , base_com_window.ramo
          , base_com_window.cobertura
          , base_com_window.premio_medio_mensal
          , base_com_window.franquia_media
          , base_com_window.tipo_canal
          , base_com_window.nome_canal
          , base_com_window.comissao_percentual
          , base_com_window.razao_premio_vs_media
          , base_com_window.mes_inicio
          , base_com_window.trimestre_inicio
          , base_com_window.qtde_apolices_cliente
------------------------------------------------------------------------------
--> qtde_ramos_cliente = soma dos indicadores de ramo
-->   Equivale a COUNT(DISTINCT ramo) — workaround para limitação do SQLite.
------------------------------------------------------------------------------
          , base_com_window.tem_auto
           + base_com_window.tem_vida
           + base_com_window.tem_residencial AS qtde_ramos_cliente
------------------------------------------------------------------------------
--> qtde_coberturas_cliente = soma dos indicadores de cobertura
-->   Equivale a COUNT(DISTINCT cobertura) — mesmo workaround.
------------------------------------------------------------------------------
          , base_com_window._tem_basica
           + base_com_window._tem_completa
           + base_com_window._tem_premium AS qtde_coberturas_cliente
------------------------------------------------------------------------------
--> Indicadores binários de ramo (seguem para o CSV como preditoras)
------------------------------------------------------------------------------
          , base_com_window.tem_auto
          , base_com_window.tem_vida
          , base_com_window.tem_residencial
------------------------------------------------------------------------------
--> Cross-sell: cliente com mais de 1 ramo na carteira
------------------------------------------------------------------------------
          , CASE
                WHEN (
                    base_com_window.tem_auto
                  + base_com_window.tem_vida
                  + base_com_window.tem_residencial
                ) > 1
                THEN 1
                ELSE 0
            END AS tem_cross_sell
       FROM base_com_window
)
------------------------------------------------------------------------------
--> SELECT FINAL: Aplica filtros de exclusão e seleciona colunas para o CSV.
--> status e motivo_cancelamento são usados apenas no WHERE — não vão pro CSV.
--> As variáveis _tem_basica, _tem_completa, _tem_premium ficam no CTE anterior
-->   e não são selecionadas aqui (variáveis internas de cálculo).
------------------------------------------------------------------------------
SELECT base_cross_sell.apolice_id
     , base_cross_sell.cliente_id
     , base_cross_sell.data_inicio
     , base_cross_sell.indicador_churn
     , base_cross_sell.genero
     , base_cross_sell.faixa_etaria
     , base_cross_sell.tempo_cliente_meses
     , base_cross_sell.faixa_tempo_casa
     , base_cross_sell.tipo_cliente
     , base_cross_sell.regiao
     , base_cross_sell.ramo
     , base_cross_sell.cobertura
     , base_cross_sell.vigencia_meses
     , base_cross_sell.premio_mensal
--      , base_cross_sell.comissao  // Correlação Linear perfeita, como produto de receita esperada e comissao_percentual
     , base_cross_sell.forma_pagamento
     , base_cross_sell.premio_medio_mensal
     , base_cross_sell.franquia_media
     , base_cross_sell.tipo_canal
     , base_cross_sell.nome_canal
     , base_cross_sell.comissao_percentual
     , base_cross_sell.razao_premio_vs_media
     , base_cross_sell.mes_inicio
     , base_cross_sell.trimestre_inicio
     , base_cross_sell.qtde_apolices_cliente
     , base_cross_sell.qtde_ramos_cliente
     , base_cross_sell.qtde_coberturas_cliente
     , base_cross_sell.tem_auto
     , base_cross_sell.tem_vida
     , base_cross_sell.tem_residencial
     , base_cross_sell.tem_cross_sell
  FROM base_cross_sell
 WHERE base_cross_sell.status != 'Suspensa'
   AND NOT (
       base_cross_sell.status = 'Cancelada'
       AND base_cross_sell.motivo_cancelamento IN (
            'Falecimento do segurado'
          , 'Venda do bem segurado'
       )
   )
ORDER BY base_cross_sell.apolice_id;