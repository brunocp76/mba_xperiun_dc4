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
--> Primeiras Analises
------------------------------------------------------------------------------
--> Autor: Bruno César Pasquini
--> Auxiliar: IA
--> Revisor: Bruno César Pasquini
------------------------------------------------------------------------------


---------------------------------------------------------------------------
--> Tabela d_calendario
---------------------------------------------------------------------------

 SELECT *
   FROM d_calendario;


---------------------------------------------------------------------------
--> Tabela d_canal
---------------------------------------------------------------------------

 SELECT *
   FROM d_canal;


---------------------------------------------------------------------------
--> Tabela d_cliente
---------------------------------------------------------------------------

 SELECT *
   FROM d_cliente;

 SELECT MIN(tempo_cliente_meses)   AS tempo_cliente_meses_min
      , AVG(tempo_cliente_meses)   AS tempo_cliente_meses_med
      , MAX(tempo_cliente_meses)   AS tempo_cliente_meses_max
   FROM d_cliente;


---------------------------------------------------------------------------
--> Tabela d_meta_mensal
---------------------------------------------------------------------------

 SELECT *
   FROM d_meta_mensal;

 SELECT COUNT(*)                            AS Registros
      , ROUND(MIN(meta_novas_apolices), 2)  AS Meta_Receita_Min
      , ROUND(AVG(meta_novas_apolices), 2)  AS Meta_Receita_Med
      , ROUND(MAX(meta_novas_apolices), 2)  AS Meta_Receita_Max
      , ROUND(MIN(meta_receita_premios), 2) AS Meta_Quantidade_Min
      , ROUND(AVG(meta_receita_premios), 2) AS Meta_Quantidade_Med
      , ROUND(MAX(meta_receita_premios), 2) AS Meta_Quantidade_Max
      , ROUND(MIN(meta_taxa_churn), 2)      AS Meta_Quantidade_Min
      , ROUND(AVG(meta_taxa_churn), 2)      AS Meta_Quantidade_Med
      , ROUND(MAX(meta_taxa_churn), 2)      AS Meta_Quantidade_Max
   FROM d_meta_mensal;

 SELECT ano
      , COUNT(*)                            AS Registros
      , ROUND(MIN(meta_novas_apolices), 2)  AS Meta_Receita_Min
      , ROUND(AVG(meta_novas_apolices), 2)  AS Meta_Receita_Med
      , ROUND(MAX(meta_novas_apolices), 2)  AS Meta_Receita_Max
      , ROUND(MIN(meta_receita_premios), 2) AS Meta_Quantidade_Min
      , ROUND(AVG(meta_receita_premios), 2) AS Meta_Quantidade_Med
      , ROUND(MAX(meta_receita_premios), 2) AS Meta_Quantidade_Max
      , ROUND(MIN(meta_taxa_churn), 2)      AS Meta_Quantidade_Min
      , ROUND(AVG(meta_taxa_churn), 2)      AS Meta_Quantidade_Med
      , ROUND(MAX(meta_taxa_churn), 2)      AS Meta_Quantidade_Max
   FROM d_meta_mensal
  GROUP BY ano
  ORDER BY ano;

 SELECT mes
      , COUNT(*)                            AS Registros
      , ROUND(MIN(meta_novas_apolices), 2)  AS Meta_Receita_Min
      , ROUND(AVG(meta_novas_apolices), 2)  AS Meta_Receita_Med
      , ROUND(MAX(meta_novas_apolices), 2)  AS Meta_Receita_Max
      , ROUND(MIN(meta_receita_premios), 2) AS Meta_Quantidade_Min
      , ROUND(AVG(meta_receita_premios), 2) AS Meta_Quantidade_Med
      , ROUND(MAX(meta_receita_premios), 2) AS Meta_Quantidade_Max
      , ROUND(MIN(meta_taxa_churn), 2)      AS Meta_Quantidade_Min
      , ROUND(AVG(meta_taxa_churn), 2)      AS Meta_Quantidade_Med
      , ROUND(MAX(meta_taxa_churn), 2)      AS Meta_Quantidade_Max
   FROM d_meta_mensal
  GROUP BY mes
  ORDER BY mes;


---------------------------------------------------------------------------
--> Tabela d_produto
---------------------------------------------------------------------------

 SELECT *
      , franquia_media / premio_medio_mensal   AS franquia_sobre_premio
   FROM d_produto;


---------------------------------------------------------------------------
--> Tabela d_regiao
---------------------------------------------------------------------------

 SELECT *
   FROM d_regiao;


---------------------------------------------------------------------------
--> Tabela f_apolice
---------------------------------------------------------------------------

 SELECT *
   FROM f_apolice
  ORDER BY data_inicio
      , data_fim_prevista
      , receita_total DESC
      , receita_esperada DESC;

 SELECT COUNT(*)                                                                            AS registros
      , ROUND(SUM(receita_total), 2)                                                        AS receita_total_realizada
      , ROUND(SUM(receita_esperada), 2)                                                     AS receita_esperada
      , ROUND(SUM(receita_esperada) - SUM(receita_total), 2)                                AS perda_estimada
      , ROUND(SUM(CASE WHEN status = "Cancelada" THEN 1 ELSE 0 END), 2)                     AS cancelamentos
      , ROUND(100.0 * SUM(CASE WHEN status = "Cancelada" THEN 1 ELSE 0 END) / COUNT(*), 2)  AS taxa_churn
      , ROUND(AVG(premio_mensal), 2)                                                        AS premio_medio_mensal
   FROM f_apolice;

 SELECT MIN(vigencia_meses)
      , AVG(vigencia_meses)
      , MAX(vigencia_meses)
   FROM f_apolice;