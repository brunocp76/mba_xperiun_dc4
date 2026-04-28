
# ==========================================================================
# MODELO DE REGRESSÃO LOGÍSTICA — CHURN VOLUNTÁRIO
# Seguradora Xperiun
# ==========================================================================
# Autor:    Bruno Cesar Pasquini (com assistência de IA)
# Objetivo: Modelo explicativo de churn voluntário em apólices de seguros
# ==========================================================================

# %%
# ==========================================================================
# ETAPA 2 — IMPORTAÇÃO E VALIDAÇÃO DOS DADOS
# ==========================================================================

# --------------------------------------------------------------------------
# 2.1 — Imports
# --------------------------------------------------------------------------
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import warnings

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', 40)
pd.set_option('display.width', 120)

print("Bibliotecas importadas com sucesso.")

# %%
# --------------------------------------------------------------------------
# 2.2 — Leitura do CSV exportado do SQLite
# --------------------------------------------------------------------------
# Ajuste o caminho conforme a localização do seu arquivo CSV.
CAMINHO_CSV = 'base_modelagem_churn.csv'

df = pd.read_csv(
    CAMINHO_CSV
    , sep=','            # ajuste se necessário (';' para CSVs brasileiros)
    , encoding='utf-8'   # ajuste se necessário ('latin-1' para acentos)
    , low_memory=False
)

print(f"Shape: {df.shape}")
print(f"Registros: {df.shape[0]:,}")
print(f"Colunas:   {df.shape[1]}")

# %%
# --------------------------------------------------------------------------
# 2.3 — Validação inicial
# --------------------------------------------------------------------------

# 2.3.1 — Tipos de dados
print("=" * 76)
print("TIPOS DE DADOS")
print("=" * 76)
print(df.dtypes.to_string())

# %%
# 2.3.2 — Valores nulos
print("=" * 76)
print("VALORES NULOS POR COLUNA")
print("=" * 76)
nulos = df.isnull().sum()
nulos_pct = (df.isnull().sum() / len(df) * 100).round(2)
resumo_nulos = pd.DataFrame({
    'nulos': nulos
    , 'pct': nulos_pct
})
print(resumo_nulos[resumo_nulos['nulos'] > 0].to_string())
if resumo_nulos['nulos'].sum() == 0:
    print("Nenhum valor nulo encontrado.")

# %%
# 2.3.3 — Taxa de churn (deve ser ~16%)
taxa_churn = df['indicador_churn'].mean()
n_churn = df['indicador_churn'].sum()
n_nao_churn = len(df) - n_churn
print("=" * 76)
print("DISTRIBUIÇÃO DA VARIÁVEL RESPOSTA")
print("=" * 76)
print(f"Total de registros: {len(df):,}")
print(f"Churn = 1:          {n_churn:,} ({taxa_churn:.2%})")
print(f"Churn = 0:          {n_nao_churn:,} ({1 - taxa_churn:.2%})")

# Validação: taxa deve estar próxima de 16%
assert 0.10 < taxa_churn < 0.25, \
    f"ALERTA: Taxa de churn ({taxa_churn:.2%}) fora do esperado (~16%)"
print(f"\n✅ Taxa de churn ({taxa_churn:.2%}) dentro do intervalo esperado.")

# %%
# 2.3.4 — Estatísticas descritivas das variáveis contínuas
print("=" * 76)
print("ESTATÍSTICAS DESCRITIVAS — VARIÁVEIS CONTÍNUAS")
print("=" * 76)
continuas = [
    'tempo_cliente_meses', 'premio_medio_mensal', 'franquia_media'
    , 'comissao_percentual', 'vigencia_meses', 'premio_mensal'
    , 'comissao', 'receita_esperada', 'ratio_premio_vs_medio'
    , 'qtd_apolices_acumuladas', 'qtd_ramos_distintos'
    , 'qtd_coberturas_distintas'
]
# Filtra apenas colunas que existam no DataFrame
continuas_existentes = [c for c in continuas if c in df.columns]
print(df[continuas_existentes].describe().round(2).to_string())

# %%
# 2.3.5 — Distribuição das variáveis categóricas
print("=" * 76)
print("DISTRIBUIÇÃO — VARIÁVEIS CATEGÓRICAS")
print("=" * 76)
categoricas = [
    'tipo_cliente', 'genero', 'faixa_etaria', 'regiao'
    , 'ramo', 'cobertura', 'nome_canal', 'tipo_canal'
    , 'forma_pagamento'
]
categoricas_existentes = [c for c in categoricas if c in df.columns]
for col in categoricas_existentes:
    print(f"\n--- {col} ---")
    contagem = df[col].value_counts()
    pct = (contagem / len(df) * 100).round(2)
    resumo = pd.DataFrame({'n': contagem, '%': pct})
    print(resumo.to_string())

# %%
# --------------------------------------------------------------------------
# 2.4 — Definição de papéis das colunas
# --------------------------------------------------------------------------

# Colunas de identificação (não entram no modelo, mas são mantidas para rastreio)
COLS_ID = [
    'apolice_id', 'cliente_id', 'produto_id', 'canal_id', 'data_inicio'
]

# Variável resposta
COL_TARGET = 'indicador_churn'

# Variáveis usadas apenas para estratificação (não entram no modelo)
COLS_ESTRATIFICACAO = ['faixa_tempo_casa']

# Variáveis binárias que já são numéricas (não precisam de encoding)
COLS_BINARIAS = [
    'is_fim_semana', 'is_feriado'
    , 'tem_auto', 'tem_vida', 'tem_residencial', 'tem_cross_sell'
]

# Variáveis contínuas
COLS_CONTINUAS = [
    'tempo_cliente_meses', 'premio_medio_mensal', 'franquia_media'
    , 'comissao_percentual', 'vigencia_meses', 'premio_mensal'
    , 'comissao', 'receita_esperada', 'ratio_premio_vs_medio'
    , 'qtd_apolices_acumuladas', 'qtd_ramos_distintos'
    , 'qtd_coberturas_distintas'
]

# Variáveis categóricas (precisarão de encoding)
COLS_CATEGORICAS = [
    'tipo_cliente', 'genero', 'faixa_etaria', 'regiao'
    , 'ramo', 'cobertura', 'nome_canal', 'tipo_canal'
    , 'forma_pagamento'
]

# Variáveis temporais que serão tratadas como categóricas
COLS_TEMPORAIS_CAT = ['mes_inicio', 'trimestre_inicio']

# ano_inicio: pode ser categórica ou contínua, vamos avaliar
COLS_TEMPORAIS_CONT = ['ano_inicio']

# Features totais (tudo que é candidato ao modelo)
COLS_FEATURES = (
    COLS_CONTINUAS
    + COLS_BINARIAS
    + COLS_CATEGORICAS
    + COLS_TEMPORAIS_CAT
    + COLS_TEMPORAIS_CONT
)

print(f"IDs:              {len(COLS_ID)}")
print(f"Target:           1 ({COL_TARGET})")
print(f"Contínuas:        {len(COLS_CONTINUAS)}")
print(f"Binárias:         {len(COLS_BINARIAS)}")
print(f"Categóricas:      {len(COLS_CATEGORICAS)}")
print(f"Temporais (cat):  {len(COLS_TEMPORAIS_CAT)}")
print(f"Temporais (cont): {len(COLS_TEMPORAIS_CONT)}")
print(f"Estratificação:   {len(COLS_ESTRATIFICACAO)}")
print(f"Total features:   {len(COLS_FEATURES)}")

# %%
# --------------------------------------------------------------------------
# 2.5 — Conversão de tipos
# --------------------------------------------------------------------------
# Garante que categóricas sejam string e contínuas sejam float

for col in COLS_CATEGORICAS + COLS_TEMPORAIS_CAT:
    if col in df.columns:
        df[col] = df[col].astype(str)

for col in COLS_CONTINUAS + COLS_TEMPORAIS_CONT:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

for col in COLS_BINARIAS:
    if col in df.columns:
        df[col] = df[col].astype(int)

print("✅ Tipos de dados convertidos.")
print(df[COLS_FEATURES].dtypes.to_string())


# %%
# ==========================================================================
# ETAPA 3 — SEGMENTAÇÃO DA BASE (TREINO 70% / TESTE 30%)
# ==========================================================================

# --------------------------------------------------------------------------
# 3.1 — Construção da chave de estratificação
# --------------------------------------------------------------------------
# Estratificamos por múltiplas variáveis usando iterstrat.
# A biblioteca espera uma matriz binária (multi-label), então
# convertemos cada variável de estratificação em colunas binárias.
#
# Variáveis de estratificação (por ordem de importância):
#   1. indicador_churn
#   2. faixa_tempo_casa
#   3. faixa_etaria
#   4. ramo
#   5. nome_canal
# --------------------------------------------------------------------------

from iterstrat.ml_stratifiers import MultilabelStratifiedShuffleSplit

# Variáveis que queremos preservar na estratificação
vars_estrat = [
    COL_TARGET         # indicador_churn
    , 'faixa_tempo_casa'
    , 'faixa_etaria'
    , 'ramo'
    , 'nome_canal'
]

# Cria matriz binária para cada variável de estratificação
# (cada categoria vira uma coluna 0/1)
estratos_df = pd.get_dummies(df[vars_estrat], columns=vars_estrat)
print(f"Matriz de estratificação: {estratos_df.shape}")
print(f"Colunas: {list(estratos_df.columns)}")

# %%
# --------------------------------------------------------------------------
# 3.2 — Split estratificado 70/30
# --------------------------------------------------------------------------
msss = MultilabelStratifiedShuffleSplit(
    n_splits=1
    , test_size=0.30
    , random_state=42
)

# X pode ser qualquer array do mesmo tamanho; o split usa apenas y (estratos)
X_placeholder = np.zeros((len(df), 1))
y_estratos = estratos_df.values

for train_idx, test_idx in msss.split(X_placeholder, y_estratos):
    idx_treino = train_idx
    idx_teste = test_idx

# Cria as bases
df_treino = df.iloc[idx_treino].copy().reset_index(drop=True)
df_teste = df.iloc[idx_teste].copy().reset_index(drop=True)

print(f"\n{'=' * 60}")
print(f"RESULTADO DO SPLIT")
print(f"{'=' * 60}")
print(f"Base completa: {len(df):,} registros")
print(f"Base treino:   {len(df_treino):,} registros ({len(df_treino)/len(df):.1%})")
print(f"Base teste:    {len(df_teste):,} registros ({len(df_teste)/len(df):.1%})")

# %%
# --------------------------------------------------------------------------
# 3.3 — Validação do split: proporções das variáveis de estratificação
# --------------------------------------------------------------------------
print(f"\n{'=' * 60}")
print(f"VALIDAÇÃO DO SPLIT — PROPORÇÕES")
print(f"{'=' * 60}")

for var in vars_estrat:
    print(f"\n--- {var} ---")
    prop_total = (df[var].value_counts(normalize=True) * 100).round(2)
    prop_treino = (df_treino[var].value_counts(normalize=True) * 100).round(2)
    prop_teste = (df_teste[var].value_counts(normalize=True) * 100).round(2)
    comparacao = pd.DataFrame({
        'Total (%)': prop_total
        , 'Treino (%)': prop_treino
        , 'Teste (%)': prop_teste
    })
    comparacao['Diff (pp)'] = (comparacao['Treino (%)']
                               - comparacao['Teste (%)']).abs().round(2)
    print(comparacao.to_string())

# Validação da taxa de churn
churn_treino = df_treino[COL_TARGET].mean()
churn_teste = df_teste[COL_TARGET].mean()
print(f"\n--- Resumo Churn ---")
print(f"Churn treino: {churn_treino:.4%}")
print(f"Churn teste:  {churn_teste:.4%}")
print(f"Diferença:    {abs(churn_treino - churn_teste):.4%}")

# %%
# --------------------------------------------------------------------------
# 3.4 — Salva as bases para uso nas próximas etapas
# --------------------------------------------------------------------------
# As variáveis COLS_ID, COL_TARGET, COLS_FEATURES e COLS_ESTRATIFICACAO
# ficam disponíveis no escopo do notebook para as etapas seguintes.
# Não salvamos em CSV intermediário — seguimos no mesmo notebook.
# --------------------------------------------------------------------------

print(f"\n✅ Bases prontas para a Etapa 4 (Encoding).")
print(f"   df_treino: {df_treino.shape}")
print(f"   df_teste:  {df_teste.shape}")
print(f"\n   Variáveis de features:        {len(COLS_FEATURES)}")
print(f"   Variáveis de identificação:   {len(COLS_ID)}")
print(f"   Variáveis de estratificação:  {len(COLS_ESTRATIFICACAO)}")