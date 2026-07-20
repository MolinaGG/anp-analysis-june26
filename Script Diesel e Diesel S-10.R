# =============================================================================
# 01_treinar_e_exportar.R
# Pipeline de treino: carrega dados da ANP, treina dois modelos de classificação
# (Árvore de Decisão e Rede Neural MLP), avalia e exporta tudo para o Quarto.
# =============================================================================

library(tidymodels)
library(tidyverse)
library(janitor)

tidymodels_prefer()  # Resolve conflitos de funções entre tidymodels e outros pacotes
set.seed(123)        # Garante reprodutibilidade em todo o pipeline

# =============================================================================
# CORREÇÃO DE DIRETÓRIO
# Aponta o R para a pasta onde está o anp.csv e onde serão salvos os modelos
# =============================================================================
setwd("C:/Users/guilh/OneDrive/Documentos/Projetos em R/Projeto combustíveis")

cat("📁 Diretório:", getwd(), "\n")
cat("📄 anp.csv encontrado:", file.exists("anp.csv"), "\n")

dir.create("modelos", showWarnings = FALSE)  # Cria pasta de saída se não existir

# =============================================================================
# BLOCO 1 — CARREGAMENTO E LIMPEZA DOS DADOS
# Lê o CSV com encoding Latin1 (padrão ANP) e separador ponto-e-vírgula (csv2)
# clean_names() padroniza nomes: minúsculas, sem espaços/acentos
# =============================================================================
dados_brutos <- read_csv2(
  "anp.csv",
  locale = locale(encoding = "Latin1", decimal_mark = ","),
  show_col_types = FALSE
) %>%
  clean_names()

# =============================================================================
# BLOCO 2 — TRANSFORMAÇÃO DOS DADOS
# CORREÇÃO: coluna de região veio duplicada no CSV original, clean_names()
# a renomeou para regiao_sigla_1 (primeira ocorrência) e regiao_sigla_17 (segunda)
# Filtra apenas DIESEL e DIESEL S10, cria variável-alvo 'classe_preco'
# =============================================================================
dados_anp <- dados_brutos %>%
  rename(
    regiao       = regiao_sigla_1,   # ← corrigido: era regiao_sigla
    estado       = estado_sigla,
    produto      = produto,
    bandeira     = bandeira,
    valor_venda  = valor_de_venda,
    valor_compra = valor_de_compra
  ) %>%
  filter(produto %in% c("DIESEL", "DIESEL S10")) %>%  # Mantém só os dois tipos de diesel
  mutate(
    valor_venda  = as.numeric(valor_venda),   # Garante tipo numérico
    valor_compra = as.numeric(valor_compra)
  ) %>%
  group_by(estado, produto) %>%
  mutate(
    # Mediana de preço de venda por estado e tipo de diesel
    mediana_estado_produto = median(valor_venda, na.rm = TRUE),

    # Variável-alvo: "Acima" se o posto cobra mais que a mediana do estado
    classe_preco = factor(
      if_else(valor_venda > mediana_estado_produto, "Acima", "Abaixo"),
      levels = c("Acima", "Abaixo")  # "Acima" é o evento positivo
    )
  ) %>%
  ungroup() %>%
  select(classe_preco, regiao, estado, produto, bandeira, valor_compra, valor_venda) %>%
  drop_na(classe_preco)  # Remove linhas sem classe definida

cat("✅ Dados carregados:", nrow(dados_anp), "linhas\n")

# =============================================================================
# BLOCO 3 — DIVISÃO DOS DADOS
# 75% treino / 25% teste, estratificado para manter proporção das classes
# =============================================================================
dados_split  <- initial_split(dados_anp, prop = 0.75, strata = classe_preco)
dados_treino <- training(dados_split)
dados_teste  <- testing(dados_split)

# Validação cruzada com 5 folds para tuning dos hiperparâmetros
dados_folds <- vfold_cv(dados_treino, v = 5, strata = classe_preco)

cat("✅ Treino:", nrow(dados_treino), "| Teste:", nrow(dados_teste), "\n")

# =============================================================================
# BLOCO 4 — RECEITA DE PRÉ-PROCESSAMENTO
# Define as transformações aplicadas antes de entrar nos modelos
# =============================================================================
receita_combustivel <- recipe(
  classe_preco ~ regiao + estado + produto + bandeira + valor_compra,
  data = dados_treino
) %>%
  step_impute_median(valor_compra) %>%           # Imputa mediana onde valor_compra for NA
  step_novel(all_nominal_predictors()) %>%        # Trata categorias novas no teste
  step_unknown(all_nominal_predictors()) %>%      # Substitui NAs categóricos por "unknown"
  step_dummy(all_nominal_predictors()) %>%        # Converte categorias em dummies (0/1)
  step_zv(all_predictors()) %>%                   # Remove preditores constantes
  step_range(all_numeric_predictors(), min = 0, max = 1)  # Normaliza numéricos para [0,1]

# =============================================================================
# BLOCO 5 — ESPECIFICAÇÃO DOS MODELOS
# =============================================================================

# Modelo 1: Árvore de Decisão (engine: rpart)
espec_tree <- decision_tree(
  tree_depth      = tune(),   # Profundidade máxima da árvore
  min_n           = tune(),   # Mínimo de obs. para dividir um nó
  cost_complexity = tune()    # Parâmetro de poda: maior = árvore mais simples
) %>%
  set_engine("rpart") %>%
  set_mode("classification")

# Modelo 2: Rede Neural MLP (engine: nnet)
espec_nnet <- mlp(
  hidden_units = tune(),  # Neurônios na camada oculta
  penalty      = tune(),  # Regularização L2 (evita overfitting)
  epochs       = tune()   # Número de iterações de treino
) %>%
  set_engine("nnet") %>%
  set_mode("classification")

# =============================================================================
# BLOCO 6 — WORKFLOWS
# Une receita + modelo em um objeto único para o pipeline de tuning
# =============================================================================
wf_tree <- workflow() %>% add_recipe(receita_combustivel) %>% add_model(espec_tree)
wf_nnet <- workflow() %>% add_recipe(receita_combustivel) %>% add_model(espec_nnet)

# =============================================================================
# BLOCO 7 — MÉTRICAS E GRIDS DE HIPERPARÂMETROS
# =============================================================================
metricas <- metric_set(roc_auc, accuracy, f_meas)

# Grid regular: testa combinações em grade
grid_tree <- grid_regular(
  cost_complexity(),
  tree_depth(),
  min_n(),
  levels = 4   # 4³ = 64 combinações
)

grid_nnet <- grid_regular(
  hidden_units(range = c(2, 10)),
  penalty(),
  epochs(range = c(50, 200)),
  levels = 3   # 3³ = 27 combinações
)

# =============================================================================
# BLOCO 8 — TUNING
# Testa os hiperparâmetros nos folds de validação cruzada
# ⚠️ Este bloco é o mais demorado — normal levar vários minutos
# =============================================================================
cat("⏳ Iniciando tuning da Árvore de Decisão...\n")
tune_tree <- tune_grid(
  wf_tree,
  resamples = dados_folds,
  grid      = grid_tree,
  metrics   = metricas
)

cat("⏳ Iniciando tuning da Rede Neural...\n")
tune_nnet <- tune_grid(
  wf_nnet,
  resamples = dados_folds,
  grid      = grid_nnet,
  metrics   = metricas
)

# Seleciona a melhor combinação de hiperparâmetros pelo ROC-AUC médio nos folds
melhor_tree <- select_best(tune_tree, metric = "roc_auc")
melhor_nnet <- select_best(tune_nnet, metric = "roc_auc")

# Substitui tune() pelos valores ótimos encontrados
wf_tree_final <- finalize_workflow(wf_tree, melhor_tree)
wf_nnet_final <- finalize_workflow(wf_nnet, melhor_nnet)

# Treina os modelos finais com todos os dados de treino
cat("⏳ Treinando modelos finais...\n")
fit_tree <- fit(wf_tree_final, data = dados_treino)
fit_nnet <- fit(wf_nnet_final, data = dados_treino)

cat("✅ Modelos treinados!\n")

# =============================================================================
# BLOCO 9 — AVALIAÇÃO NO CONJUNTO DE TESTE
# Dados de teste nunca foram vistos pelos modelos durante o treino
# =============================================================================

# Probabilidades preditas para a classe "Acima" (usadas no ROC-AUC)
pred_tree <- predict(fit_tree, dados_teste, type = "prob") %>%
  select(pred_tree_Acima = .pred_Acima)

pred_nnet <- predict(fit_nnet, dados_teste, type = "prob") %>%
  select(pred_nnet_Acima = .pred_Acima)

# Classes preditas (usadas em accuracy e F1)
classe_tree <- predict(fit_tree, dados_teste, type = "class") %>%
  rename(classe_tree = .pred_class)

classe_nnet <- predict(fit_nnet, dados_teste, type = "class") %>%
  rename(classe_nnet = .pred_class)

# Consolida: classe real + probabilidades + classes preditas dos dois modelos
resultados_teste <- dados_teste %>%
  select(classe_preco) %>%
  bind_cols(pred_tree, pred_nnet, classe_tree, classe_nnet)

# Calcula métricas finais
auc_tree <- roc_auc(resultados_teste, truth = classe_preco, pred_tree_Acima, event_level = "first")
auc_nnet <- roc_auc(resultados_teste, truth = classe_preco, pred_nnet_Acima, event_level = "first")
acc_tree <- accuracy(resultados_teste, truth = classe_preco, estimate = classe_tree)
acc_nnet <- accuracy(resultados_teste, truth = classe_preco, estimate = classe_nnet)
f1_tree  <- f_meas(resultados_teste,  truth = classe_preco, estimate = classe_tree,  event_level = "first")
f1_nnet  <- f_meas(resultados_teste,  truth = classe_preco, estimate = classe_nnet,  event_level = "first")

# Tabela-resumo comparativa
tabela_resumo <- tibble(
  modelo   = c("Árvore de Decisão", "Rede Neural (MLP)"),
  roc_auc  = c(auc_tree$.estimate, auc_nnet$.estimate),
  accuracy = c(acc_tree$.estimate, acc_nnet$.estimate),
  f1_score = c(f1_tree$.estimate,  f1_nnet$.estimate)
)

print(tabela_resumo)

# =============================================================================
# BLOCO 10 — EXPORTAÇÃO
# Salva todos os objetos como .rds para o relatório Quarto + Shiny
# carregar sem precisar retreinar
# =============================================================================
saveRDS(fit_tree,         "modelos/fit_tree.rds")          # Modelo árvore treinado
saveRDS(fit_nnet,         "modelos/fit_nnet.rds")          # Modelo rede neural treinado
saveRDS(dados_anp,        "modelos/dados_anp.rds")         # Base completa (exploração Shiny)
saveRDS(dados_teste,      "modelos/dados_teste.rds")       # Dados de teste
saveRDS(resultados_teste, "modelos/resultados_teste.rds")  # Predições consolidadas
saveRDS(tabela_resumo,    "modelos/tabela_resumo.rds")     # Tabela de métricas

cat("\n✅ Arquivos salvos em ./modelos/ — prontos para o relatorio_combustivel.qmd\n")