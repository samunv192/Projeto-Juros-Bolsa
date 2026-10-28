# Dicionário de dados — base_mensal.csv

Uma linha por mês, de jan/2015 ao último mês completo com IPCA divulgado.

| Variável | Descrição | Unidade | Fonte |
|---|---|---|---|
| mes | Mês de referência (primeiro dia do mês) | data | — |
| ret_bancos | Retorno mensal médio da cesta de bancos (ITUB4, BBDC4, BBAS3) | % | Yahoo Finance |
| ret_varejo | Retorno mensal médio da cesta de varejo (LREN3, MGLU3, RADL3) | % | Yahoo Finance |
| ret_utilities | Retorno mensal médio da cesta de utilities (EQTL3, CMIG4, SBSP3) | % | Yahoo Finance |
| ret_ibov | Retorno mensal do Ibovespa (^BVSP) | % | Yahoo Finance |
| selic | Meta Selic vigente no último dia do mês | % a.a. | BCB/SGS 432 |
| delta_selic | Variação da meta Selic em relação ao mês anterior | p.p. | calculado |
| ciclo | Direção do último movimento da Selic ("alta" ou "queda"); meses sem mudança herdam o ciclo vigente | texto | calculado |
| ciclo_alta | 1 se ciclo = "alta", 0 se "queda" | 0/1 | calculado |
| ipca | Variação do IPCA no mês | % | BCB/SGS 433 |
| ipca_12m | IPCA acumulado nos últimos 12 meses | % | calculado |
| juro_real | Juro real ex-post: (1 + selic) / (1 + ipca_12m) − 1 | % a.a. | calculado |

## Regras de construção

- **Preço do mês:** preço ajustado (dividendos e desdobramentos) do último pregão do mês.
- **Retorno:** retorno simples, (preço do mês / preço do mês anterior − 1) × 100.
- **Cestas:** média simples (pesos iguais) dos retornos das 3 ações de cada setor, rebalanceada todo mês.
- **Meses incompletos:** o mês corrente fica de fora até terminar e até o IPCA dele ser divulgado.

`retornos_ativos_mensal.csv` traz os mesmos retornos por ação (colunas symbol, mes, preco, ret, setor), para análises de robustez.
