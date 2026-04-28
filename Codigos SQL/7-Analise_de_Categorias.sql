WITH base AS (
 SELECT f_apolice.apolice_id
      , f_apolice.forma_pagamento
      , f_apolice.status
      , f_apolice.receita_total
      , f_apolice.receita_esperada
      , (f_apolice.receita_esperada - f_apolice.receita_total) AS receita_perdida
      , CASE 
            WHEN f_apolice.status = 'Cancelada' AND f_apolice.motivo_cancelamento NOT IN ("Falecimento do segurado", "Venda do bem segurado") THEN 1 ELSE 0 
        END AS flag_churn
      , d_produto.nome_produto
      , d_canal.nome_canal
      , d_cliente.faixa_etaria
      , d_cliente.tipo_cliente
      , d_cliente.tempo_cliente_meses
      , d_regiao.regiao
   FROM f_apolice
   LEFT JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
   LEFT JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
   LEFT JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
   LEFT JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
),
scorecard AS (
-- PRODUTO
 SELECT 'Produto' AS dimensao
      , nome_produto AS segmento
      , COUNT(*) AS total_apolices
      , SUM(flag_churn) AS total_canceladas
      , SUM(receita_perdida) AS receita_perdida
   FROM base
  GROUP BY nome_produto
    UNION ALL
-- CANAL
 SELECT 'Canal'
      , nome_canal
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY nome_canal
    UNION ALL
-- REGIÃO
 SELECT 'Regiao'
      , regiao
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY regiao
    UNION ALL
-- PAGAMENTO
 SELECT 'Forma Pagamento'
      , forma_pagamento
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY forma_pagamento
    UNION ALL
-- FAIXA ETÁRIA
 SELECT 'Faixa Etaria'
      , faixa_etaria
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY faixa_etaria
    UNION ALL
-- TIPO CLIENTE
 SELECT 'Tipo Cliente'
      , tipo_cliente
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY tipo_cliente
    UNION ALL
-- TEMPO DE CLIENTE (FAIXAS)
 SELECT 'Tempo Cliente'
      , CASE
            WHEN tempo_cliente_meses < 6 THEN '<6 meses'
            WHEN tempo_cliente_meses BETWEEN 6 AND 12 THEN '6-12 meses'
            ELSE '>12 meses'
        END
      , COUNT(*)
      , SUM(flag_churn)
      , SUM(receita_perdida)
   FROM base
  GROUP BY 2
)
 SELECT dimensao
      , segmento
      , total_apolices
      , total_canceladas
      , ROUND(100.0 * total_canceladas / total_apolices, 2) AS taxa_churn
      , receita_perdida
      , ROUND(100.0 * receita_perdida / SUM(receita_perdida) OVER (), 2) AS perc_perda_total
-- SCORE SIMPLES (pode ajustar depois)
      , ROUND(
            (100.0 * total_canceladas / total_apolices) * 0.4 +
            (100.0 * receita_perdida / SUM(receita_perdida) OVER ()) * 0.6
         , 2) AS score_prioridade
FROM scorecard
ORDER BY taxa_churn DESC;