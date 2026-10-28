# montar_entregaveis.R — monta os pacotes dos Entregáveis 1 e 2 prontos para enviar
# Rode DEPOIS do rodar_tudo.R. Resultado: pasta entregaveis/ com duas pastas e dois .zip.

source("scripts/parametros.R")

SAIDA <- "entregaveis"
E1 <- file.path(SAIDA, "Entregavel1_Coleta")
E2 <- file.path(SAIDA, "Entregavel2_Base")

# --- 0. Confere se tudo já foi gerado -----------------------------------
brutos   <- c("bcb_selic_meta.csv", "bcb_ipca.csv", "yahoo_precos_diarios.csv")
tratados <- c("base_mensal.csv", "base_mensal_excel.csv", "retornos_ativos_mensal.csv")
necessarios <- c(file.path(PASTA_BRUTOS, brutos), file.path(PASTA_TRATADOS, tratados),
                 "dados/dicionario_dados.md")
faltando <- necessarios[!file.exists(necessarios)]
if (length(faltando) > 0) {
  stop("Rode o rodar_tudo.R antes. Arquivos que faltam:\n  ", paste(faltando, collapse = "\n  "))
}

unlink(SAIDA, recursive = TRUE)  # começa do zero a cada execução
dir.create(file.path(E1, "scripts"),       recursive = TRUE)
dir.create(file.path(E1, "dados", "brutos"), recursive = TRUE)
dir.create(file.path(E2, "scripts"),       recursive = TRUE)

escrever <- function(linhas, caminho) {
  con <- file(caminho, open = "w", encoding = "UTF-8")
  writeLines(linhas, con)
  close(con)
}
fmt_data <- function(x) format(as.Date(x), "%d/%m/%Y")

# --- 1. Entregável 1: scripts de coleta + dados brutos ------------------
file.copy(file.path("scripts", c("parametros.R", "00_setup.R", "01_coleta_bcb.R", "02_coleta_mercado.R")),
          file.path(E1, "scripts"))
file.copy(file.path(PASTA_BRUTOS, brutos), file.path(E1, "dados", "brutos"))

selic  <- read_csv(file.path(PASTA_BRUTOS, "bcb_selic_meta.csv"),       show_col_types = FALSE)
ipca   <- read_csv(file.path(PASTA_BRUTOS, "bcb_ipca.csv"),             show_col_types = FALSE)
precos <- read_csv(file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv"), show_col_types = FALSE)

data_coleta <- format(file.mtime(file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv")), "%d/%m/%Y")
pregoes <- count(precos, symbol)
lista_tickers <- CESTAS |>
  group_by(setor) |>
  summarise(t = paste(sub("\\.SA$", "", ticker), collapse = ", "), .groups = "drop") |>
  mutate(linha = paste0("  - ", setor, ": ", t)) |>
  pull(linha)

escrever(c(
  "ENTREGÁVEL 1 — SCRIPTS DE COLETA",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "O QUE ESTES SCRIPTS FAZEM",
  "  - 00_setup.R: instala os pacotes necessários e cria as pastas.",
  "  - parametros.R: período, pastas e composição das cestas setoriais.",
  "  - 01_coleta_bcb.R: baixa do Banco Central (SGS) a meta Selic (série 432) e o IPCA mensal (série 433).",
  "  - 02_coleta_mercado.R: baixa do Yahoo Finance os preços diários ajustados de 9 ações e do Ibovespa.",
  "",
  "COMO RODAR",
  "  1. Abrir esta pasta no Positron (File > Open Folder) ou no RStudio.",
  "  2. Rodar, nesta ordem: scripts/00_setup.R, scripts/01_coleta_bcb.R e scripts/02_coleta_mercado.R.",
  "  3. Os dados são salvos em dados/brutos/.",
  "",
  "COLETA INCLUÍDA NESTE PACOTE",
  paste0("  - Data da coleta: ", data_coleta),
  paste0("  - Meta Selic: ", nrow(selic), " observações diárias, de ", fmt_data(min(selic$date)),
         " a ", fmt_data(max(selic$date))),
  paste0("  - IPCA: ", nrow(ipca), " meses, de ", format(min(ipca$date), "%m/%Y"),
         " a ", format(max(ipca$date), "%m/%Y")),
  paste0("  - Preços: ", n_distinct(precos$symbol), " tickers, de ", fmt_data(min(precos$date)),
         " a ", fmt_data(max(precos$date)), ", com ", min(pregoes$n),
         if (min(pregoes$n) != max(pregoes$n)) paste0(" a ", max(pregoes$n)) else "",
         " pregões por ticker"),
  "  - Composição das cestas:",
  lista_tickers,
  "",
  "OBSERVAÇÕES",
  "  - A API do BCB limita cada consulta a 10 anos; o script baixa em blocos de 3 anos e junta.",
  "  - As fontes são atualizadas com o tempo (meses novos e revisões de preços ajustados), então",
  "    rodar de novo em outra data pode gerar valores um pouco diferentes. Os arquivos em",
  "    dados/brutos/ registram exatamente o que foi coletado na data acima."
), file.path(E1, "README.txt"))

# --- 2. Entregável 2: base mensal + dicionário + validação --------------
file.copy(file.path(PASTA_TRATADOS, tratados), E2)
file.copy("dados/dicionario_dados.md", E2)
file.copy(file.path("scripts", c("parametros.R", "03_base_mensal.R", "04_validacao.R")),
          file.path(E2, "scripts"))

# Saída das checagens salva em texto
capture.output(source("scripts/04_validacao.R"), file = file.path(E2, "validacao.txt"))
linhas_val <- readLines(file.path(E2, "validacao.txt"), encoding = "UTF-8")
n_ok    <- sum(grepl("^\\s*OK\\s", linhas_val))
n_falha <- sum(grepl("^\\s*FALHA\\s", linhas_val))

base <- read_csv(file.path(PASTA_TRATADOS, "base_mensal.csv"), show_col_types = FALSE)

escrever(c(
  "ENTREGÁVEL 2 — BASE DE DADOS MENSAL",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "CONTEÚDO",
  paste0("  - base_mensal.csv: arquivo principal. ", nrow(base), " meses (",
         format(min(base$mes), "%m/%Y"), " a ", format(max(base$mes), "%m/%Y"), "), ",
         ncol(base), " variáveis."),
  "  - base_mensal_excel.csv: a mesma base no padrão brasileiro (ponto e vírgula e vírgula decimal), para abrir no Excel.",
  "  - retornos_ativos_mensal.csv: retorno mensal de cada ação, para testes de robustez.",
  "  - dicionario_dados.md: descrição de cada variável, unidades, fontes e regras de construção.",
  "  - validacao.txt: resultado das checagens automáticas da base.",
  "  - scripts/: código que constrói (03_base_mensal.R) e valida (04_validacao.R) a base.",
  "",
  "COMO A BASE FOI CONSTRUÍDA",
  "  - Preço do mês: preço ajustado do último pregão do mês; retorno simples mensal, em %.",
  "  - Setores: cestas de 3 ações (bancos, varejo e utilities), com média simples dos retornos.",
  "  - Selic: meta vigente no fim do mês; delta_selic é a variação no mês, em pontos percentuais.",
  "  - Ciclo: direção do último movimento do Copom (alta ou queda); meses sem mudança herdam o ciclo vigente.",
  "  - Juro real ex-post: (1 + Selic) / (1 + IPCA acumulado em 12 meses) - 1.",
  "  - Só entram meses completos e com IPCA já divulgado.",
  "",
  "VALIDAÇÃO",
  paste0("  - ", n_ok, " checagens OK e ", n_falha, " falha(s). Detalhes em validacao.txt."),
  "",
  "COMO REPRODUZIR",
  "  A base é gerada a partir dos dados brutos do Entregável 1. Copie os scripts deste pacote",
  "  para a pasta scripts/ do Entregável 1 e rode 03_base_mensal.R e depois 04_validacao.R.",
  "  Os arquivos são gerados em dados/tratados/."
), file.path(E2, "README.txt"))

# --- 3. Compactar em .zip -----------------------------------------------
compactar <- function(pasta) {
  destino <- paste0(pasta, ".zip")
  if (.Platform$OS.type == "windows") {
    cmd <- sprintf("Compress-Archive -Path '%s' -DestinationPath '%s' -Force",
                   normalizePath(pasta), file.path(normalizePath(dirname(pasta)), basename(destino)))
    status <- system2("powershell", c("-NoProfile", "-Command", shQuote(cmd, type = "cmd")))
  } else {
    old <- setwd(dirname(pasta)); on.exit(setwd(old))
    status <- utils::zip(basename(destino), basename(pasta))
  }
  if (!identical(as.integer(status), 0L) || !file.exists(destino)) {
    message("Não consegui criar ", destino, ". Compacte a pasta manualmente ",
            "(botão direito > Compactar / Enviar para > Pasta compactada).")
  }
}
compactar(E1)
compactar(E2)

cat("\nPronto! Veja a pasta '", SAIDA, "':\n", sep = "")
print(list.files(SAIDA, recursive = TRUE))
if (n_falha > 0) warning("A validação teve ", n_falha, " falha(s). Confira validacao.txt antes de enviar.")
