WITH base_filtrada AS (
 SELECT f_apolice.apolice_id
      , f_apolice.cliente_id
      , f_apolice.produto_id
      , f_apolice.canal_id
      , f_apolice.data_inicio
      , f_apolice.vigencia_meses
      , f_apolice.premio_mensal
      , f_apolice.receita_esperada
--       , f_apolice.comissao  // Correlação Linear perfeita, como produto de receita_esperada e comissao_percentual
      , f_apolice.forma_pagamento
-- TARGET
      , CASE 
            WHEN f_apolice.status = 'Cancelada' 
             AND f_apolice.motivo_cancelamento NOT IN ('Falecimento do segurado', 'Venda do bem segurado')
            THEN 1 
            ELSE 0 
        END AS indicador_churn
   FROM f_apolice
  WHERE 1=1
    AND f_apolice.status <> 'Suspensa'
    AND NOT (f_apolice.status = 'Cancelada' AND f_apolice.motivo_cancelamento IN ('Falecimento do segurado', 'Venda do bem segurado'))
    AND (
            f_apolice.data_cancelamento IS NULL 
         OR TRIM(f_apolice.data_cancelamento) = ''
         OR f_apolice.data_cancelamento >= f_apolice.data_inicio
        )
    AND f_apolice.data_inicio < '2024-10-01'
),
base_enriquecida AS (
 SELECT base_filtrada.apolice_id
      , base_filtrada.cliente_id
      , base_filtrada.produto_id
      , base_filtrada.canal_id
      , base_filtrada.data_inicio
      , base_filtrada.indicador_churn
-- NUMÉRICAS
      , d_cliente.tempo_cliente_meses
      , base_filtrada.premio_mensal
      , base_filtrada.vigencia_meses
      , base_filtrada.receita_esperada
--       , base_filtrada.comissao  // Correlação Linear perfeita, como produto de receita_esperada e comissao_percentual
-- PRODUTO
      , d_produto.ramo
      , d_produto.cobertura
      , d_produto.premio_medio_mensal
      , d_produto.franquia_media
      , base_filtrada.premio_mensal / NULLIF(d_produto.premio_medio_mensal, 0) AS premio_relativo
-- CANAL
      , d_canal.nome_canal
      , d_canal.tipo AS tipo_canal
-- CLIENTE
      , d_cliente.tipo_cliente
      , CASE 
            WHEN d_cliente.tipo_cliente = 'Pessoa Juridica' THEN 'Nao Aplicavel'
            ELSE d_cliente.genero
        END AS genero
      , d_cliente.faixa_etaria
      , d_regiao.regiao
-- TEMPORAL
      , CAST(strftime('%m', base_filtrada.data_inicio) AS INTEGER) AS mes_inicio
      , CAST((CAST(strftime('%m', base_filtrada.data_inicio) AS INTEGER) - 1) / 3 + 1 AS INTEGER) AS trimestre_inicio
   FROM base_filtrada
   JOIN d_produto ON base_filtrada.produto_id = d_produto.produto_id
   JOIN d_canal ON base_filtrada.canal_id = d_canal.canal_id
   JOIN d_cliente ON base_filtrada.cliente_id = d_cliente.cliente_id
   LEFT JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
),
portfolio AS (
 SELECT base_enriquecida.apolice_id
-- QTD APÓLICES (OK com window)
      , COUNT(*) OVER (
            PARTITION BY base_enriquecida.cliente_id 
            ORDER BY base_enriquecida.data_inicio
        ) AS qtd_apolices_cliente
-- QTD RAMOS (correção sem window DISTINCT)
      , (
            SELECT COUNT(DISTINCT d_produto_sub.ramo)
              FROM f_apolice AS f_apolice_sub
              JOIN d_produto AS d_produto_sub ON f_apolice_sub.produto_id = d_produto_sub.produto_id
             WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
               AND f_apolice_sub.data_inicio <= base_enriquecida.data_inicio
        ) AS qtd_ramos_cliente
-- QTD COBERTURAS
      , (
            SELECT COUNT(DISTINCT d_produto_sub.cobertura)
              FROM f_apolice AS f_apolice_sub
              JOIN d_produto AS d_produto_sub ON f_apolice_sub.produto_id = d_produto_sub.produto_id
             WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
               AND f_apolice_sub.data_inicio <= base_enriquecida.data_inicio
        ) AS qtd_coberturas_cliente
-- FLAGS
      , (
            SELECT MAX(CASE WHEN d_produto_sub.ramo = 'Auto' THEN 1 ELSE 0 END)
              FROM f_apolice AS f_apolice_sub
              JOIN d_produto AS d_produto_sub ON f_apolice_sub.produto_id = d_produto_sub.produto_id
             WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
        ) AS tem_auto
      , (
            SELECT MAX(CASE WHEN d_produto_sub.ramo = 'Vida' THEN 1 ELSE 0 END)
              FROM f_apolice AS f_apolice_sub
              JOIN d_produto AS d_produto_sub ON f_apolice_sub.produto_id = d_produto_sub.produto_id
             WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
        ) AS tem_vida
      , (
            SELECT MAX(CASE WHEN d_produto_sub.ramo = 'Residencial' THEN 1 ELSE 0 END)
              FROM f_apolice AS f_apolice_sub
              JOIN d_produto AS d_produto_sub ON f_apolice_sub.produto_id = d_produto_sub.produto_id
             WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
        ) AS tem_residencial
      , CASE 
            WHEN (
                SELECT COUNT(*) 
                  FROM f_apolice AS f_apolice_sub
                 WHERE f_apolice_sub.cliente_id = base_enriquecida.cliente_id
            ) >= 2 THEN 1
            ELSE 0
        END AS tem_cross_sell
   FROM base_enriquecida
)
SELECT base_enriquecida.*
      , portfolio.qtd_apolices_cliente
      , portfolio.qtd_ramos_cliente
      , portfolio.qtd_coberturas_cliente
      , portfolio.tem_auto
      , portfolio.tem_vida
      , portfolio.tem_residencial
      , portfolio.tem_cross_sell
  FROM base_enriquecida
  LEFT JOIN portfolio ON base_enriquecida.apolice_id = portfolio.apolice_id;