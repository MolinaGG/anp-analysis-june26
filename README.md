⛽ Análise de Preços de Combustíveis no Brasil (ANP)
Projeto de análise exploratória e estatística dos preços praticados no mercado brasileiro de combustíveis, com base nos dados disponibilizados pela Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP).

📌 Sobre o Projeto
Este projeto analisa a variação de preços, distribuição regional e tendências de mercado para combustíveis (Gasolina, Etanol, Diesel, etc.).

🎯 Objetivos
Mapear a variação média de preços por região e estado.

Identificar disparidades regionais e outliers de preços.

Analisar a evolução temporal das margens e valores de revenda.

🛠️ Tecnologias e Pacotes Utilizados
Linguagem: R

Manipulação de Dados: tidyverse, dplyr, data.table (ajuste para os pacotes que você usou)

Visualização: ggplot2

Relatório/Documentação: R Markdown / Quarto

📊 Estrutura do Repositório
Plaintext
├── data/              # Instruções sobre a base de dados
├── scripts/           # Scripts R de extração, limpeza e análise
│   └── analise.R
├── reports/           # Gráficos gerados e relatórios (HTML/PDF)
├── .gitignore
└── README.md

🗄️ Fonte dos Dados
Devido ao tamanho da base de dados original da ANP (anp.csv, ~3,4 GB), o arquivo de dados brutos não está versionado neste repositório.

Você pode obter os dados brutos atualizados diretamente no portal do governo:

Fonte oficial: Dados Abertos ANP

🚀 Como Executar o Projeto
Clone o repositório:

Bash
git clone https://github.com/MolinaGG/anp-analysis-june26.git
Baixe a base de dados:
Baixe o arquivo .csv da ANP e salve na raiz do projeto como anp.csv.

Execute os scripts:
Abra o projeto no RStudio (.Rproj) e rode o script principal:

R
source("scripts/analise.R")
✒️ Autor
Guilherme Molina Solano — Análise e desenvolvimento — LinkedIn | GitHub
