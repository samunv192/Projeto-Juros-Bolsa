# 03_base_mensal.R — transforma os dados brutos na base mensal do projeto
# Entradas: dados/brutos/*.csv   (gerados pelos scripts 01 e 02)
# Saídas:   dados/tratados/base_mensal.csv (e .rds)       -> 1 linha por mês
#           dados/tratados/retornos_ativos_mensal.csv    -> 1 linha por ação por mês

source("scripts/parametros.R")

# --- 0. Leitura dos dados brutos ----------------------------------------
selic_d <- read_csv(file.path(PASTA_BRUTOS, "bcb_selic_meta.csv"),    show_col_types = FALSE)
ipca_d  <- read_csv(file.path(PASTA_BRUTOS, "bcb_ipca.csv"),          show_col_types = FALSE)
precos  <- read_csv(file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv"), show_col_types = FALSE)

# --- 1. Janela da base ---------------------------------------------------
# Primeiro mês: jan/2015 (dez/2014 só serve para calcular o primeiro retorno).
# Último mês: o último mês COMPLETO que também já tem IPCA divulgado.
PRIMEIRO_MES <- floor_date(DATA_INICIO, "month") %m+% months(1)
ULTIMO_MES   <- min(floor_date(DATA_FIM, "month") %m-% months(1),
                    floor_date(max(ipca_d$date), "month"))

# --- 2. Selic mensal: valor da meta no último dia do mês -----------------
selic_m <- selic_d |>
  arrange(date) |>
  mutate(mes = floor_date(date, "month")) |>
  group_by(mes) |>
  summarise(selic = dplyr::last(selic_meta), .groups = "drop") |>
  mutate(
    delta_selic = selic - dplyr::lag(selic),          # variação no mês, em p.p.
    ciclo = case_when(delta_selic > 0 ~ "alta",       # direção do último movimento do Copom
                      delta_selic < 0 ~ "queda")
  ) |>
  fill(ciclo, .direction = "downup") |>               # meses sem mudança herdam o ciclo vigente
  mutate(ciclo_alta = as.integer(ciclo == "alta"))

# --- 3. IPCA: mensal e acumulado em 12 meses -----------------------------
ipca_m <- ipca_d |>
  arrange(date) |>
  transmute(mes = floor_date(date, "month"), ipca) |>
  mutate(ipca_12m = (zoo::rollapplyr(1 + ipca / 100, 12, prod, fill = NA) - 1) * 100)

# --- 4. Retornos mensais de cada ação e do Ibovespa ----------------------
# Preço do mês = preço ajustado do último pregão do mês.
ret_ativos <- precos |>
  filter(!is.na(adjusted)) |>
  arrange(symbol, date) |>
  mutate(mes = floor_date(date, "month")) |>
  group_by(symbol, mes) |>
  summarise(preco = dplyr::last(adjusted), .groups = "drop_last") |>
  arrange(mes, .by_group = TRUE) |>
  mutate(ret = (preco / dplyr::lag(preco) - 1) * 100) |>   # retorno simples, em %
  ungroup() |>
  left_join(CESTAS, by = c("symbol" = "ticker")) |>
  filter(mes >= PRIMEIRO_MES, mes <= ULTIMO_MES)

# --- 5. Cestas setoriais: média simples das ações do setor --------------
ret_setores <- ret_ativos |>
  filter(setor != "mercado") |>
  group_by(setor, mes) |>
  summarise(n_ativos = sum(!is.na(ret)),               # quantas ações entraram na média
            ret      = mean(ret, na.rm = TRUE),
            .groups = "drop")

setores_wide <- ret_setores |>
  select(mes, setor, ret) |>
  pivot_wider(names_from = setor, values_from = ret, names_prefix = "ret_")

ibov <- ret_ativos |>
  filter(setor == "mercado") |>
  select(mes, ret_ibov = ret)

# --- 6. Base final -------------------------------------------------------
base_mensal <- setores_wide |>
  left_join(ibov,    by = "mes") |>
  left_join(selic_m, by = "mes") |>
  left_join(ipca_m,  by = "mes") |>
  mutate(juro_real = ((1 + selic / 100) / (1 + ipca_12m / 100) - 1) * 100) |>
  filter(mes >= PRIMEIRO_MES, mes <= ULTIMO_MES) |>
  arrange(mes) |>
  select(mes, ret_bancos, ret_varejo, ret_utilities, ret_ibov,
         selic, delta_selic, ciclo, ciclo_alta, ipca, ipca_12m, juro_real)

# --- 7. Salvar -----------------------------------------------------------
write_csv(base_mensal, file.path(PASTA_TRATADOS, "base_mensal.csv"))
saveRDS(base_mensal,   file.path(PASTA_TRATADOS, "base_mensal.rds"))
write_csv(ret_ativos,  file.path(PASTA_TRATADOS, "retornos_ativos_mensal.csv"))
# Versão para Excel em português: ponto e vírgula entre colunas e vírgula decimal
write_csv2(base_mensal, file.path(PASTA_TRATADOS, "base_mensal_excel.csv"))

cat("\nBase mensal criada:", nrow(base_mensal), "meses, de",
    format(min(base_mensal$mes), "%m/%Y"), "a", format(max(base_mensal$mes), "%m/%Y"), "\n\n")
glimpse(base_mensal)
