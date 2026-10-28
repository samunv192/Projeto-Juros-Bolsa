# 04_validacao.R — confere se a base mensal está pronta para a análise
# Entrada: dados/tratados/base_mensal.csv e retornos_ativos_mensal.csv

source("scripts/parametros.R")

base   <- read_csv(file.path(PASTA_TRATADOS, "base_mensal.csv"),            show_col_types = FALSE)
ativos <- read_csv(file.path(PASTA_TRATADOS, "retornos_ativos_mensal.csv"), show_col_types = FALSE)

falhas <- 0
checar <- function(ok, msg) {
  cat(if (ok) "  OK    " else "  FALHA ", msg, "\n")
  if (!ok) falhas <<- falhas + 1
}

cat("\n=== Checagens da base mensal ===\n")

meses_esperados <- seq(min(base$mes), max(base$mes), by = "month")
checar(nrow(base) == length(meses_esperados) && all(base$mes == meses_esperados),
       "meses consecutivos, sem buracos nem repetições")

checar(!anyNA(base), "nenhum valor ausente em nenhuma coluna")

n_por_mes <- ativos |> filter(setor != "mercado", !is.na(ret)) |> count(mes)
checar(nrow(n_por_mes) == nrow(base) && all(n_por_mes$n == 9),
       "as 9 ações têm retorno em todos os meses")

rets <- base |> select(starts_with("ret_")) |> unlist()
checar(all(abs(rets) < 60), "retornos mensais de setores e Ibovespa abaixo de 60% em módulo")

checar(all(between(base$selic, 1, 20)), "Selic sempre entre 1% e 20% a.a.")
checar(all(between(base$ipca, -2, 3)), "IPCA mensal sempre entre -2% e 3%")
checar(all(base$ciclo %in% c("alta", "queda")), "ciclo definido em todos os meses")

# --- Resumo --------------------------------------------------------------
cat("\n=== Resumo ===\n")
cat("  Período:", format(min(base$mes), "%m/%Y"), "a", format(max(base$mes), "%m/%Y"),
    "|", nrow(base), "meses\n")
cat("  Meses com mudança da Selic:", sum(base$delta_selic != 0), "\n")
print(count(base, ciclo, name = "meses"))

cat("\n  Retorno mensal (%) por série:\n")
base |>
  summarise(across(starts_with("ret_"),
                   list(media = mean, desvio = sd, min = min, max = max))) |>
  pivot_longer(everything(), names_to = c("serie", ".value"),
               names_pattern = "ret_(.*)_(media|desvio|min|max)") |>
  mutate(across(where(is.numeric), \(x) round(x, 2))) |>
  print()

# Movimentos individuais muito grandes não são erro, mas vale conferir e citar no relatório
extremos <- ativos |> filter(abs(ret) > 30) |> arrange(desc(abs(ret))) |>
  select(symbol, setor, mes, ret)
if (nrow(extremos) > 0) {
  cat("\n  Meses com retorno individual acima de 30% em módulo (conferir):\n")
  print(extremos, n = Inf)
}

cat("\n")
if (falhas == 0) cat("Base validada: pronta para a análise.\n") else
  warning(falhas, " checagem(ns) falharam — veja as linhas marcadas com FALHA acima.")
