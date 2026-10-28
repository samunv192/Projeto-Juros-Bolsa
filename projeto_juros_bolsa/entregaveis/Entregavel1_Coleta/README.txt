ENTREGÁVEL 1 — SCRIPTS DE COLETA
Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic
Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)

O QUE ESTES SCRIPTS FAZEM
  - 00_setup.R: instala os pacotes necessários e cria as pastas.
  - parametros.R: período, pastas e composição das cestas setoriais.
  - 01_coleta_bcb.R: baixa do Banco Central (SGS) a meta Selic (série 432) e o IPCA mensal (série 433).
  - 02_coleta_mercado.R: baixa do Yahoo Finance os preços diários ajustados de 9 ações e do Ibovespa.

COMO RODAR
  1. Abrir esta pasta no Positron (File > Open Folder) ou no RStudio.
  2. Rodar, nesta ordem: scripts/00_setup.R, scripts/01_coleta_bcb.R e scripts/02_coleta_mercado.R.
  3. Os dados são salvos em dados/brutos/.

COLETA INCLUÍDA NESTE PACOTE
  - Data da coleta: 28/10/2026
  - Meta Selic: 4350 observações diárias, de 01/12/2014 a 28/10/2026
  - IPCA: 154 meses, de 12/2013 a 09/2026
  - Preços: 10 tickers, de 01/12/2014 a 27/10/2026, com 2962 pregões por ticker
  - Composição das cestas:
  - bancos: ITUB4, BBDC4, BBAS3
  - mercado: ^BVSP
  - utilities: EQTL3, CMIG4, SBSP3
  - varejo: LREN3, MGLU3, RADL3

OBSERVAÇÕES
  - A API do BCB limita cada consulta a 10 anos; o script baixa em blocos de 3 anos e junta.
  - As fontes são atualizadas com o tempo (meses novos e revisões de preços ajustados), então
    rodar de novo em outra data pode gerar valores um pouco diferentes. Os arquivos em
    dados/brutos/ registram exatamente o que foi coletado na data acima.
