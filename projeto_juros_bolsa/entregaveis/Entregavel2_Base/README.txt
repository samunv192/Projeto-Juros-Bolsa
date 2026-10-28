ENTREGÁVEL 2 — BASE DE DADOS MENSAL
Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic
Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)

CONTEÚDO
  - base_mensal.csv: arquivo principal. 141 meses (01/2015 a 09/2026), 12 variáveis.
  - base_mensal_excel.csv: a mesma base no padrão brasileiro (ponto e vírgula e vírgula decimal), para abrir no Excel.
  - retornos_ativos_mensal.csv: retorno mensal de cada ação, para testes de robustez.
  - dicionario_dados.md: descrição de cada variável, unidades, fontes e regras de construção.
  - validacao.txt: resultado das checagens automáticas da base.
  - scripts/: código que constrói (03_base_mensal.R) e valida (04_validacao.R) a base.

COMO A BASE FOI CONSTRUÍDA
  - Preço do mês: preço ajustado do último pregão do mês; retorno simples mensal, em %.
  - Setores: cestas de 3 ações (bancos, varejo e utilities), com média simples dos retornos.
  - Selic: meta vigente no fim do mês; delta_selic é a variação no mês, em pontos percentuais.
  - Ciclo: direção do último movimento do Copom (alta ou queda); meses sem mudança herdam o ciclo vigente.
  - Juro real ex-post: (1 + Selic) / (1 + IPCA acumulado em 12 meses) - 1.
  - Só entram meses completos e com IPCA já divulgado.

VALIDAÇÃO
  - 7 checagens OK e 0 falha(s). Detalhes em validacao.txt.

COMO REPRODUZIR
  A base é gerada a partir dos dados brutos do Entregável 1. Copie os scripts deste pacote
  para a pasta scripts/ do Entregável 1 e rode 03_base_mensal.R e depois 04_validacao.R.
  Os arquivos são gerados em dados/tratados/.
