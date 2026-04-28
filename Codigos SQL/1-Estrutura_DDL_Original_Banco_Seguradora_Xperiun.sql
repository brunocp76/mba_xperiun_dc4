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
--> Estrutura DDL do Banco de Dados SQL da Seguradora Xperiun
------------------------------------------------------------------------------
--> Autor: Bruno Cesar Pasquini
--> Auxiliar: IA
--> Revisor: Bruno Cesar Pasquini
------------------------------------------------------------------------------

---------------------------------------------------------------------------
--> Obtido com o código:
-->
--> SELECT
-->    sql
--> FROM
-->    sqlite_master
--> WHERE
-->    type IN ('table', 'index', 'trigger')
-->    AND name NOT LIKE 'sqlite_%'
--> ORDER BY sql;
---------------------------------------------------------------------------


---------------------------------------------------------------------------
--> Tabela d_calendario
---------------------------------------------------------------------------

CREATE TABLE d_calendario
(
    data TEXT PRIMARY KEY,
    ano INTEGER,
    mes INTEGER,
    nome_mes TEXT,
    trimestre INTEGER,
    semestre INTEGER,
    dia_semana INTEGER,
    nome_dia_semana TEXT,
    is_fim_semana INTEGER,
    is_feriado INTEGER
)


---------------------------------------------------------------------------
--> Tabela d_canal
---------------------------------------------------------------------------

CREATE TABLE d_canal
(
    canal_id INTEGER PRIMARY KEY,
    nome_canal TEXT,
    tipo TEXT,
    comissao_percentual REAL
)


---------------------------------------------------------------------------
--> Tabela d_cliente
---------------------------------------------------------------------------

CREATE TABLE d_cliente
(
    cliente_id INTEGER PRIMARY KEY,
    uf TEXT,
    regiao_id INTEGER,
    faixa_etaria TEXT,
    genero TEXT,
    tipo_cliente TEXT,
    tempo_cliente_meses INTEGER
)


---------------------------------------------------------------------------
--> Tabela d_meta_mensal
---------------------------------------------------------------------------

CREATE TABLE d_meta_mensal
(
    meta_id INTEGER PRIMARY KEY,
    ano INTEGER,
    mes INTEGER,
    meta_novas_apolices INTEGER,
    meta_receita_premios REAL,
    meta_taxa_churn REAL
)


---------------------------------------------------------------------------
--> Tabela d_produto
---------------------------------------------------------------------------

CREATE TABLE d_produto
(
    produto_id INTEGER PRIMARY KEY,
    nome_produto TEXT,
    ramo TEXT,
    cobertura TEXT,
    premio_medio_mensal REAL,
    franquia_media REAL,
    descricao TEXT
)


---------------------------------------------------------------------------
--> Tabela d_regiao
---------------------------------------------------------------------------

CREATE TABLE d_regiao
(
    regiao_id INTEGER PRIMARY KEY,
    uf TEXT,
    estado TEXT,
    regiao TEXT
)


---------------------------------------------------------------------------
--> Tabela f_apolice
---------------------------------------------------------------------------

CREATE TABLE f_apolice
(
    apolice_id INTEGER PRIMARY KEY,
    cliente_id INTEGER,
    produto_id INTEGER,
    canal_id INTEGER,
    data_inicio TEXT,
    data_fim_prevista TEXT,
    vigencia_meses INTEGER,
    premio_mensal REAL,
    parcelas_pagas INTEGER,
    receita_total REAL,
    receita_esperada REAL,
    comissao REAL,
    forma_pagamento TEXT,
    status TEXT,
    data_cancelamento TEXT,
    motivo_cancelamento TEXT,
    FOREIGN KEY (cliente_id) REFERENCES d_cliente(cliente_id),
    FOREIGN KEY (produto_id) REFERENCES d_produto(produto_id),
    FOREIGN KEY (canal_id) REFERENCES d_canal(canal_id),
    FOREIGN KEY (data_inicio) REFERENCES d_calendario(data)
)