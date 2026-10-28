# 01_coleta_bcb.R — baixa a meta Selic (série 432) e o IPCA mensal (série 433) do SGS/BCB
# Saída: dados/brutos/bcb_selic_meta.csv e dados/brutos/bcb_ipca.csv

source("scripts/parametros.R")
library(httr2)

USAR_RBCB <- FALSE  # FALSE = API do BCB direto (recomendado); TRUE = pacote rbcb

# A API do BCB recusa consultas com janela maior que 10 anos.
# Por isso dividimos o período em blocos de 3 anos e depois juntamos.
blocos_de_datas <- function(inicio, fim, anos = 3) {
  inicios <- seq(inicio, fim, by = paste(anos, "years"))
  fins    <- c(inicios[-1] - 1, fim)
  tibble(inicio = inicios, fim = fins)
}

# Opção 1: API do BCB direto.
# Mandamos um "User-Agent" e pedimos JSON explicitamente; se o servidor devolver
# uma página de erro (HTML/XML), o script para e mostra o que veio, em vez de travar no JSON.
baixar_bloco_api <- function(codigo, inicio, fim) {
  url <- paste0(
    "https://api.bcb.gov.br/dados/serie/bcdata.sgs.", codigo,
    "/dados?formato=json",
    "&dataInicial=", format(inicio, "%d/%m/%Y"),
    "&dataFinal=",   format(fim,    "%d/%m/%Y")
  )
  resp <- request(url) |>
    req_user_agent("Mozilla/5.0 (projeto academico REC3302 FEA-RP/USP)") |>
    req_headers(Accept = "application/json") |>
    req_timeout(60) |>
    # Erros temporários do servidor (502, 503...) disparam novas tentativas, com espera crescente
    req_retry(max_tries = 6,
              is_transient = \(r) resp_status(r) %in% c(429, 500, 502, 503, 504),
              backoff = \(i) 10 * i) |>
    req_error(is_error = \(r) FALSE) |>
    req_perform()

  texto <- resp_body_string(resp)
  if (resp_status(resp) != 200 || !startsWith(trimws(texto), "[")) {
    stop("O BCB não devolveu JSON para a série ", codigo,
         " (status ", resp_status(resp), ").\nInício da resposta: ",
         substr(texto, 1, 300))
  }
  Sys.sleep(1)  # pausa curta entre consultas para não sobrecarregar a API
  jsonlite::fromJSON(texto) |>
    as_tibble() |>
    transmute(date  = as.Date(data, format = "%d/%m/%Y"),
              valor = as.numeric(valor))
}

# Opção 2: pacote rbcb
baixar_bloco_rbcb <- function(codigo, inicio, fim) {
  rbcb::get_series(c(valor = codigo), start_date = inicio, end_date = fim)
}

baixar_sgs <- function(codigo, nome, inicio = DATA_INICIO) {
  baixar <- if (USAR_RBCB) baixar_bloco_rbcb else baixar_bloco_api
  blocos <- blocos_de_datas(inicio, DATA_FIM)
  map2(blocos$inicio, blocos$fim, \(i, f) baixar(codigo, i, f)) |>
    bind_rows() |>
    distinct(date, .keep_all = TRUE) |>   # remove datas repetidas entre blocos
    arrange(date) |>
    rename(!!nome := valor)
}

# Se o BCB falhar mesmo depois das novas tentativas, usamos o arquivo baixado
# na última vez que deu certo (se existir), com um aviso.
baixar_ou_usar_salvo <- function(codigo, nome, arquivo, ...) {
  caminho <- file.path(PASTA_BRUTOS, arquivo)
  dados <- tryCatch(baixar_sgs(codigo, nome, ...), error = function(e) {
    if (!file.exists(caminho)) stop(conditionMessage(e), call. = FALSE)
    warning("Falha ao baixar a série ", codigo, " do BCB; usando o arquivo salvo ", arquivo,
            ". Rode de novo mais tarde para atualizar.", call. = FALSE)
    NULL
  })
  if (is.null(dados)) return(read_csv(caminho, show_col_types = FALSE))
  write_csv(dados, caminho)
  dados
}

# --- Coleta -------------------------------------------------------------
selic <- baixar_ou_usar_salvo(432, "selic_meta", "bcb_selic_meta.csv")   # % ao ano
# IPCA começa 12 meses antes, para já termos o IPCA acumulado em 12 meses em jan/2015
ipca  <- baixar_ou_usar_salvo(433, "ipca", "bcb_ipca.csv",
                              inicio = DATA_INICIO %m-% months(12))     # variação % no mês

# --- Checagens ----------------------------------------------------------
checar <- function(df, nome) {
  v <- df[[2]]
  cat(nome, "\n",
      "  observações:", nrow(df), "\n",
      "  período:", format(min(df$date)), "a", format(max(df$date)), "\n",
      "  mínimo / máximo:", min(v, na.rm = TRUE), "/", max(v, na.rm = TRUE), "\n",
      "  valores ausentes:", sum(is.na(v)), "\n\n")
}
checar(selic, "Meta Selic (% a.a.)")
checar(ipca,  "IPCA (% no mês)")

# O que esperar: Selic entre ~2 e ~15; IPCA mensal quase sempre entre -0,5 e 1,5.
