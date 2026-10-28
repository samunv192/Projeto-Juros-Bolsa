# parametros.R — configurações usadas por todos os scripts do projeto
# (não precisa rodar sozinho: os outros scripts chamam este arquivo com source())

library(tidyverse)

# Confere se o R está rodando na pasta do projeto (no Positron: File > Open Folder)
if (!dir.exists("scripts")) {
  stop("Diretório de trabalho errado: abra a PASTA do projeto no Positron (File > Open Folder). ",
       "Diretório atual: ", getwd())
}

# Período: começamos 1 mês antes de 2015 para conseguir calcular o retorno de jan/2015
DATA_INICIO <- as.Date("2014-12-01")
DATA_FIM    <- Sys.Date()

# Pastas
PASTA_BRUTOS   <- "dados/brutos"    # dados como vieram da fonte
PASTA_TRATADOS <- "dados/tratados"  # base mensal final

# Cestas setoriais (3 ações por setor) + índice de mercado
# O 3º ativo de varejo e de utilities ainda pode ser trocado pelo grupo.
CESTAS <- tribble(
  ~ticker,    ~setor,
  "ITUB4.SA", "bancos",
  "BBDC4.SA", "bancos",
  "BBAS3.SA", "bancos",
  "LREN3.SA", "varejo",
  "MGLU3.SA", "varejo",
  "RADL3.SA", "varejo",
  "EQTL3.SA", "utilities",
  "CMIG4.SA", "utilities",
  "SBSP3.SA", "utilities",
  "^BVSP",    "mercado"
)
