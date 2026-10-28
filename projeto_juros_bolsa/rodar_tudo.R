# rodar_tudo.R — roda o projeto inteiro em ordem (coleta -> base mensal -> validação)
# No Positron: abra a pasta do projeto, abra este arquivo e clique no botão ▶ (Run).

source("scripts/00_setup.R")
source("scripts/01_coleta_bcb.R")
source("scripts/02_coleta_mercado.R")
source("scripts/03_base_mensal.R")
source("scripts/04_validacao.R")
