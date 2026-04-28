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
--> Analise de Chaves Primarias e Estrangeiras
------------------------------------------------------------------------------
--> Autor: Bruno César Pasquini
--> Auxiliar: IA
--> Revisor: Bruno César Pasquini
------------------------------------------------------------------------------


---------------------------------------------------------------------------
--> Tabela d_calendario
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                         AS linhas
      , COUNT(DISTINCT "data")                          AS distintos
      , SUM(CASE WHEN "data" IS NULL THEN 1 ELSE 0 END) AS nulos
   FROM d_calendario;

--> Chave Primária: data


---------------------------------------------------------------------------
--> Tabela d_canal
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                           AS linhas
      , COUNT(DISTINCT canal_id)                           AS distintos
      , SUM(CASE WHEN canal_id IS NULL THEN 1 ELSE 0 END)  AS nulos
   FROM d_canal;

--> Chave Primária: canal_id


---------------------------------------------------------------------------
--> Tabela d_cliente
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                              AS linhas
      , COUNT(DISTINCT cliente_id)                            AS distintos
      , SUM(CASE WHEN cliente_id IS NULL THEN 1 ELSE 0 END)   AS nulos
   FROM d_cliente;

--> Chave Primária: cliente_id


---------------------------------------------------------------------------
--> Tabela d_meta_mensal
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                           AS linhas
      , COUNT(DISTINCT meta_id)                            AS distintos
      , SUM(CASE WHEN meta_id IS NULL THEN 1 ELSE 0 END)   AS nulos
   FROM d_meta_mensal;

--> Chave Primária: meta_id


---------------------------------------------------------------------------
--> Tabela d_produto
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                            AS linhas
      , COUNT(DISTINCT produto_id)                          AS distintos
      , SUM(CASE WHEN produto_id IS NULL THEN 1 ELSE 0 END) AS nulos
   FROM d_produto;

--> Chave Primária: produto_id


---------------------------------------------------------------------------
--> Tabela d_regiao
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                           AS linhas
      , COUNT(DISTINCT regiao_id)                          AS distintos
      , SUM(CASE WHEN regiao_id IS NULL THEN 1 ELSE 0 END) AS nulos
   FROM d_regiao;

--> Chave Primária: produto_id


---------------------------------------------------------------------------
--> Tabela f_apolice
---------------------------------------------------------------------------

--> Candidatas a chaves primárias

 SELECT COUNT(*)                                              AS linhas
      , COUNT(DISTINCT apolice_id)                            AS distintos
      , SUM(CASE WHEN apolice_id IS NULL THEN 1 ELSE 0 END)   AS nulos
   FROM f_apolice;

--> Candidatas a chaves estrangeiras

 SELECT COUNT(*)                                              AS linhas
      , COUNT(DISTINCT cliente_id)                            AS distintos
      , SUM(CASE WHEN cliente_id IS NULL THEN 1 ELSE 0 END)   AS nulos
   FROM f_apolice;

 SELECT COUNT(*)                                            AS linhas
      , COUNT(DISTINCT produto_id)                          AS distintos
      , SUM(CASE WHEN produto_id IS NULL THEN 1 ELSE 0 END) AS nulos
   FROM f_apolice;

 SELECT COUNT(*)                                            AS linhas
      , COUNT(DISTINCT canal_id)                            AS distintos
      , SUM(CASE WHEN canal_id IS NULL THEN 1 ELSE 0 END)   AS nulos
   FROM f_apolice;

 SELECT COUNT(*)                                              AS linhas
      , COUNT(DISTINCT data_inicio)                           AS distintos
      , SUM(CASE WHEN data_inicio IS NULL THEN 1 ELSE 0 END)  AS nulos
   FROM f_apolice;

--> Chave Primária: apolice_id
--> Chaves Estrangeiras: cliente_id, produto_id, canal_id e data_inicio
