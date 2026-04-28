------------------------------------------------------------------------------
--                                                                            
--   ######                                                                   
--   #     #   ##   #    #  ####   ####     #####  ######                     
--   #     #  #  #  ##   # #    # #    #    #    # #                          
--   ######  #    # # #  # #      #    #    #    # #####                      
--   #     # ###### #  # # #      #    #    #    # #                          
--   #     # #    # #   ## #    # #    #    #    # #                          
--   ######  #    # #    #  ####   ####     #####  ######                     
--                                                                            
--   ######                                                                   
--   #     #   ##   #####   ####   ####     #####    ##                       
--   #     #  #  #  #    # #    # #         #    #  #  #                      
--   #     # #    # #    # #    #  ####     #    # #    #                     
--   #     # ###### #    # #    #      #    #    # ######                     
--   #     # #    # #    # #    # #    #    #    # #    #                     
--   ######  #    # #####   ####   ####     #####  #    #                     
--                                                                            
--    #####                                                                   
--   #     # ######  ####  #    # #####    ##   #####   ####  #####    ##     
--   #       #      #    # #    # #    #  #  #  #    # #    # #    #  #  #    
--    #####  #####  #      #    # #    # #    # #    # #    # #    # #    #   
--         # #      #  ### #    # #####  ###### #    # #    # #####  ######   
--   #     # #      #    # #    # #   #  #    # #    # #    # #   #  #    #   
--    #####  ######  ####   ####  #    # #    # #####   ####  #    # #    #   
--                                                                            
--   #     #                                                                  
--    #   #  #####  ###### #####  # #    # #    #                             
--     # #   #    # #      #    # # #    # ##   #                             
--      #    #    # #####  #    # # #    # # #  #                             
--     # #   #####  #      #####  # #    # #  # #                             
--    #   #  #      #      #   #  # #    # #   ##                             
--   #     # #      ###### #    # #  ####  #    #                             
--                                                                            
------------------------------------------------------------------------------
--> Analises de Hipoteses de Negocios
------------------------------------------------------------------------------
--> Autor: Bruno César Pasquini
--> Auxiliar: IA
--> Revisor: Bruno César Pasquini
------------------------------------------------------------------------------



---------------------------------------------------------------------------
----->
--> Bloco 0 — Visão Executiva (Scorecard + Big Numbers)
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 0.1 — Scorecard Multi-Dimensão Consolidado
---------------------------------------------------------------------------

--> Visão transversal — não testa uma hipótese específica, mas cruza dimensões de múltiplas hipóteses em um painel único.

-- | Hipóteses |
-- |-----------|
-- | **Tipo de produto/ramo como driver de churn** — ramos diferentes (Auto, Vida, Residencial) apresentam taxas de churn significativamente distintas. |
-- | **Canal de aquisição influencia retenção** — clientes adquiridos por canais digitais cancelam mais do que os adquiridos por corretores ou parceiros. |
-- | **Faixa etária — jovens cancelam mais** — clientes entre 18-25 anos apresentam taxa de churn superior à média. Suspeita da diretoria Xperiun. |
-- | **Localização geográfica (UF/região)** — a taxa de churn varia por região do país e por UF. |

WITH base_metricas AS (
 SELECT f_apolice.apolice_id
      , f_apolice.status
      , f_apolice.receita_total
      , f_apolice.receita_esperada
      , f_apolice.comissao
      , f_apolice.parcelas_pagas
      , f_apolice.vigencia_meses
      , f_apolice.premio_mensal
      , f_apolice.forma_pagamento
      , d_produto.nome_produto
      , d_produto.ramo
      , d_produto.cobertura
      , d_canal.nome_canal
      , d_cliente.faixa_etaria
      , d_cliente.tempo_cliente_meses
      , d_regiao.regiao
   FROM f_apolice
   LEFT JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
   LEFT JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
   LEFT JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
   LEFT JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
)
, scorecard_unificado AS (
 SELECT 'Produto' AS dimensao_principal
      , nome_produto AS segmento
      , COUNT(*) AS total_apolices
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_pct_num
      , ROUND(SUM(receita_total), 2) AS receita_realizada
      , ROUND(SUM(receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(receita_esperada - receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2) AS gap_receita_num
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(AVG(premio_mensal), 2) AS ticket_medio_premio
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2) AS adimplencia_pct_num
   FROM base_metricas
  GROUP BY nome_produto
  UNION ALL
 SELECT 'Canal'
      , nome_canal
      , COUNT(*)
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2)
      , ROUND(SUM(receita_total), 2)
      , ROUND(SUM(receita_esperada), 2)
      , ROUND(SUM(receita_esperada - receita_total), 2)
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2)
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2)
      , ROUND(AVG(premio_mensal), 2)
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2)
   FROM base_metricas
  GROUP BY nome_canal
  UNION ALL
 SELECT 'Região'
      , regiao
      , COUNT(*)
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2)
      , ROUND(SUM(receita_total), 2)
      , ROUND(SUM(receita_esperada), 2)
      , ROUND(SUM(receita_esperada - receita_total), 2)
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2)
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2)
      , ROUND(AVG(premio_mensal), 2)
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2)
   FROM base_metricas
  GROUP BY regiao
  UNION ALL
 SELECT 'Faixa Etária'
      , faixa_etaria
      , COUNT(*)
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2)
      , ROUND(SUM(receita_total), 2)
      , ROUND(SUM(receita_esperada), 2)
      , ROUND(SUM(receita_esperada - receita_total), 2)
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2)
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2)
      , ROUND(AVG(premio_mensal), 2)
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2)
   FROM base_metricas
  GROUP BY faixa_etaria
  UNION ALL
 SELECT 'Forma Pagamento'
      , forma_pagamento
      , COUNT(*)
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2)
      , ROUND(SUM(receita_total), 2)
      , ROUND(SUM(receita_esperada), 2)
      , ROUND(SUM(receita_esperada - receita_total), 2)
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2)
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2)
      , ROUND(AVG(premio_mensal), 2)
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2)
   FROM base_metricas
  GROUP BY forma_pagamento
  UNION ALL
 SELECT 'Tempo de Casa'
      , CASE
            WHEN tempo_cliente_meses < 6 THEN '0-5 meses'
            WHEN tempo_cliente_meses BETWEEN 6 AND 11 THEN '6-11 meses'
            WHEN tempo_cliente_meses BETWEEN 12 AND 23 THEN '12-23 meses'
            WHEN tempo_cliente_meses BETWEEN 24 AND 47 THEN '24-47 meses'
            ELSE '48+ meses'
        END
      , COUNT(*)
      , SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)
      , ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2)
      , ROUND(SUM(receita_total), 2)
      , ROUND(SUM(receita_esperada), 2)
      , ROUND(SUM(receita_esperada - receita_total), 2)
      , ROUND(100.0 * SUM(receita_esperada - receita_total) / SUM(receita_esperada), 2)
      , ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2)
      , ROUND(AVG(premio_mensal), 2)
      , ROUND(100.0 * AVG(parcelas_pagas / NULLIF(vigencia_meses, 0)), 2)
   FROM base_metricas
  GROUP BY 2
)
 SELECT scorecard_unificado.dimensao_principal
      , scorecard_unificado.segmento
      , scorecard_unificado.total_apolices
      , scorecard_unificado.churn_qtd
      , scorecard_unificado.churn_pct_num || '%' AS churn_pct
      , scorecard_unificado.receita_esperada
      , scorecard_unificado.receita_realizada
      , scorecard_unificado.gap_receita
      , scorecard_unificado.gap_receita_num || '%' AS gap_receita_pct
      , scorecard_unificado.cac_perdido
      , scorecard_unificado.ticket_medio_premio
      , scorecard_unificado.adimplencia_pct_num || '%' AS adimplencia_pct
      , ROUND(
            (scorecard_unificado.churn_pct_num * 0.5)
          + (100.0 * scorecard_unificado.gap_receita / NULLIF(SUM(scorecard_unificado.gap_receita) OVER (), 0) * 0.5)
        , 2) AS score_prioridade
   FROM scorecard_unificado
  ORDER BY score_prioridade DESC
      , scorecard_unificado.churn_pct_num DESC
      , scorecard_unificado.gap_receita_num DESC
      , scorecard_unificado.adimplencia_pct_num DESC
      , scorecard_unificado.dimensao_principal
      , scorecard_unificado.segmento;


---------------------------------------------------------------------------
-----> 0.2 — Motivos de Cancelamento (Ranking Geral)
---------------------------------------------------------------------------

--> Exploratório — não vinculado a uma hipótese específica. Usa o campo `motivo_cancelamento` (texto livre) para categorização qualitativa dos motivos declarados.

-- | Hipóteses |
-- |-----------|
-- | **Motivo de cancelamento como enriquecimento qualitativo** — classificação dos comentários escritos para identificar padrões. |

 SELECT COALESCE(f_apolice.motivo_cancelamento, 'Não informado') AS motivo_cancelamento
      , COUNT(f_apolice.apolice_id) AS churn_qtd
      , ROUND(100.0 * COUNT(f_apolice.apolice_id) / (SELECT COUNT(*) FROM f_apolice WHERE status = 'Cancelada'), 2) || '%' AS pct_do_churn
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total) / COUNT(f_apolice.apolice_id), 2) AS gap_receita_media
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_recentia_pct
      , ROUND(SUM(f_apolice.comissao), 2) AS cac_perdido
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
  GROUP BY motivo_cancelamento
  ORDER BY gap_receita DESC;



---------------------------------------------------------------------------
----->
--> Bloco 1 — Produto, Cobertura & Preço
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 1.1 — Churn por Ramo
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Tipo de produto/ramo como driver de churn** — Auto, Vida e Residencial têm taxas de churn distintas; Auto tende a ser o mais volátil por ticket e concorrência. |

 SELECT d_produto.ramo
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  GROUP BY d_produto.ramo
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 1.2 — Churn por Cobertura
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Tipo de cobertura influencia churn** — coberturas Básicas têm maior churn que Completas ou Premium, pois clientes com menos proteção percebem menos valor. |
-- | **Cobertura Premium como âncora de retenção** — clientes com coberturas Premium cancelam menos por maior investimento percebido (sunk cost). |

 SELECT d_produto.cobertura
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  GROUP BY d_produto.cobertura
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 1.3 — Matriz Ramo × Cobertura
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Tipo de produto/ramo** |
-- | **Tipo de cobertura** |

 SELECT d_produto.ramo
      , d_produto.cobertura
      , d_produto.franquia_media
      , d_produto.premio_medio_mensal
      , d_produto.nome_produto
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  GROUP BY d_produto.ramo
      , d_produto.cobertura
  ORDER BY d_produto.ramo
      , d_produto.cobertura
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 1.4 — Sensibilidade a Preço (Prêmio vs Média do Ramo)
---------------------------------------------------------------------------

--> A query mais relevante para a hipótese #1 do projeto: reajuste de prêmio como driver de churn.

-- | Hipóteses |
-- |-----------|
-- | **Aumento do prêmio na renovação** — clientes cujo prêmio subiu entre vigências cancelam mais. Self-join em `f_apolice` por `cliente_id + produto_id` ordenado por `data_inicio`. |
-- | **Variabilidade de preço entre vigências** — flutuações de prêmio (independente da direção) geram instabilidade e churn. Baseada em pesquisa LexisNexis 2025. |

WITH media_por_produto AS (
 SELECT produto_id
      , AVG(premio_mensal) AS premio_medio
   FROM f_apolice
  GROUP BY produto_id
)
 SELECT d_produto.ramo
      , CASE
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 0.90 THEN '1) Abaixo de -10%'
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 1.10 THEN '2) Dentro da média (±10%)'
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 1.25 THEN '3) Acima +10% a +25%'
            ELSE '4) Acima +25%'
        END AS faixa_preco_vs_media
      , COUNT(*) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
   JOIN media_por_produto ON f_apolice.produto_id = media_por_produto.produto_id
  GROUP BY d_produto.ramo
      , faixa_preco_vs_media
  ORDER BY d_produto.ramo
      , faixa_preco_vs_media
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;

WITH media_por_produto AS (
 SELECT produto_id
      , AVG(premio_mensal) AS premio_medio
   FROM f_apolice
  GROUP BY produto_id
)
 SELECT d_produto.ramo
      , d_produto.cobertura
      , CASE
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 0.90 THEN '1) Abaixo de -10%'
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 1.10 THEN '2) Dentro da média (±10%)'
            WHEN f_apolice.premio_mensal <= media_por_produto.premio_medio * 1.25 THEN '3) Acima +10% a +25%'
            ELSE '4) Acima +25%'
        END AS faixa_preco_vs_media
      , COUNT(*) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
   JOIN media_por_produto ON f_apolice.produto_id = media_por_produto.produto_id
  GROUP BY d_produto.ramo
      , d_produto.cobertura
      , faixa_preco_vs_media
  ORDER BY d_produto.ramo
      , d_produto.cobertura
      , faixa_preco_vs_media
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 1.5 — Sensibilidade à Franquia
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Franquia como fator de percepção de valor** — neste contexto, a query usa `franquia_media` de `d_produto` para avaliar se produtos com franquia alta têm mais churn. |

 SELECT d_produto.ramo
      , CASE
            WHEN d_produto.franquia_media = 0 THEN '1) Nula (R$ 0)'
            WHEN d_produto.franquia_media < 500 THEN '1) Baixa (Até R$ 500)'
            WHEN d_produto.franquia_media <= 1000 THEN '2) Média (Entre R$ 501 e R$ 1000)'
            WHEN d_produto.franquia_media <= 2000 THEN '3) Alta (Entre R$ 1001 e R$ 2000)'
            WHEN d_produto.franquia_media <= 3000 THEN '4) Mais Alta (Entre R$ 2001 e R$ 3000)'
            ELSE '5) Altíssima (Acima de R$ 3000)'
        END AS faixa_franquia
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  GROUP BY d_produto.ramo
      , faixa_franquia
  ORDER BY d_produto.ramo
      , faixa_franquia
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;



---------------------------------------------------------------------------
----->
--> Bloco 2 — Canal & Estratégia de Vendas
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 2.1 — Churn por Canal (com Comissão de Tabela)
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Canal de aquisição influencia retenção** — clientes adquiridos por canais digitais cancelam mais do que os adquiridos via corretor, direto ou parceria. |
-- | **Corretor/parceiro específico** — variação de churn entre corretores individuais indica qualidade da venda. |
-- | **Comissão do canal como proxy de retenção** — canais com maior comissão (e portanto maior investimento na venda) retêm melhor. Derivada do Datacast. |

 SELECT d_canal.nome_canal
      , d_canal.comissao_percentual || '%' AS comissao_tabela
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
  GROUP BY d_canal.nome_canal
      , d_canal.comissao_percentual
  ORDER BY ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) DESC;


---------------------------------------------------------------------------
-----> 2.2 — Canal × Ramo (Cross-Canal)
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Canal de aquisição** |
-- | **Interação canal × produto — combos tóxicos** — certas combinações de canal + ramo geram churn desproporcionalmente alto (ex: digital + Auto). |

 SELECT d_canal.nome_canal
      , d_produto.ramo
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  GROUP BY d_canal.nome_canal
      , d_produto.ramo
  ORDER BY d_canal.nome_canal
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 2.3 — Top Motivos de Cancelamento por Canal
---------------------------------------------------------------------------

--> Revela se cada canal tem um "calcanhar de Aquiles" diferente (preço no digital? atendimento no corretor?).

-- | Hipóteses |
-- |-----------|
-- | **Motivo de cancelamento** — os motivos declarados variam por canal? Canais digitais citam mais "preço" enquanto corretores citam mais "atendimento"? |
-- | **Canal de aquisição** |
-- | **Comissão do canal como proxy** |

 SELECT d_canal.nome_canal
      , f_apolice.motivo_cancelamento
      , COUNT(*) AS churn_qtd
      , ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY d_canal.nome_canal), 2) || '%' AS pct_no_canal
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
   FROM f_apolice
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
  WHERE f_apolice.status = 'Cancelada'
  GROUP BY d_canal.nome_canal
      , f_apolice.motivo_cancelamento
 HAVING COUNT(*) >= 50
  ORDER BY d_canal.nome_canal
      , churn_qtd DESC;



---------------------------------------------------------------------------
----->
--> Bloco 3 — Perfil do Cliente, Geografia & Interações
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 3.1 — Churn por Faixa Etária + Gênero
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Faixa etária — jovens cancelam mais** — clientes entre 18-25 anos apresentam taxa de churn superior. Suspeita explícita da diretoria Xperiun ("jovens e digitais"). |
-- | **Gênero como fator de churn** — homens e mulheres podem ter padrões de cancelamento diferentes, possivelmente mediados pelo tipo de produto. |
-- | **Tipo de Pessoa como fator de churn** — PFs e PJs podem ter padrões de cancelamento diferentes, possivelmente mediados pelo tipo de produto. |

 SELECT CASE
            WHEN d_cliente.tipo_cliente = 'Pessoa Física' AND d_cliente.genero = 'Masculino' THEN 'Masculino'
            WHEN d_cliente.tipo_cliente = 'Pessoa Física' AND d_cliente.genero = 'Feminino' THEN 'Feminino'
            WHEN d_cliente.tipo_cliente = 'Pessoa Jurídica' THEN 'Jurídica'
            ELSE 'Verifique'
         END AS tipo_genero
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
  GROUP BY tipo_genero
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;

 SELECT d_cliente.faixa_etaria
      , CASE
            WHEN d_cliente.tipo_cliente = 'Pessoa Física' AND d_cliente.genero = 'Masculino' THEN 'Masculino'
            WHEN d_cliente.tipo_cliente = 'Pessoa Física' AND d_cliente.genero = 'Feminino' THEN 'Feminino'
            WHEN d_cliente.tipo_cliente = 'Pessoa Jurídica' THEN 'Jurídica'
            ELSE 'Verifique'
         END AS tipo_genero
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_faixa
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
  GROUP BY d_cliente.faixa_etaria
      , tipo_genero
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 3.2 — Churn por Região + Estado
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Localização geográfica (UF/região)** — a taxa de churn varia significativamente por região e UF, possivelmente refletindo concorrência local e perfil socioeconômico. |

 SELECT d_regiao.regiao
      , d_regiao.estado
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
   JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
  GROUP BY d_regiao.regiao
      , d_regiao.estado
 HAVING COUNT(f_apolice.apolice_id) >= 500
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 3.3 — Tempo de Casa (Meses — para gráfico de linha no Power BI)
---------------------------------------------------------------------------

--> Granularidade mensal para visualizar a "curva de sobrevivência" no Power BI.

-- | Hipóteses |
-- |-----------|
-- | **Churn de 1º ano** — aqui em granularidade mensal para identificar o mês exato do pico. |
-- | **Tenure alto = menor churn** — curva contínua para visualização no Power BI. |

 SELECT d_cliente.tempo_cliente_meses
      , COUNT(*) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
  GROUP BY d_cliente.tempo_cliente_meses
  ORDER BY d_cliente.tempo_cliente_meses;


---------------------------------------------------------------------------
-----> 3.4 — Churn por Tempo de Casa (5 Faixas Estratégicas)
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Churn de 1º ano** — a maioria dos cancelamentos ocorre nos primeiros 12 meses de contrato. O primeiro ciclo é o período mais crítico para retenção. |
-- | **Tenure alto = menor churn** — clientes com mais tempo de relacionamento são progressivamente mais fiéis. Efeito de "lock-in" comportamental. |

 SELECT CASE
            WHEN d_cliente.tempo_cliente_meses < 7 THEN '1) 0-6 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 7 AND 12 THEN '2) 7-12 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 13 AND 24 THEN '3) 13-24 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 25 AND 36 THEN '4) 25-36 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 37 AND 48 THEN '5) 37-48 meses'
            ELSE '6) >48 meses'
        END AS faixa_tempo_casa
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
  GROUP BY faixa_tempo_casa
  ORDER BY faixa_tempo_casa;


---------------------------------------------------------------------------
-----> 3.5 — INTERAÇÃO: Canal × Faixa Etária (Combo Tóxico)
---------------------------------------------------------------------------

--> **Insight estratégico:** Esta é a query que responde diretamente à suspeita da diretoria: "Jovens e digitais cancelam mais?"

-- | Hipóteses |
-- |-----------|
-- | **Faixa etária** |
-- | **Canal de aquisição** |

 SELECT d_cliente.faixa_etaria
      , d_canal.nome_canal
      , COUNT(*) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
  GROUP BY d_cliente.faixa_etaria
      , d_canal.nome_canal
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 3.6 — INTERAÇÃO: Canal × Tenure (Venda Agressiva)
---------------------------------------------------------------------------

--> Televendas + cliente novo = churn precoce? Testa a qualidade da venda por canal.

-- | Hipóteses |
-- |-----------|
-- | **Churn de 1º ano** |
-- | **Canal de aquisição** |
-- | **Comissão do canal como proxy** — canais com maior comissão retêm por mais tempo? |

 SELECT d_canal.nome_canal
      , CASE
            WHEN d_cliente.tempo_cliente_meses < 7 THEN '1) 0-6 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 7 AND 12 THEN '2) 7-12 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 13 AND 24 THEN '3) 13-24 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 25 AND 36 THEN '4) 25-36 meses'
            WHEN d_cliente.tempo_cliente_meses BETWEEN 37 AND 48 THEN '5) 37-48 meses'
            ELSE '6) >48 meses'
        END AS faixa_tempo_casa
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
  GROUP BY d_canal.nome_canal
      , faixa_tempo_casa
  ORDER BY d_canal.nome_canal
      , faixa_tempo_casa
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;



---------------------------------------------------------------------------
----->
--> Bloco 4 — Temporal, Sazonalidade & Metas
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 4.1 — Série Temporal do Churn (Mês/Ano)
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Sazonalidade** — meses específicos concentram cancelamentos (ex: início de ano por renovação, meio de ano por revisão orçamentária). |

 SELECT strftime('%Y', f_apolice.data_cancelamento) || '/' || strftime('%m', f_apolice.data_cancelamento) AS ano_mes
      , COUNT(f_apolice.apolice_id) AS churn_qtd
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
    AND f_apolice.data_cancelamento IS NOT NULL
  GROUP BY ano_mes
  ORDER BY ano_mes;


---------------------------------------------------------------------------
-----> 4.2 — Sazonalidade por Ramo (Mês isolado)
---------------------------------------------------------------------------

--> Auto dispara em Jan/Fev (IPVA)? Vida em Jul/Ago (revisão semestral)? Mês isolado permite comparar anos.

-- | Hipóteses |
-- |-----------|
-- | **Sazonalidade** — desdobrada por ramo para identificar se Auto, Vida e Residencial têm picos sazonais diferentes. |
-- | **Tipo de produto/ramo** |

 SELECT d_produto.ramo
      , strftime('%m', f_apolice.data_cancelamento) AS mes
      , COUNT(*) AS churn_qtd
      , ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY d_produto.ramo), 2) || '%' AS pct_do_ramo
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  WHERE f_apolice.status = 'Cancelada'
    AND f_apolice.data_cancelamento IS NOT NULL
  GROUP BY d_produto.ramo
      , mes
  ORDER BY d_produto.ramo
      , mes
      , churn_qtd DESC;


---------------------------------------------------------------------------
-----> 4.3 — Ciclo de Vida da Apólice (Janela de Retenção)
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Churn de 1º ano** — aqui medido em dias para granularidade fina. |
-- | **Tenure alto = menor churn** |
-- | **Momento da renovação como janela crítica** — o churn se concentra próximo à data de fim prevista da apólice, indicando que a renovação é o momento de decisão. |

 SELECT CASE
            WHEN julianday(f_apolice.data_cancelamento) - julianday(f_apolice.data_inicio) <= 30 THEN '0-30 dias'
            WHEN julianday(f_apolice.data_cancelamento) - julianday(f_apolice.data_inicio) <= 90 THEN '31-90 dias'
            WHEN julianday(f_apolice.data_cancelamento) - julianday(f_apolice.data_inicio) <= 180 THEN '91-180 dias'
            WHEN julianday(f_apolice.data_cancelamento) - julianday(f_apolice.data_inicio) <= 365 THEN '181-365 dias'
            ELSE '365+ dias'
        END AS janela_retencao
      , COUNT(f_apolice.apolice_id) AS churn_qtd
      , ROUND(100.0 * COUNT(f_apolice.apolice_id) / (SELECT COUNT(*) FROM f_apolice WHERE status = 'Cancelada' AND data_cancelamento IS NOT NULL), 2) || '%' AS pct_do_total_churn
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
    AND f_apolice.data_cancelamento IS NOT NULL
  GROUP BY janela_retencao
  ORDER BY MIN(julianday(f_apolice.data_cancelamento) - julianday(f_apolice.data_inicio));


---------------------------------------------------------------------------
-----> 4.4 — Emissão em Feriado/Fim de Semana vs Churn
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Contratos fechados em fins de semana/feriados têm maior churn** — vendas fora do horário comercial padrão podem indicar compra impulsiva ou canal de menor qualidade. Derivada do Datacast. |

 SELECT d_calendario.is_feriado
      , d_calendario.is_fim_semana
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_calendario ON f_apolice.data_inicio = d_calendario.data
  GROUP BY d_calendario.is_feriado
      , d_calendario.is_fim_semana
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 4.5 — Governança: Meta de Churn vs Realizado
---------------------------------------------------------------------------

-- > Governança executiva — não testa hipótese de driver de churn, mas contextualiza o desempenho da empresa contra suas próprias metas.

-- | Hipóteses |
-- |-----------|
-- | Usa `d_meta_mensal` para comparar churn real × meta mensal. Narrativa de desempenho para o dashboard executivo. |

WITH churn_real AS (
 SELECT strftime('%Y', f_apolice.data_cancelamento) AS ano
      , CAST(strftime('%m', f_apolice.data_cancelamento) AS INTEGER) AS mes
      , COUNT(f_apolice.apolice_id) AS qtd_churn
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
    AND f_apolice.data_cancelamento IS NOT NULL
  GROUP BY ano
      , mes
)
, base_mensal AS (
 SELECT strftime('%Y', f_apolice.data_inicio) AS ano
      , CAST(strftime('%m', f_apolice.data_inicio) AS INTEGER) AS mes
      , COUNT(f_apolice.apolice_id) AS qtd_base
   FROM f_apolice
  GROUP BY ano
      , mes
)
 SELECT d_meta_mensal.ano
      , d_meta_mensal.mes
      , ROUND(100.0 *d_meta_mensal.meta_taxa_churn, 2) || '%' AS meta_churn_pct
      , ROUND(100.0 * COALESCE(churn_real.qtd_churn, 0) / NULLIF(base_mensal.qtd_base, 0), 2) || '%' AS churn_realizado_pct
      , CASE
            WHEN (COALESCE(churn_real.qtd_churn, 0) / NULLIF(base_mensal.qtd_base, 0)) > d_meta_mensal.meta_taxa_churn THEN '❌ Acima da meta'
            ELSE '✅ Dentro da meta'
        END AS status_governanca
   FROM d_meta_mensal
   LEFT JOIN churn_real ON d_meta_mensal.ano = churn_real.ano
        AND d_meta_mensal.mes = churn_real.mes
   LEFT JOIN base_mensal ON d_meta_mensal.ano = base_mensal.ano
        AND d_meta_mensal.mes = base_mensal.mes
  ORDER BY d_meta_mensal.ano
      , d_meta_mensal.mes;



---------------------------------------------------------------------------
----->
--> Bloco 5 — Financeiro & Operacional
----->
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-----> 5.1 — Churn por Forma de Pagamento
---------------------------------------------------------------------------

-- | Hipóteses |
-- |-----------|
-- | **Débito automático reduz churn** — clientes que pagam via débito automático cancelam menos do que os que usam boleto, cartão ou PIX. Menor atrito = menor oportunidade de decisão. |
-- | **Inadimplência/atrasos precedem churn** — ratio parcelas_pagas/vigencia_meses como proxy de adimplência por forma de pagamento. |

 SELECT f_apolice.forma_pagamento
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
  WHERE f_apolice.vigencia_meses > 0
  GROUP BY f_apolice.forma_pagamento
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 5.2 — Forma de Pagamento × Ramo
---------------------------------------------------------------------------

--> Débito automático protege contra churn em Vida mas não em Auto? Testa interação.

-- | Hipóteses |
-- |-----------|
-- | **Débito automático** — desdobrado por ramo. |
-- | **Tipo de produto/ramo** |

 SELECT d_produto.ramo
      , f_apolice.forma_pagamento
      , COUNT(*) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(100.0 * AVG(f_apolice.parcelas_pagas / NULLIF(f_apolice.vigencia_meses, 0)), 2) || '%' AS adimplencia_pct
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
   FROM f_apolice
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
  WHERE f_apolice.vigencia_meses > 0
  GROUP BY d_produto.ramo
      , f_apolice.forma_pagamento
  ORDER BY d_produto.ramo
      , f_apolice.forma_pagamento
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 5.3 — Pareto do Gap da Receita (Quintis)
---------------------------------------------------------------------------

--> Financeiro/operacional — quantifica a concentração da perda de receita.

-- | Hipóteses |
-- |-----------|
-- | Ordena apólices canceladas por gap (receita_esperada - receita_total) e calcula quintis. Identifica se 20% das apólices respondem por 80% do gap (Pareto). |

WITH ranked_gap AS (
 SELECT f_apolice.apolice_id
      , f_apolice.receita_esperada
      , f_apolice.receita_total
      , f_apolice.premio_mensal
      , f_apolice.comissao
      , f_apolice.vigencia_meses
      , f_apolice.parcelas_pagas
      , (f_apolice.receita_esperada - f_apolice.receita_total) AS gap_receita
      , NTILE(5) OVER (ORDER BY (f_apolice.receita_esperada - f_apolice.receita_total) DESC) AS quintil
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
    AND (f_apolice.receita_esperada - f_apolice.receita_total) > 0
)
 SELECT ranked_gap.quintil
      , COUNT(ranked_gap.apolice_id) AS churn_qtd
      , ROUND(100.0 * COUNT(ranked_gap.apolice_id) / (SELECT COUNT(*) FROM f_apolice WHERE status = 'Cancelada' AND data_cancelamento IS NOT NULL), 0) || '%' AS pct_do_total_churn
      , ROUND(SUM(ranked_gap.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(ranked_gap.receita_total), 2) AS receita_realizada
      , ROUND(SUM(ranked_gap.gap_receita), 2) AS gap_receita
      , ROUND(SUM(ranked_gap.gap_receita) * 100.0 / SUM(SUM(ranked_gap.gap_receita)) OVER (), 2) || '%' AS pct_gap
      , ROUND(100.0 * SUM(ranked_gap.gap_receita) / SUM(ranked_gap.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(ranked_gap.comissao), 2) AS cac_perdido
      , ROUND(AVG(ranked_gap.premio_mensal), 2) AS ticket_medio_premio
   FROM ranked_gap
  GROUP BY ranked_gap.quintil
  ORDER BY ranked_gap.quintil;


---------------------------------------------------------------------------
-----> 5.4 — Pareto do Gap da Comissão Perdida (Quintis)
---------------------------------------------------------------------------

--> Financeiro/operacional — quantifica a concentração da perda de receita.

-- | Hipóteses |
-- |-----------|
-- | Ordena apólices canceladas por comissão perdida e calcula quintis. Identifica se 20% das apólices respondem por 80% da comissão perdida (Pareto). |

WITH ranked_comissao AS (
 SELECT f_apolice.apolice_id
      , f_apolice.receita_esperada
      , f_apolice.receita_total
      , f_apolice.premio_mensal
      , f_apolice.comissao
      , f_apolice.vigencia_meses
      , f_apolice.parcelas_pagas
      , (f_apolice.receita_esperada - f_apolice.receita_total) AS gap_receita
      , NTILE(5) OVER (ORDER BY (f_apolice.comissao) DESC) AS quintil
   FROM f_apolice
  WHERE f_apolice.status = 'Cancelada'
    AND (f_apolice.comissao) > 0
)
 SELECT ranked_comissao.quintil
      , COUNT(ranked_comissao.apolice_id) AS churn_qtd
      , ROUND(100.0 * COUNT(ranked_comissao.apolice_id) / (SELECT COUNT(*) FROM f_apolice WHERE status = 'Cancelada' AND data_cancelamento IS NOT NULL), 0) || '%' AS pct_do_total_churn
      , ROUND(SUM(ranked_comissao.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(ranked_comissao.receita_total), 2) AS receita_realizada
      , ROUND(SUM(ranked_comissao.gap_receita), 2) AS gap_receita
      , ROUND(100.0 * SUM(ranked_comissao.gap_receita) / SUM(ranked_comissao.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(ranked_comissao.comissao), 2) AS cac_perdido
      , ROUND(100.0 * SUM(ranked_comissao.comissao) / SUM(SUM(ranked_comissao.comissao)) OVER (), 2) || '%' AS pct_comissao
      , ROUND(AVG(ranked_comissao.premio_mensal), 2) AS ticket_medio_premio
   FROM ranked_comissao
  GROUP BY ranked_comissao.quintil
  ORDER BY ranked_comissao.quintil;



---------------------------------------------------------------------------
----->
--> Bloco 6 — Cross-sell & Portfolio
----->
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-----> 6.1 — Portfolio de Cross-sell (Mono vs. Multi-produto)
---------------------------------------------------------------------------

--> **Possivelmente o insight mais acionável do projeto inteiro.**
--> "Clientes com 2+ apólices ativas churnam 50% menos" → recomendação direta de cross-sell.

-- | Hipóteses |
-- |-----------|
-- | **Clientes mono-produto cancelam mais** — clientes com apenas 1 produto ativo cancelam mais do que clientes com 2+ produtos simultâneos. O multi-produto cria "lock-in". |
-- | **Perda de desconto de bundle** — quando o cliente perde o desconto de pacote por cancelar um produto, a probabilidade de cancelar os demais aumenta. |
-- | **Unbundling em cascata** — o cancelamento de um produto precipita o cancelamento dos demais, especialmente quando o desconto de pacote se perde. Efeito dominó. |

WITH portfolio_cliente AS (
 SELECT cliente_id
      , COUNT(DISTINCT CASE WHEN status = 'Ativa' THEN apolice_id END) AS qtd_ativas
      , COUNT(DISTINCT CASE WHEN status = 'Ativa' THEN produto_id END) AS qtd_produtos_distintos
   FROM f_apolice
  GROUP BY cliente_id
)
 SELECT CASE
            WHEN portfolio_cliente.qtd_produtos_distintos = 0 THEN '0 produtos ativos'
            WHEN portfolio_cliente.qtd_produtos_distintos = 1 THEN '1 produto ativo'
            WHEN portfolio_cliente.qtd_produtos_distintos = 2 THEN '2 produtos ativos'
            WHEN portfolio_cliente.qtd_produtos_distintos = 3 THEN '3 produtos ativos'
            ELSE '4+ produtos ativos'
        END AS tamanho_portfolio
      , COUNT(f_apolice.apolice_id) AS apolices
      , SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) AS churn_qtd
      , ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' AS churn_pct
      , ROUND(SUM(f_apolice.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(f_apolice.receita_total), 2) AS receita_realizada
      , ROUND(SUM(f_apolice.receita_esperada - f_apolice.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(f_apolice.receita_esperada - f_apolice.receita_total) / SUM(f_apolice.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN f_apolice.comissao ELSE 0 END), 2) AS cac_perdido
      , ROUND(AVG(f_apolice.premio_mensal), 2) AS ticket_medio_premio
      , ROUND(AVG(f_apolice.receita_total), 2) AS ltv_medio
   FROM f_apolice
   JOIN portfolio_cliente ON f_apolice.cliente_id = portfolio_cliente.cliente_id
  GROUP BY tamanho_portfolio
  ORDER BY ROUND(100.0 * SUM(CASE WHEN f_apolice.status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 2) DESC;


---------------------------------------------------------------------------
-----> 6.2 — Efeito Cascata (Sequência Temporal)
---------------------------------------------------------------------------

--> Quando o cliente cancela o 1º produto, cancela o 2º em até 90 dias?

-- | Hipóteses |
-- |-----------|
-- | **Unbundling em cascata** — aqui analisado temporalmente: após o 1º cancelamento, quanto tempo até o 2º? Existe aceleração? |

WITH clientes_multi AS (
 SELECT cliente_id
   FROM f_apolice
  WHERE status = 'Cancelada'
  GROUP BY cliente_id
 HAVING COUNT(*) >= 2
)
, cancelamentos_sequenciais AS (
 SELECT f_apolice.cliente_id
      , f_apolice.apolice_id
      , f_apolice.data_cancelamento
      , ROW_NUMBER() OVER (PARTITION BY f_apolice.cliente_id ORDER BY f_apolice.data_cancelamento) AS ordem_cancel
      , f_apolice.receita_esperada
      , f_apolice.receita_total
      , f_apolice.comissao
      , f_apolice.premio_mensal
   FROM f_apolice
   JOIN clientes_multi ON f_apolice.cliente_id = clientes_multi.cliente_id
  WHERE f_apolice.status = 'Cancelada'
    AND f_apolice.data_cancelamento IS NOT NULL
)
 SELECT CASE
            WHEN c2.data_cancelamento IS NULL THEN '0) Sem 2º cancelamento'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 30 THEN '1) Cascata ≤ 30 dias'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 60 THEN '2) Cascata 31-60 dias'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 90 THEN '3) Cascata 61-90 dias'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 120 THEN '4) Cascata 91-120 dias'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 150 THEN '5) Cascata 121-150 dias'
            WHEN julianday(c2.data_cancelamento) - julianday(c1.data_cancelamento) <= 180 THEN '6) Cascata 151-180 dias'
            ELSE '7) Cascata > 180 dias'
        END AS tipo_cascata
      , COUNT(DISTINCT c1.cliente_id) AS qtd_clientes
      , ROUND(SUM(c1.receita_esperada), 2) AS receita_esperada
      , ROUND(SUM(c1.receita_total), 2) AS receita_realizada
      , ROUND(SUM(c1.receita_esperada - c1.receita_total), 2) AS gap_receita
      , ROUND(100.0 * SUM(c1.receita_esperada - c1.receita_total) / SUM(c1.receita_esperada), 2) || '%' AS gap_receita_pct
      , ROUND(SUM(c1.comissao), 2) AS cac_perdido
      , ROUND(100.0 * SUM(c1.comissao) / SUM(SUM(c1.comissao)) OVER (), 2) || '%' AS pct_comissao
      , ROUND(AVG(c1.premio_mensal), 2) AS ticket_medio_premio
   FROM cancelamentos_sequenciais c1
   LEFT JOIN cancelamentos_sequenciais c2
        ON c1.cliente_id = c2.cliente_id
       AND c2.ordem_cancel = c1.ordem_cancel + 1
  WHERE c1.ordem_cancel = 1
  GROUP BY tipo_cascata
  ORDER BY tipo_cascata;



---------------------------------------------------------------------------
----->
--> Bloco 7 — Star Schema para Power BI ⭐
----->
---------------------------------------------------------------------------

--> **Problema:** O modelo original é snowflake: `f_apolice → d_cliente → d_regiao`.
--> O Power BI funciona melhor com star schema (cada dimensão conecta direto ao fato).

--> **Solução:**
--> - `vw_fato_apolice` = fato com todas as chaves + flags + métricas derivadas + `regiao_id` direto
--> - `vw_dim_cliente_completa` = d_cliente + d_regiao (desnormalizado)
--> - Dimensões puras importadas diretamente: `d_produto`, `d_canal`, `d_calendario`

--> Modelo Star Schema no Power BI:

-->         d_produto ──┐
-->           d_canal ──┤
-->   d_calendario ─────┤── f_apolice
-->   vw_dim_cliente ───┘
-->   (c/ d_regiao)


---------------------------------------------------------------------------
-----> 7.1 — Dimensão Calendário
---------------------------------------------------------------------------

 SELECT "data"
      , ano
      , semestre
      , trimestre
      , mes
      , CAST(strftime('%d', "data") AS INTEGER) AS dia
      , nome_mes
      , dia_semana
      , nome_dia_semana
      , is_fim_semana
      , is_feriado
      , ano || ' Q' || trimestre AS ano_trimestre
      , ano || ' ' || strftime('%m', "data") as ano_mes
      , SUBSTR(nome_mes, 1, 3) || ' ' || ano AS mes_ano
      , printf('%04d-%02d-01', ano, mes) AS inicio_mes
   FROM d_calendario
  ORDER BY "data";


---------------------------------------------------------------------------
-----> 7.2 — Dimensão Canal
---------------------------------------------------------------------------

 SELECT canal_id
      , tipo
      , nome_canal
      , comissao_percentual / 100 AS comissao_percentual
   FROM d_canal
  ORDER BY canal_id;


---------------------------------------------------------------------------
-----> 7.3 — Dimensão Cliente Completa (Desnormalizada)
---------------------------------------------------------------------------

--> Achata o snowflake: `d_cliente + d_regiao` em uma view só.

--> Dimensão de cliente desnormalizada (achata `d_cliente` + `d_regiao`). Elimina snowflake → star schema puro.

 SELECT d_cliente.cliente_id
      , d_cliente.tipo_cliente
      , d_cliente.genero
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
--       , d_cliente.UF
--       , d_cliente.regiao_id
-- Campos de d_regiao (desnormalizados)
      , d_regiao.regiao
      , d_regiao.uf
      , d_regiao.estado
   FROM d_cliente
   LEFT JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
  ORDER BY cliente_id;


---------------------------------------------------------------------------
-----> 7.4 — Dimensão Produto
---------------------------------------------------------------------------

 SELECT produto_id
      , ramo
      , cobertura
      , nome_produto
      , descricao
      , premio_medio_mensal
      , franquia_media
   FROM d_produto
  ORDER BY produto_id;


---------------------------------------------------------------------------
-----> 7.5 — Fato Apólice
---------------------------------------------------------------------------

--> Query para importação no Power Query da tabela fato de Apólices.

-- | Flag / Coluna           | Hipóteses |
-- |-------------------------|-----------|
-- | is_churn                | Variável dependente (todas) |
-- | dias_ate_cancelamento   | Momento da renovação |
-- | gap_receita             | Financeiro (dashboard) |
-- | cac_perdido             | Comissão como proxy |

WITH base AS (
 SELECT *
      , CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END AS churn_flag
      , ROUND(receita_esperada - receita_total, 2) AS gap_receita
      , CASE
            WHEN status = 'Cancelada' AND data_cancelamento IS NOT NULL
            THEN CAST(julianday(data_cancelamento) - julianday(data_inicio) AS INTEGER)
            ELSE NULL
        END AS dias_ate_churn
      , CASE
            WHEN status = 'Cancelada' THEN comissao
            ELSE 0
        END AS cac_perdido
   FROM f_apolice
)
 SELECT apolice_id
      , cliente_id
      , produto_id
      , canal_id
      , vigencia_meses
      , premio_mensal
      , forma_pagamento
      , comissao
      , data_inicio
      , data_cancelamento
      , receita_esperada
      , receita_total
      , parcelas_pagas
      , status
      , motivo_cancelamento
      , churn_flag
      , gap_receita
      , dias_ate_churn
      , cac_perdido
      , CASE
            WHEN churn_flag = 0 THEN '1) Nao Cancelada'
            WHEN dias_ate_churn IS NULL THEN '2) Cancelada (sem data)'
            WHEN dias_ate_churn <= 30 THEN '3) 0-30 dias'
            WHEN dias_ate_churn <= 90 THEN '4) 31-90 dias'
            WHEN dias_ate_churn <= 180 THEN '5) 91-180 dias'
            WHEN dias_ate_churn <= 365 THEN '6) 181-365 dias'
            ELSE '7) 365+ dias'
        END AS janela_retencao
   FROM base
  ORDER BY data_inicio
      , data_cancelamento
      , apolice_id;


---------------------------------------------------------------------------
-----> 7.6 — Fato Meta Mensal
---------------------------------------------------------------------------

 SELECT printf('%04d-%02d-01', ano, mes) AS inicio_mes
      , ano
      , mes
      , meta_novas_apolices AS meta_apolices
      , meta_receita_premios
      , meta_taxa_churn
   FROM d_meta_mensal
  ORDER BY inicio_mes;


---------------------------------------------------------------------------
-----> 7.7 — Consulta do Momento da Última Atualização
---------------------------------------------------------------------------

SELECT strftime('%d/%m/%Y %H:%M', datetime('now', '-3 hours')) AS Momento_Update;


---------------------------------------------------------------------------
-----> 7.8 — Verifica se há chaves duplicadas nas dimensões
---------------------------------------------------------------------------

 SELECT 'canal'
      , canal_id
      , COUNT(*) 
   FROM d_canal
  GROUP BY canal_id
 HAVING COUNT(*) > 1
UNION ALL
 SELECT 'calendario'
      , data
      , COUNT(*) 
   FROM d_calendario
  GROUP BY data
 HAVING COUNT(*) > 1
UNION ALL
 SELECT 'cliente' AS tabela
      , cliente_id
      , COUNT(*) 
   FROM d_cliente
  GROUP BY cliente_id
 HAVING COUNT(*) > 1
UNION ALL
 SELECT 'produto'
      , produto_id
      , COUNT(*) 
   FROM d_produto
  GROUP BY produto_id
 HAVING COUNT(*) > 1;


---------------------------------------------------------------------------
-----> 7.9 — Validações em alguns cards no Power BI...
---------------------------------------------------------------------------

SELECT ROUND(SUM(receita_esperada), 2) AS receita_esperada FROM f_apolice;

SELECT ROUND(SUM(receita_total), 2) AS receita_realizada FROM f_apolice;

SELECT ROUND(SUM(receita_esperada - receita_total), 2) AS gap_receita FROM f_apolice;

SELECT ROUND(SUM(CASE WHEN status = 'Cancelada' THEN comissao ELSE 0 END), 2) AS cac_total FROM f_apolice;

SELECT ROUND(SUM(CASE WHEN status = 'Cancelada' THEN (comissao * (vigencia_meses - parcelas_pagas) * 1.0 / NULLIF(vigencia_meses, 0)) ELSE 0 END), 2) AS cac_proporcional FROM f_apolice;

SELECT ROUND(AVG(premio_mensal), 2) AS ticket_medio FROM f_apolice;

SELECT COUNT(*) AS qtd_apolices FROM f_apolice;

SELECT ROUND(100.0 * SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END) / COUNT(*), 4) || '%' AS Taxa_Churn FROM f_apolice;

SELECT ROUND(100.0 * SUM(parcelas_pagas) / NULLIF(SUM(vigencia_meses), 0), 4) || '%' AS Taxa_Adimplencia FROM f_apolice;

SELECT ROUND(100.0 * COUNT(DISTINCT CASE WHEN status = 'Cancelada' THEN cliente_id END) / COUNT(DISTINCT cliente_id), 4) || '%' AS Taxa_Churn_Cliente_Unico FROM f_apolice;

SELECT ROUND(SUM(receita_total) * 1.0 / NULLIF(SUM(CASE WHEN status = 'Cancelada' THEN comissao * (vigencia_meses - parcelas_pagas) * 1.0 / NULLIF(vigencia_meses, 0) ELSE 0 END), 0), 2) AS cac_eficiencia FROM f_apolice;

SELECT ramo,
       COUNT(*) AS qtd,
       ROUND(SUM(receita_total),2) AS rec_real,
       ROUND(SUM(CASE WHEN status = 'Cancelada' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) || '%' AS churn_pct,
       ROUND(SUM(receita_esperada - receita_total),2) AS gap
FROM f_apolice
LEFT JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
GROUP BY ramo;
