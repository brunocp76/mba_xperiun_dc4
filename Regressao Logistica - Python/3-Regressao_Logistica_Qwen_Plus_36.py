# ==========================================
# PASSO 2: Importação e Segmentação Estratificada
# ==========================================

import pandas as pd
import numpy as np
from iterstrat.ml_stratifiers import MultilabelStratifiedShuffleSplit

# 1. Carregar dados exportados do SQLite
df = pd.read_csv('t_modelagem_churn.csv')

# Verificação rápida de tipos e nulos (sanidade)
print(f"📦 Dataset carregado: {df.shape[0]} linhas, {df.shape[1]} colunas.")
print(f"🔹 Colunas numéricas: {df.select_dtypes(include=['number']).shape[1]}")
print(f"🔹 Colunas categóricas: {df.select_dtypes(include=['object']).shape[1]}")
print(f"🔹 Target (Churn): {df['indicador_churn'].sum()} ({df['indicador_churn'].mean()*100:.2f}%)\n")

# 2. Preparar Matriz de Estratificação Multi-Label
# A biblioteca funciona melhor com variáveis binárias (One-Hot Encoded)
# para estratificar por múltiplas categorias simultaneamente.
cols_estrato = ['faixa_tempo_casa', 'faixa_etaria', 'ramo', 'nome_canal', 'indicador_churn']

# Criar dummies apenas para o processo de split (não altera o df original)
df_dummies = pd.get_dummies(df[cols_estrato], columns=cols_estrato, prefix=cols_estrato, prefix_sep='_')

# 3. Realizar a divisão 70/30
# random_state garante reprodutibilidade
msplit = MultilabelStratifiedShuffleSplit(n_splits=1, test_size=0.30, random_state=42)

# A função split retorna os índices
indices_train, indices_test = next(msplit.split(df, df_dummies))

# 4. Criar DataFrames finais
df_train = df.iloc[indices_train].reset_index(drop=True)
df_test = df.iloc[indices_test].reset_index(drop=True)

# 5. Validação da Estratificação
def print_stats(name, df):
    churn_rate = df['indicador_churn'].mean() * 100
    print(f"--- {name} ({len(df)} registros) ---")
    print(f"✅ Churn Rate: {churn_rate:.2f}%")
    print(f"📊 Ramo (Automóvel): {df[df['ramo']=='Automóvel'].shape[0]} | Vida: {df[df['ramo']=='Vida'].shape[0]} | Residencial: {df[df['ramo']=='Residencial'].shape[0]}")
    print(f"📊 Tempo (0-12m): {df[df['faixa_tempo_casa']=='1) 0-12 meses'].shape[0]} | 13-48m: {df[df['faixa_tempo_casa']=='2) 13-48 meses'].shape[0]}")

print("📊 Validação da Amostragem:")
print_stats("BASE TREINO (70%)", df_train)
print_stats("BASE TESTE (30%)", df_test)

# 6. Salvar para os próximos passos (opcional, mas recomendado)
df_train.to_csv('df_train_modelagem.csv', index=False)
df_test.to_csv('df_test_modelagem.csv', index=False)
print("\n💾 Bases salvas em 'df_train_modelagem.csv' e 'df_test_modelagem.csv'.")