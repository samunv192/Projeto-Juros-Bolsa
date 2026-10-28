# 02_coleta_mercado.R — baixa preços diários das ações das cestas e do Ibovespa (Yahoo Finance)
# Saída: dados/brutos/yahoo_precos_diarios.csv

source("scripts/parametros.R")
library(tidyquant)

# --- Coleta -------------------------------------------------------------
precos <- tq_get(CESTAS$ticker, get = "stock.prices",
                 from = DATA_INICIO, to = DATA_FIM)

write_csv(precos, file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv"))

# --- Checagens ----------------------------------------------------------
# 1) Algum ticker não veio?
sem_dados <- setdiff(CESTAS$ticker, unique(precos$symbol))
if (length(sem_dados) > 0) {
  warning("Tickers sem dados: ", paste(sem_dados, collapse = ", "),
          " — tente rodar de novo ou troque o ativo em parametros.R")
}

# 2) Cobertura de cada ticker: começa no início do período? tem buracos?
cobertura <- precos |>
  group_by(symbol) |>
  summarise(primeira_data = min(date),
            ultima_data   = max(date),
            dias          = n(),
            nas_ajustado  = sum(is.na(adjusted)),
            .groups = "drop") |>
  left_join(CESTAS, by = c("symbol" = "ticker")) |>
  arrange(setor, symbol)

print(cobertura, n = Inf)

# 3) Algum ativo começa bem depois do início? (isso quebraria a média da cesta)
tardios <- cobertura |> filter(primeira_data > DATA_INICIO + 15)
if (nrow(tardios) > 0) {
  warning("Ativos com histórico curto: ", paste(tardios$symbol, collapse = ", "))
}

# O que esperar: todos os 10 tickers, ~245 dias de pregão por ano,
# primeira data no início de dez/2014 e poucos ou nenhum NA.
