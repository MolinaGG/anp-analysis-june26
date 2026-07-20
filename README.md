# Análise de Preços de Combustíveis no Brasil (ANP)

Análise exploratória e estatística dos preços praticados no mercado brasileiro de combustíveis, com base nos dados disponibilizados pela Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP).

> Projeto focado no mapeamento da variação média de preços por região/estado, identificação de disparidades regionais e análise da evolução temporal das margens de revenda.

---

## 🛠️ Stack / Tecnologias

* **Linguagem:** R
* **Manipulação de Dados:** `tidyverse`, `dplyr`, `data.table`
* **Visualização:** `ggplot2`
* **Relatórios:** R Markdown / Quarto

---

## 📁 Estrutura do Repositório

```text
├── data/       -> Instruções sobre a base de dados
├── scripts/    -> Scripts R de extração, limpeza e análise
├── reports/    -> Gráficos gerados e relatórios (HTML/PDF)
├── .gitignore
└── README.md

🗄️ Fonte dos Dados
Devido ao tamanho da base original da ANP (anp.csv, ~3.4 GB), o arquivo bruto não está versionado neste repositório.

Fonte oficial: Dados Abertos ANP

🚀 Como Executar
Clone o repositório:
git clone https://github.com/MolinaGG/anp-analysis-june26.git

Adicione a base de dados:
Baixe o arquivo .csv no portal da ANP e salve na raiz do projeto como anp.csv.

Execute os scripts no RStudio:
source("scripts/analise.R")

✒️ Autor
Guilherme Molina Solano — Análise e Desenvolvimento
