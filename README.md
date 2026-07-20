# Análise de Preços de Combustíveis no Brasil (ANP)

Análise exploratória e estatística dos preços praticados no mercado brasileiro de combustíveis, com base nos dados disponibilizados pela Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP).

> **Projeto:** Mapeamento da variação média de preços por região e estado, identificação de disparidades regionais e análise da evolução temporal das margens de revenda.

---

## 🛠️ Stack / Tecnologias

* **Linguagem:** R
* **Manipulação de Dados:** `tidyverse`, `dplyr`, `data.table`
* **Visualização:** `ggplot2`
* **Relatórios:** R Markdown / Quarto

---

## 📁 Estrutura do Repositório

```text
├── Script Diesel e Diesel S-10.R
├── .gitignore
└── README.md
```

🗄️ Fonte dos Dados
Devido ao tamanho da base original da ANP (anp.csv, ~3.4 GB), o arquivo bruto não está versionado neste repositório.

Fonte: https://www.kaggle.com/datasets/paulogladson/anp-combustveis

🚀 Como Executar
Clone o repositório:
```bash
git clone https://github.com/MolinaGG/anp-analysis-june26.git
```

Adicione a base de dados:
Baixe o arquivo .csv no portal da ANP e salve na raiz do projeto como anp.csv.

Execute no RStudio:
```R
source("Script Diesel e Diesel S-10.R")
```

✒️ Autor
Guilherme Molina Solano — Análise e Desenvolvimento
