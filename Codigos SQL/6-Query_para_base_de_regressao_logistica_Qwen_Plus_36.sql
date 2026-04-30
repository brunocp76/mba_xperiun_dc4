WITH todas_apolices AS (
 SELECT f_apolice.apolice_id
      , f_apolice.cliente_id
      , f_apolice.produto_id
      , f_apolice.canal_id
      , f_apolice.data_inicio
      , f_apolice.vigencia_meses
      , f_apolice.premio_mensal
      , f_apolice.forma_pagamento
--       , f_apolice.comissao  // Correlação linear perfeita como produto de receita_esperada e comissao_percentual
      , f_apolice.receita_esperada
      , f_apolice.status
      , f_apolice.motivo_cancelamento
      , f_apolice.data_cancelamento
      , d_cliente.tipo_cliente
      , CASE WHEN d_cliente.tipo_cliente = 'Pessoa Juridica' THEN 'Não Aplicável'
             ELSE d_cliente.genero
        END AS genero
      , d_cliente.tempo_cliente_meses
      , d_cliente.faixa_etaria
      , d_cliente.regiao_id
      , d_canal.nome_canal
      , d_canal.tipo AS tipo_canal
      , d_canal.comissao_percentual
      , d_produto.ramo
      , d_produto.cobertura
      , d_produto.nome_produto
      , d_produto.franquia_media
      , d_produto.premio_medio_mensal
      , d_regiao.regiao
      , d_regiao.estado
   FROM f_apolice
   JOIN d_cliente ON f_apolice.cliente_id = d_cliente.cliente_id
   JOIN d_canal ON f_apolice.canal_id = d_canal.canal_id
   JOIN d_produto ON f_apolice.produto_id = d_produto.produto_id
   JOIN d_regiao ON d_cliente.regiao_id = d_regiao.regiao_id
  WHERE f_apolice.data_inicio < '2024-10-01'
),
com_flags AS (
 SELECT t.apolice_id
      , t.cliente_id
      , t.produto_id
      , t.canal_id
      , t.data_inicio
      , t.vigencia_meses
      , t.premio_mensal
      , t.forma_pagamento
--       , t.comissao  // Correlação linear perfeita como produto de receita_esperada e comissao_percentual
      , t.receita_esperada
      , t.status
      , t.motivo_cancelamento
      , t.data_cancelamento
      , t.tipo_cliente
      , t.genero
      , t.tempo_cliente_meses
      , t.faixa_etaria
      , t.regiao_id
      , t.nome_canal
      , t.tipo_canal
      , t.comissao_percentual
      , t.ramo
      , t.cobertura
      , t.nome_produto
      , t.franquia_media
      , t.premio_medio_mensal
      , t.regiao
      , t.estado
      , ROW_NUMBER() OVER(PARTITION BY t.cliente_id, t.ramo ORDER BY t.data_inicio, t.apolice_id) AS rn_ramo
      , ROW_NUMBER() OVER(PARTITION BY t.cliente_id, t.cobertura ORDER BY t.data_inicio, t.apolice_id) AS rn_cobertura
   FROM todas_apolices t
),
cumulativas AS (
 SELECT c.apolice_id
      , c.cliente_id
      , c.produto_id
      , c.canal_id
      , c.data_inicio
      , c.vigencia_meses
      , c.premio_mensal
      , c.forma_pagamento
--       , c.comissao  // Correlação linear perfeita como produto de receita_esperada e comissao_percentual
      , c.receita_esperada
      , c.status
      , c.motivo_cancelamento
      , c.data_cancelamento
      , c.tipo_cliente
      , c.genero
      , c.tempo_cliente_meses
      , c.faixa_etaria
      , c.regiao_id
      , c.nome_canal
      , c.tipo_canal
      , c.comissao_percentual
      , c.ramo
      , c.cobertura
      , c.nome_produto
      , c.franquia_media
      , c.premio_medio_mensal
      , c.regiao
      , c.estado
      , COUNT(*) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS qtd_apolices_cliente
      , SUM(CASE WHEN c.rn_ramo = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS qtd_ramos_distintos
      , SUM(CASE WHEN c.rn_cobertura = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS qtd_coberturas_distintas
      , MAX(CASE WHEN c.ramo = 'Automóvel' THEN 1 ELSE 0 END) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS tem_auto
      , MAX(CASE WHEN c.ramo = 'Vida' THEN 1 ELSE 0 END) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS tem_vida
      , MAX(CASE WHEN c.ramo = 'Residencial' THEN 1 ELSE 0 END) OVER(PARTITION BY c.cliente_id ORDER BY c.data_inicio, c.apolice_id) AS tem_residencial
   FROM com_flags c
),
base_filtrada AS (
 SELECT t.apolice_id
      , t.cliente_id
      , t.produto_id
      , t.canal_id
      , t.data_inicio
      , t.vigencia_meses
      , t.premio_mensal
      , t.forma_pagamento
--       , t.comissao  // Correlação linear perfeita como produto de receita_esperada e comissao_percentual
      , t.receita_esperada
      , t.tipo_cliente
      , t.genero
      , t.tempo_cliente_meses
      , t.faixa_etaria
      , t.nome_canal
      , t.tipo_canal
      , t.comissao_percentual
      , t.ramo
      , t.cobertura
      , t.nome_produto
      , t.franquia_media
      , t.premio_medio_mensal
      , t.regiao
      , t.estado
      , c.qtd_apolices_cliente
      , c.qtd_ramos_distintos
      , c.qtd_coberturas_distintas
      , c.tem_auto
      , c.tem_vida
      , c.tem_residencial
      , CASE
            WHEN c.qtd_ramos_distintos > 1 THEN 1
            ELSE 0
        END AS tem_cross_sell
      , t.premio_mensal * 1.0 / NULLIF(t.premio_medio_mensal, 0) AS razao_premio
      , CAST(strftime('%m', t.data_inicio) AS INTEGER) AS mes_inicio
      , CASE
            WHEN CAST(strftime('%m', t.data_inicio) AS INTEGER) <= 3 THEN 1
            WHEN CAST(strftime('%m', t.data_inicio) AS INTEGER) <= 6 THEN 2
            WHEN CAST(strftime('%m', t.data_inicio) AS INTEGER) <= 9 THEN 3
            ELSE 4
        END AS trimestre_inicio
      , CASE
            WHEN t.status = 'Cancelada' AND t.motivo_cancelamento NOT IN ('Falecimento do segurado', 'Venda do bem segurado') THEN 1
            ELSE 0
        END AS indicador_churn
   FROM todas_apolices t
   JOIN cumulativas c ON t.apolice_id = c.apolice_id
  WHERE 1=1
    AND t.status != 'Suspensa'
    AND NOT (t.status = 'Cancelada' AND t.motivo_cancelamento IN ('Falecimento do segurado', 'Venda do bem segurado'))
    AND (t.data_cancelamento > t.data_inicio OR TRIM(t.data_cancelamento) = '' OR t.data_cancelamento IS NULL)
)
 SELECT base_filtrada.apolice_id
      , base_filtrada.cliente_id
      , base_filtrada.produto_id
      , base_filtrada.canal_id
      , base_filtrada.data_inicio
      , base_filtrada.vigencia_meses
      , base_filtrada.premio_mensal
      , base_filtrada.forma_pagamento
--       , base_filtrada.comissao  // Correlação linear perfeita como produto de receita_esperada e comissao_percentual
      , base_filtrada.receita_esperada
      , base_filtrada.tipo_cliente
      , base_filtrada.genero
      , base_filtrada.tempo_cliente_meses
      , base_filtrada.faixa_etaria
      , base_filtrada.nome_canal
      , base_filtrada.tipo_canal
      , base_filtrada.comissao_percentual
      , base_filtrada.ramo
      , base_filtrada.cobertura
      , base_filtrada.nome_produto
      , base_filtrada.franquia_media
      , base_filtrada.premio_medio_mensal
      , base_filtrada.regiao
      , base_filtrada.estado
      , base_filtrada.qtd_apolices_cliente
      , base_filtrada.qtd_ramos_distintos
      , base_filtrada.qtd_coberturas_distintas
      , base_filtrada.tem_auto
      , base_filtrada.tem_vida
      , base_filtrada.tem_residencial
      , base_filtrada.tem_cross_sell
      , base_filtrada.razao_premio
      , base_filtrada.mes_inicio
      , base_filtrada.trimestre_inicio
      , base_filtrada.indicador_churn
   FROM base_filtrada
  ORDER BY base_filtrada.data_inicio
      , base_filtrada.apolice_id;