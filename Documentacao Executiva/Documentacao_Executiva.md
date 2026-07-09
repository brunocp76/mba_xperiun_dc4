# Documentação Executiva
## Dashboard de Análise de Churn — Seguradora Xperiun
### MBA Xperiun · Data Challenge 4 · Squad 23

---

> **Classificação:** Uso Interno — Gestão Executiva  
> **Data de referência dos dados:** Janeiro/2020 — Setembro/2025  
> **Versão do documento:** 1.1 — Maio/2026 *(revisão após feedback)*  
> **Autores:** Bruno Cesar Pasquini (com suporte de IA)

---

## Sumário Executivo

Este documento descreve o *dashboard* analítico desenvolvido para a **Seguradora Xperiun** com o objetivo de compreender, quantificar e prever o *churn* — o cancelamento voluntário de apólices por parte dos segurados.

O trabalho parte de uma distinção conceitual fundamental, frequentemente ignorada em análises de mercado: **nem todo cancelamento é *churn***. Cancelamentos por falecimento do segurado ou venda do bem protegido são eventos inevitáveis, alheios à atuação da seguradora. Tratá-los como *churn* superestima o problema e distorce as métricas de desempenho.

Com essa correção aplicada, o indicador principal passa de **18,42%** (taxa de cancelamento total) para **16,41%** (taxa de *churn* gerenciável) — uma diferença que altera completamente a leitura do negócio e a priorização das ações de retenção.

---

## 1. Contexto de Negócio

A Seguradora Xperiun comercializa apólices de seguro nos ramos de **Automóvel**, **Vida** e **Residencial**, com três níveis de cobertura (**Básica**, **Completa** e **Premium**) e vigências de **6**, **12** ou **24 meses**. A distribuição é realizada por quatro tipos de canais: **Corretor**, **Digital**, **Direto** e **Parceria**.

O *churn* representa um problema multidimensional para a seguradora:

1. **Financeiro:** perda da receita futura esperada do contrato
2. **Operacional:** o custo de comissão de venda já foi desembolsado e não é recuperável
3. **Estratégico:** clientes perdidos podem migrar para concorrentes, reduzindo participação de mercado

---

## 2. Arquitetura de Dados

### 2.1 Modelo de Dados (Star Schema)

O modelo segue a arquitetura **estrela** (*Star Schema*), com uma tabela fato central e cinco dimensões:

```
          dProduto ──┐
            dCanal ──┤
    dCalendario ─────┼── fApolice ◄── fMetaMensal
  dCliente ──────────┘
```

| Tabela | Tipo | Registros | Descrição |
|--------|------|----------:|-----------|
| `fApolice` | Fato principal | 120.000 | Apólices emitidas — coração do modelo |
| `dCliente` | Dimensão | 24.799 | Perfil demográfico e comportamental dos segurados |
| `dProduto` | Dimensão | 9 | Ramos, coberturas e parâmetros atuariais |
| `dCanal` | Dimensão | 6 | Canais de venda e percentuais de comissão |
| `dCalendario` | Dimensão temporal | 2.100 | Calendário diário com indicadores de feriados |
| `fMetaMensal` | Fato secundário | 69 | Metas mensais de apólices, receita e churn |
| `tModeloRegressao` | Tabela auxiliar | 9 | Coeficientes do modelo de Regressão Logística |
| `tDecisModelo` | Tabela auxiliar | 10 | Curva de ganho (Lift) por decil de score |
| `pVigencia` | Parâmetro | 3 | Slicer de vigência para simulações |
| `pCorteChurn` | Parâmetro | 101 | Slicer de corte de churn para o simulador |
| `pWaterfall` | Parâmetro | 4 | Estrutura do gráfico de cascata |
| `_Medidas` | Auxiliar | — | 155 medidas DAX organizadas em 9 pastas |

### 2.2 Qualidade dos Dados

Duas inconsistências foram identificadas e tratadas antes da análise:

- **4 registros** com `data_cancelamento < data_inicio` (cancelamento anterior à emissão) — corrigidos no Power Query para `dias_ate_churn = 0`
- **Clientes Pessoa Jurídica** com campo `gênero` preenchido — corrigido no SQL para `'Não Informado'` (PJ não possui gênero físico)

---

## 3. Definições Conceituais Fundamentais

### 3.1 Taxonomia de Cancelamentos

| Conceito | Definição | Métrica Principal |
|---------|-----------|-------------------|
| **Cancelamento** | Encerramento de qualquer apólice por qualquer motivo | `Taxa Cancelamento %` = 18,42% |
| ***Churn*** **Gerenciável** | Cancelamento por motivo evitável: preço, atendimento, concorrência, necessidade | `Taxa Churn %` = **16,41%** |
| ***Churn*** **Estrutural** | Cancelamento inevitável: falecimento ou venda do bem segurado | `Taxa Churn Estrutural %` = 2,00% |

> **Por que essa distinção importa:** a taxa de cancelamento total (18,42%) supera a meta média mensal de *churn*, criando uma falsa percepção de desempenho crítico. Ao isolar o *churn* gerenciável (16,41%), o indicador fica abaixo da meta — o que muda radicalmente o diagnóstico e a urgência das ações.

### 3.2 Vocabulário de Medidas

| Termo | O que mede |
|-------|-----------|
| **Receita Esperada** | Valor total contratado (prêmio × vigência) — potencial máximo sem cancelamentos |
| **Receita Realizada** | Valor efetivamente recebido (prêmio × parcelas pagas) |
| **Receita Líquida** | Receita Realizada − Comissão paga ao canal |
| **Gap Receita** | Perda financeira por *churn* gerenciável: R$ 71,7M |
| **Gap Cancelamento** | Perda financeira por todos os cancelamentos: R$ 75,6M |
| **CAC** | Custo de Aquisição de Cliente — proxy: comissão de venda |
| **LTV Contratado** | Valor potencial médio por apólice: R$ 3.208 |
| **LTV Realizado** | Valor efetivo médio por apólice: R$ 2.577 |

---

## 4. Indicadores Globais da Carteira

*Período: Janeiro/2020 a Setembro/2025*

### 4.1 Volume e Composição

| Indicador | Valor |
|-----------|------:|
| Total de apólices | 119.996 |
| Clientes únicos | 24.799 |
| Apólices ativas (carteira viva) | 19.561 |
| Apólices vencidas (sem renovação) | 77.927 |
| Apólices canceladas — *churn* | 19.693 |
| Apólices canceladas — estrutural | 2.406 |
| Apólices suspensas (inadimplência — ver nota) | 410 |

### 4.2 Financeiro

| Indicador | Valor |
|-----------|------:|
| Receita Esperada | R$ 384.911.883 |
| Receita Realizada | R$ 309.272.869 |
| Receita Líquida (após comissões) | R$ 276.136.274 |
| Margem Líquida | **89,29%** |
| Gap Receita (*churn* gerenciável) | R$ 71.666.979 |
| Gap Cancelamento (total) | R$ 75.639.014 |
| Comissão Total Paga | R$ 33.136.595 |
| CAC Perdido em *Churn* | R$ 2.782.092 |
| CAC Perdido em Cancelamentos | R$ 3.125.171 |
| Payback do CAC | **1,1 meses** |

### 4.3 Churn

| Indicador | Valor |
|-----------|------:|
| Taxa de Cancelamento (total) | 18,42% |
| **Taxa de *Churn* Gerenciável** | **16,41%** |
| Taxa de *Churn* Estrutural | 2,00% |
| Proporção do *churn* que é evitável | **89,12%** |
| Dias médios até o cancelamento | 196 dias |
| Destruição de valor por apólice | R$ 631 (19,7% do LTV contratado) |

### 4.4 Waterfall Financeiro

```
Receita Esperada         R$ 384,9M
  − Gap Estrutural            R$ 4,0M   (cancelamentos inevitáveis — 1,0%)
  − Gap Churn              R$ 71,7M   (cancelamentos gerenciáveis — 18,6%)
= Receita Realizada      R$ 309,3M
  − Comissão Paga          R$ 33,1M   (custo de distribuição — 10,7%)
= Receita Líquida        R$ 276,1M
```

---

## 5. Análise por Dimensão de Negócio

### 5.1 Canal de Distribuição

O canal é o principal fator diferenciador de risco e rentabilidade na carteira:

| Canal | Margem Líquida | Taxa *Churn* | Payback CAC | Score Risco |
|-------|---------------|-------------|-------------|-------------|
| **Digital** | 95,0% | Alto | 0,5 meses | 🔴 Alto |
| **Direto** | 92,0% | Médio | 0,9 meses | 🟡 Médio |
| **Corretor** | 86,3% | Médio-baixo | 1,5 meses | 🟡 Médio |
| **Parceria** | 82,0% | Alto | 1,9 meses | 🔴 Alto |

> **Insight estratégico:** o canal Digital combina a maior margem com o maior *churn* — clientes adquiridos digitalmente cancelam com a mesma facilidade com que contratam. O canal Corretor, apesar da menor margem, funciona como camada de retenção natural pelo relacionamento humano.

### 5.2 Ramo de Seguro

| Ramo | Taxa *Churn* Evitável | Gap Receita | Receita em Risco |
|------|----------------------|------------|-----------------|
| **Automóvel** | 16,86% | R$ 57,3M (80%) | R$ 13,2M |
| **Residencial** | 16,37% | R$ 5,4M (8%) | R$ 1,2M |
| **Vida** | 15,69% | R$ 9,0M (13%) | R$ 1,9M |

Automóvel concentra **80%** do Gap de receita evitável, tornando-o a prioridade máxima para ações de retenção.

### 5.3 Vigência do Contrato

| Vigência | Taxa de Cancelamento | Observação |
|----------|---------------------|-----------|
| 6 meses | 19,53% | Maior risco — menor comprometimento |
| 12 meses | 18,61% | Perfil mediano |
| **24 meses** | **16,75%** | Menor risco — maior comprometimento |

Contratos mais longos estão associados a clientes com maior fidelidade. Incentivar a migração de apólices semestrais para anuais ou bianuais é uma alavanca de retenção de baixo custo.

### 5.4 Apólices Suspensas — Inadimplência, não Intenção de Cancelar

410 apólices (0,34% da carteira) estão suspensas — cobrança interrompida por falha no pagamento. É uma categoria distinta do *churn* voluntário: enquanto o *churn* gerenciável reflete uma **decisão do cliente** de encerrar o contrato, a suspensão frequentemente reflete uma **incapacidade financeira pontual** — sem necessariamente haver intenção de cancelar. O perfil dos dados confirma essa hipótese:

| Indicador | Suspensas | Ativas | Diferença |
|-----------|----------:|-------:|----------:|
| Adimplência de parcelas | 36,2% | 47,4% | **−11,2 p.p.** |
| Parcelas pagas (média) | 5,6 | 7,1 | −1,5 parcelas |
| Receita em risco | **R$ 993.641** | — | — |

Forma de pagamento dominante: **Cartão de Crédito (38%)** — recusas técnicas de cobrança por limite esgotado ou cartão cancelado são a causa mais provável. A recomendação para esse grupo é de **recuperação proativa** (contato para atualização de dados de pagamento ou renegociação), diferente das ações de retenção voltadas ao *churn* voluntário. Se não regularizados, esses contratos tendem a evoluir para cancelamento formal — mas a origem do problema é financeira, não de insatisfação com o produto.

---

## 6. Simulador de Carteira Filtrada

O *dashboard* inclui uma funcionalidade de simulação que responde à pergunta estratégica: *"Se não vendêssemos para os perfis com churn acima de X%, como ficariam os indicadores da carteira?"* O slicer permite selecionar qualquer ponto de corte entre **0% e 70%** — intervalo que cobre praticamente toda a distribuição real de *churn* por segmento, com apenas casos extremos acima desse limite.

### 6.1 Cenários Ilustrativos

| Corte de *Churn* | Apólices Restantes | Taxa *Churn* Simulada | Gap Receita | CAC Perdido |
|------------------|--------------------|----------------------|------------|------------|
| **Sem corte (total)** | 119.996 (100%) | 16,41% | R$ 71,7M | R$ 2,78M |
| **≤ 20%** | 87.607 (73%) | 13,63% | R$ 52,1M | R$ 2,01M |
| **≤ 10%** | 17.750 (15%) | 7,47% | R$ 9,4M | R$ 265k |

> **Interpretação:** eliminar os segmentos com *churn* acima de 20% reduziria o *churn* em 2,8 p.p. e pouparia R$ 770 mil em CAC perdido anualmente, ao custo de 27% do volume de apólices.

---

## 7. Modelo Preditivo de Risco de Churn

### 7.1 Metodologia e Escolha do Modelo

Foi desenvolvido um modelo de **Regressão Logística** para estimar a probabilidade individual de *churn* gerenciável de cada apólice. A escolha da regressão logística foi deliberada: trata-se de um modelo cujos parâmetros têm **interpretação direta e imediata** — cada coeficiente β se traduz em um Odds Ratio que expressa, em linguagem de negócio, o quanto uma variável aumenta ou reduz as chances de *churn*. Essa transparência é especialmente valiosa em um contexto onde a **explicação do fenômeno** importa tanto quanto a predição, e onde os resultados precisam ser comunicados a gestores não técnicos. O modelo foi construído com rigor estatístico:

- **Base de dados:** ~97.148 apólices (excluindo suspensas, cancelamentos estruturais e apólices com menos de 12 meses de exposição)
- **Divisão:** 70% treino (68.003 obs.) / 30% teste (29.145 obs.), com estratificação multilabel
- **Seleção de variáveis:** consenso de 5 métodos — Análise Bivariada, Lasso (L1), Stepwise Bidirecional, Wald e Boruta
- **Correções estatísticas:** pesos amostrais para desbalanceamento de classes (16% *churn*) e erros-padrão clusterizados por `cliente_id`
- **Ferramenta:** Python 3.12 / statsmodels + scikit-learn

### 7.2 Desempenho do Modelo

| Métrica | Valor | Interpretação |
|---------|------:|---------------|
| AUC-ROC (teste) | **0,6097** | Discriminação moderada — adequada para modelo explicativo com dados anonimizados |
| Pseudo-R² (McFadden) | **2,46%** | Aceitável para modelos de comportamento humano (referência: 2%–40%) |
| Threshold ótimo (F1) | **17%** | Ponto de corte que maximiza o equilíbrio precisão/revocação |
| F1-Score no threshold | 0,3348 | vs. 0,0000 com threshold padrão de 50% |
| Variáveis no modelo | 9 | Das 58 features candidatas |
| Variáveis significantes | 7 (p < 0,05) | Com erros-padrão clusterizados por cliente |

### 7.3 Fatores de Risco — Resultados do Modelo

| Variável | Odds Ratio | p-valor | Sig. | Efeito |
|----------|----------:|--------:|:----:|--------|
| `tempo_cliente_meses` | **0,794** | < 0,001 | *** | ↓ Protege fortemente — clientes mais antigos cancelam menos |
| `cobertura_Premium` | **0,849** | < 0,001 | *** | ↓ Protege — maior investimento no produto gera mais fidelidade |
| `tipo_canal_Corretor` | **0,882** | < 0,001 | *** | ↓ Protege — relacionamento humano retém clientes |
| `vigencia_meses` | **0,958** | < 0,001 | *** | ↓ Protege — contratos mais longos têm menor *churn* |
| `faixa_etaria_36-45` | 0,981 | 0,066 | · | ↓ Tendência protetora — não significante |
| `premio_medio_mensal` | 0,998 | 0,896 | · | Sem efeito relevante — não significante |
| `faixa_etaria_18-25` | **1,093** | < 0,001 | *** | ↑ Risco — instabilidade financeira e menor fidelidade |
| `cobertura_Básica` | **1,108** | < 0,001 | *** | ↑ Risco — menor percepção de valor |
| `tipo_canal_Digital` | **1,137** | < 0,001 | *** | ↑ Risco — facilidade de cancelamento no canal digital |

*Legenda: \*\*\* p < 0,001 &nbsp;|&nbsp; · p ≥ 0,05 (não significante)*

> **Leitura dos Odds Ratios:** OR = 0,794 para `tempo_cliente_meses` significa que, a cada desvio-padrão de aumento no tempo de relacionamento, as *chances* de *churn* são reduzidas em **20,6%**. OR = 1,137 para `tipo_canal_Digital` significa **13,7% a mais de chance de *churn*** comparado ao canal de referência.

### 7.4 Score de Risco na Carteira Atual

Com o modelo calibrado e aplicado às apólices ativas:

| Indicador | Valor |
|-----------|------:|
| Score médio do portfólio | 17,48% |
| Apólices classificadas como **Alto Risco** (score ≥ 17%) | **65.730** (54,78%) |
| Receita em risco nas apólices ativas de Alto Risco | **R$ 17.759.055** |

O threshold de 17% foi definido pela maximização do F1-Score na base de teste. Pode ser ajustado para calibrar o trade-off entre alcance (mais clientes abordados) e precisão (maior certeza de acerto).

### 7.5 Curva de Ganho (Lift por Decil)

Abordando apenas os **10% com maior score** (Decil 10), captura-se aproximadamente o **dobro** da proporção de *churns* reais esperada ao acaso — demonstrando o poder discriminante do modelo para priorizar ações de retenção.

---

## 8. Recomendações Estratégicas

Com base nas análises do *dashboard* e do modelo preditivo:

### 8.1 Prioridades Imediatas

**1. Apólices Suspensas — Recuperação de Inadimplência em 30 dias**
410 apólices com R$ 993.641 em receita imediata em risco por suspensão de cobrança. É importante distinguir esse grupo do *churn* voluntário: a inadimplência que leva à suspensão pode refletir uma dificuldade financeira pontual do cliente — cartão recusado, débito sem saldo, boleto não pago — sem que haja intenção de cancelar. Nesses casos, uma ação ágil de cobrança ou renegociação tem alta probabilidade de recuperação. Cartão de Crédito concentra 38% dos casos, sugerindo recusas técnicas de cobrança como causa principal. A ação recomendada é de **recuperação**, não de retenção.

**2. Carteira de Alto Risco — Campanha de Retenção**
65.730 apólices identificadas pelo modelo com score ≥ 17%, representando R$ 17,8M em receita em risco. Priorizar: canal Digital + cobertura Básica + faixa etária 18–25 anos.

**3. Ramo Automóvel — Foco Principal**
80% do Gap de receita evitável (R$ 57,3M) está concentrado no ramo Auto. Qualquer programa de retenção deve começar aqui.

### 8.2 Alavancas Estruturais

**Migração de contratos semestrais para anuais**
Apólices de 24 meses têm 2,8 p.p. menos *churn* que as de 6 meses. Incentivar contratos mais longos (desconto proporcional, benefícios de fidelidade) pode reduzir o *churn* estruturalmente.

**Revisão da estratégia do canal Digital**
O canal Digital combina maior margem (95%) com maior *churn* — clientes que entram fácil, saem fácil. Considerar mecanismos de engajamento pós-venda no digital (comunicação proativa, facilidade de upgrade de cobertura) para aumentar a percepção de valor.

**Programa de fidelização para clientes recentes (0–12 meses)**
O modelo confirma que clientes com menos tempo de relacionamento têm maior propensão ao *churn*. O payback do CAC é de apenas 1,1 meses — o custo de aquisição é recuperado rapidamente, mas a perda de clientes jovens desperdiça o potencial de LTV dos 23–35 meses restantes.

### 8.3 Próximos Passos Analíticos

**Enriquecimento da base de dados — maior impacto esperado**

A principal alavanca de melhoria do modelo não está na técnica, mas nos **dados disponíveis**. A Seguradora Xperiun certamente possui informações que não estavam presentes nesta base anonimizada e que são preditores relevantes de *churn*:

- **Dados de sinistralidade:** histórico de sinistros por apólice (frequência, valores, tipo). Clientes que nunca acionaram o seguro têm maior propensão ao cancelamento por "não usar / não precisar" — o segundo motivo mais declarado na base. Clientes que acionaram o seguro recentemente e foram bem atendidos, ao contrário, tendem a renovar.
- **Renda do cliente:** variável classicamente associada à sensibilidade a preço e à capacidade de manter o pagamento. Sua ausência limita a análise de segmentos de dificuldade financeira.
- **Idade exata (em vez de faixa etária):** o modelo atual usa faixas de 10 anos; com a idade contínua o modelo capturaria nuances como a diferença entre 18 e 24 anos dentro da mesma faixa.
- **Histórico de contato com o cliente:** número de interações com a central, reclamações registradas, NPS (se disponível) — dados comportamentais que frequentemente precedem o cancelamento.
- **Dados geoeconômicos por UF:** indicadores de desemprego, renda média e penetração do seguro por estado, cruzados com a região do cliente.

Com esses dados adicionais, a **Regressão Logística** continuaria sendo a técnica principal de escolha — mantendo a interpretabilidade dos coeficientes — e provavelmente alcançaria desempenho significativamente superior ao AUC de 0,61 obtido com a base atual.

**Outros aprofundamentos analíticos**

- **Análise de sobrevivência (Kaplan-Meier / Cox):** modelar o *tempo* até o *churn*, e não apenas a probabilidade binária — especialmente útil para definir *quando* acionar a retenção
- **Modelo de propensão à renovação:** as 77.927 apólices vencidas sem renovação representam uma oportunidade de reativação; um modelo específico para esse grupo complementaria o atual
- **Modelos de *ensemble*** (Random Forest, XGBoost): se o objetivo evoluir para maximizar a predição em detrimento da interpretabilidade, esses métodos tendem a superar a regressão logística em AUC — mas ao custo de coeficientes não diretamente interpretáveis

---

## 9. Estrutura do Dashboard

O *dashboard* é composto por páginas temáticas organizadas em fluxo lógico:

| Página | Tema | Principais Visuais |
|--------|------|--------------------|
| Capa | Navegação | Botões de acesso por tema |
| Visão Executiva | KPIs globais | Cards, gráfico temporal, matriz canal × ramo |
| Análise de Churn | Decomposição | Motivos, janelas temporais, ranking de segmentos |
| Receita e Rentabilidade | Financeiro | Waterfall, LTV, margem por canal |
| Gestão da Carteira | Prospectiva | Mapa UF, apólices em janela crítica, suspensas |
| Metas e Atingimento | Performance | Gauges, desvio mensal, YTD |
| Análise Temporal | Tendências | MoM, YoY, médias móveis, rolling 12M |
| Score de Risco | Modelo ML | Forest Plot, tabela de coeficientes, curva de ganho |
| Simulador | What-if | Carteira filtrada por corte de *churn* |

### Medidas DAX — Inventário

| Pasta | Qtd | Exemplos |
|-------|----:|---------|
| 1 · Volume | 18 | `Qtd Apólices`, `Qtd Churns`, `Qtd Clientes` |
| 2 · Receita | 17 | `Receita Líquida`, `LTV Realizado Médio`, `Margem Líquida %` |
| 3 · Churn | 17 | `Taxa Churn %`, `Taxa Cancelamento %`, `Taxa Churn Estrutural %` |
| 4 · Gap e Cancelamentos | 13 | `Gap Receita`, `Gap Cancelamento Estrutural` |
| 5 · Comissão e CAC | 14 | `CAC Perdido Total`, `CAC Eficiência Total x`, `Payback do CAC` |
| 6 · Metas e Atingimento | 11 | `Meta Churn Status`, `Desvio Meta Churn YTD` |
| 7 · Análise Temporal | 29 | `Taxa Churn MoM`, `Receita YoY Δ`, `Taxa Churn Média Móvel 3M %` |
| 8 · Score de Risco | 30 | `Score Risco Churn Segmento %`, `Qtd Apólices Alto Risco Score` |
| 9 · Dashboard | 4 | `Rodapé Dinâmico 1`, `Rodapé Dinâmico 2`, `Momento Último Update` |
| **Total** | **155** | Todas documentadas, organizadas em pastas |

---

## 10. Convenções e Padrões do Modelo

| Elemento | Padrão |
|----------|--------|
| Tabelas fato | Prefixo `f` + PascalCase (`fApolice`, `fMetaMensal`) |
| Tabelas dimensão | Prefixo `d` + PascalCase (`dCliente`, `dProduto`) |
| Tabelas auxiliares | Prefixo `t` + PascalCase (`tModeloRegressao`) |
| Tabelas parâmetro | Prefixo `p` + PascalCase (`pVigencia`, `pCorteChurn`) |
| Tabela de medidas | `_Medidas` (underscore → aparece no topo da lista) |
| Colunas | `snake_case` minúsculo |
| Medidas | `Title Case com espaços` |
| Taxas / percentuais | Sufixo `%` ao final |
| Variações absolutas | Sufixo `Δ` |
| Múltiplos (ROI) | Sufixo `x` |
| Parâmetros internos | Prefixo `_Param` (ocultos) |
| Abreviações temporais | `YTD`, `YoY`, `MoM` |
| KPIs de *churn* | **Churn** = gerenciável | **Cancelamento** = total (inclui estrutural) |

---

## Glossário

| Termo | Definição |
|-------|-----------|
| **AUC-ROC** | Area Under the ROC Curve — medida de discriminação do modelo preditivo (0,5 = aleatório, 1,0 = perfeito) |
| **CAC** | Custo de Aquisição de Cliente — neste modelo, proxy pela comissão de venda paga ao canal |
| **Churn** | Cancelamento voluntário por motivo gerenciável (exclui falecimento e venda do bem) |
| **Churn Estrutural** | Cancelamento inevitável por falecimento do segurado ou venda do bem protegido |
| **Gap de Receita** | Diferença entre receita esperada (contratada) e receita realizada (recebida) |
| **KS** | Kolmogorov-Smirnov — medida da máxima separação entre distribuições de churn e não-churn |
| **Lift** | Razão entre a taxa de churn em um decil e a taxa média global — mede o ganho do modelo sobre o acaso |
| **LTV** | Lifetime Value — valor gerado por uma apólice ao longo da sua vigência |
| **Odds Ratio** | Razão de chances — mede o efeito multiplicativo de uma variável sobre as chances de churn |
| **Payback do CAC** | Número de meses de prêmio necessários para recuperar a comissão de aquisição |
| **Pseudo-R²** | Medida de ajuste do modelo logístico (≠ R² da regressão linear) |
| **Rolling 12M** | Média deslizante dos últimos 12 meses — elimina sazonalidade |
| **Score** | Probabilidade prevista de churn para cada apólice, calculada pelo modelo logístico |
| **Star Schema** | Arquitetura de dados com tabela fato central e dimensões ao redor |
| **Threshold** | Ponto de corte do score (17%) acima do qual uma apólice é classificada como Alto Risco |
| **YoY** | Year over Year — variação em relação ao mesmo período do ano anterior |
| **YTD** | Year to Date — acumulado desde o início do ano |

---

*Documento gerado com base em análise direta do modelo semântico — MBA Xperiun · Data Challenge 4 · Abril/2026*
