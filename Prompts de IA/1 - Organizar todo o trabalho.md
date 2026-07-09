## Contexto

Tenho o desafio de produzir um material de *BI* (*Business Intelligence*) de nível profissional, como parte de uma pós-graduação que estou cursando.

O contexto é o de uma seguradora precisando compreender o *churn* (ou cancelamento voluntário) de seus clientes nos produtos de seguro de automóvel, seguro de vida e seguro residencial. Mesmo que a seguradora suspenda a cobertura, houve uma despesa com o desembolso da comissão de vendas e existe também a possibilidade do cliente deixar de pagar para ir para algum concorrente. Então a seguradora precisa reduzir ao máximo o *churn*.

Pensei em **construir um modelo de regressão logística** para explicar o *churn*, mas preciso começar pelo *BI* antes de seguir para o *machine learning*.

Propositalmente, a descrição da tarefa é ambígua, para refletir a realidade dos projetos de *BI*.

Esta ambiguidade dá à tarefa uma vasta gama de caminhos possíveis, caminhos estes que eu poderia seguir sozinho. Ao invés disso...

Agindo como um Desenvolvedor de BI altamente experiente, você vai me ajudar a encontrar o melhor caminho para realizar a tarefa no menor tempo possível, mantendo a mais alta qualidade. A tarefa inclui análises em SQLite, a produção de um dashboard no Power BI e a confecção de uma documentação e uma apresentação executivas. Todas de altíssimo nível.

## Contexto


## Requisição

Organizei a tarefa em partes menores para garantir que cada parte seja tratada adequada e sequencialmente. Esta abordagem passo-a-passo foi pensada para lidar com as dependências entre as partes, gerenciar limites de tempo devido aos planos de consumo de IA e para garantir que não deixemos de lado nenhum detalhe importante. 

Primeiramente, você deve apresentar sugestões. Em seguida, conversaremos a respeito. Por fim, você irá executar as ações que puder à medida em que eu a instruir.

Eu preciso que você execute nesta ordem:

### **0**. Confirme se este prompt está claro ou me faça perguntas enquanto não estiver.

### **1**. Apresente uma primeira lista com 80 hipóteses de negócio que podem estar levando ao *churn* nos produtos de seguro de automóvel, seguro de vida e seguro residencial com base na minha descrição do contexto. Ordene estas hipóteses pela facilidade de testá-las e pela relevância das mesmas. Salve-as em formato Markdown, utilizando a vasta gama de recursos de formatação para documentá-las.

### **2**. Faça uma pesquisa extensa na internet (inclusive em outras línguas) para procurar algum conhecimento externo sobre os motivos que podem levar ao *churn* nestes produtos específicos de seguros. Não me preocupo se esta etapa demorar mais. Organize o material que encontrar e salve este conteúdo organizado em formato PDF.

### **3**. Refine a primeira lista de hipóteses de negócio com base neste conhecimento pesquisado, gerando uma segunda lista de hipóteses com 60 hipóteses de negócio, as mais plausíveis de acordo com a pesquisa que você fez. Ordene estas hipóteses pela facilidade de testá-las e pela relevância das mesmas. Salve-as em formato Markdown, no mesmo alto padrão anterior.

### **4**. Solicite as informações de contexto fornecidas para o meu desafio para refinarmos mais nosso caminho. Espere eu colar as instruções e, com elas, me ajude a refinar o contexto e, através dele, o nosso caminho ótimo.

### **5**. A esta altura, entendendo melhor o contexto, refine a segunda lista de hipóteses de negócio, gerando uma terceira lista de hipóteses com 40 hipóteses de negócio, as mais plausíveis de acordo com a pesquisa que você fez e com o contexto adicional que eu terei fornecido. Ordene estas hipóteses pela facilidade de testá-las e pela relevância das mesmas. Salve-as em formato Markdown, no mesmo padrão anterior.

### **6**. Solicite a estrutura de dados (do banco SQLite) através da DDL (Data Definition Language) e do arquivo DBML dos dados que eu tenho à disposição. Me questione acerca de alguns "grandes números", para entender a "extensão" dos dados que tenho para análise. Entenda os dados disponíveis e considere como eles afetam o caminho que iremos trilhar.

### **7**. A esta altura, sabendo o que temos em termos de dados disponíveis, refine a terceira lista de hipóteses de negócio, gerando uma quarta lista de hipóteses com 20 hipóteses de negócio, as mais plausíveis de acordo com a pesquisa que você fez, com o contexto adicional que eu terei fornecido e com a estrutura dos dados disponíveis para análise. Ordene estas hipóteses pela facilidade de testá-las e pela relevância das mesmas. Salve-as em formato Markdown, no mesmo padrão anterior.

### **8**. Solicite os dados existentes em formato CSV (uma extração das tabelas do SQL). Me estabeleça uma ordem de relevância dos arquivos a terem o upload feito, de acordo com o que foi analisado até aqui. Eu vou fazer o upload dos arquivos até o seu limite de arquivos para upload, e aí peço que faça uma análise abrangente dos dados. Me liste as coisas que chamam a sua atenção pela ordem de relevância que você escolher. Considere também as listas de hipóteses de negócios que você produziu. Me aponte as análises que sejam mais relevantes/impactantes para fazermos via SQLite e aquelas que sejam mais relevantes/impactantes para fazermos no Power BI (sejam análises diferentes ou o aprofundamento/visualização das análises realizadas no SQLite). Salve-as em formato Markdown, no mesmo padrão anterior.

### **9**. Com base em todo o conhecimento adquirido, pesquisado, conversado e estudado, me aponte o caminho ótimo que respeite o que me está sendo pedido e que me permita produzir, no menor tempo e com a maior qualidade possíveis, os materiais que respondam à necessidade da seguradora entender e reduzir o *churn* nos produtos de seguro de automóvel, seguro de vida e seguro residencial. Mais uma vez, salve as etapas sugeridas em formato Markdown, no mesmo padrão anterior.

### **10**. Mesmo o caminho podendo mudar conforme construo as análises no SQLite e no Power BI, me apresente uma sugestão de variáveis para um modelo de regressão logística para explicar os motivos do *churn*, ordenada pela relevância esperada. Se conseguir entregar este modelo de regressão logística, este trabalho terá um nível adicional de excelência.

## Requisição


## Entradas

As entradas serão fornecidas de acordo com os passos da seção **Requisição**.

A entrada 1 é o contexto fornecido.

A entrada 2 é a sua pesquisa exaustiva na internet.

A entrada 3 é a descrição da tarefa. Eu tenho tanto um texto Markdown com a descrição da tarefa quanto a transcrição em texto de um datacast.

A entrada 4 é a estrutura dos dados no banco SQLite e alguns "grandes números" acerca dos dados disponíveis para análise.

A entrada 5 são os dados exportados para formato CSV.

## Entradas


## Entregáveis

As entregas deverão ser fornecidas sequencialmente de acordo com os passos descritos na seção **Requisição**.

A conversa que teremos será um entregável valioso ao longo do processo.

Várias listas de hipóteses de negócios e um caminho ótimo de análise deverão ser fornecidas em formato Markdown.

Um conhecimento pesquisado na internet deverá ser fornecido em formato PDF.

## Entregáveis


## Limites

Como estes dados foram anonimizados você está *livre* para usá-los para treinamento de futuras versões de si mesma.

Outros limites serão os que eu descrever ao longo do diálogo.

**Importante**: Gosto muito de detalhes e tento ser o mais detalhado para fornecer o máximo de contexto, mas é imperativo que as suas respostas (a não ser nos arquivos de saída exportáveis), sejam o mais claro possíveis e, sendo claros, que economizem tokens, sem perder a clareza.
Por exemplo, se for a correção de alguma coisa, não precisa colocar novamente a parte que está com erro para depois colocar a parte corrigida. Mas precisa manter a clareza de qualquer jeito.
Pode me confirmar que este esforço em economizar tokens sem perder a clareza está bastante claro?

## Limites


## Avaliação

Embora eu admire e respeite sua capacidade de raciocínio, eu espero que você confirme todas as pressuposições que você assuma, toda vez que assumir uma ou mais delas.

Eu espero que você reprocesse todas as sugestões duas vezes antes de apresentá-las a mim.

Sempre considere os limites dos dados e os limites que é possível fazer tanto no SQLite quanto no Power BI.

## Avaliação


Muito obrigado.