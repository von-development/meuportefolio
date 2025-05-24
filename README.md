<p align="center">
  <img src="report/img/meu_portefolio_logo.png" alt="meuPortefólio Logo" width="150"/>
</p>

## meuPortefólio

O meuPortefólio é um projeto acadêmico desenvolvido para a disciplina de Bases de Dados, focado na implementação de uma plataforma completa de gestão de investimentos com ênfase em Fractional Shares trading.

###  Objetivo
Desenvolver uma base de dados robusta e eficiente que suporte uma plataforma de gestão de portfólios de investimento, permitindo aos usuários:
- Criar e gerenciar contas de investimento
- Monitorar diversos tipos de ativos (ações, índices, matérias-primas e criptomoedas)
- Realizar transações fracionadas
- Acompanhar métricas e análises de desempenho

### Características Principais
- Sistema completo de gestão de usuários e contas
- Suporte a múltiplos tipos de ativos
- Análise avançada de portfólio (pacote premium)
- Interface intuitiva para gestão de investimentos
- Sistema de subscrição com planos Basic e Premium

###  Tecnologias (WIP)
- Microsoft SQL Server Management Studio
- Base de Dados SQL Server

# meuPortfolio Project Structure

This project is organized for full-stack development with backend, frontend, and database components, including Docker support for local development.

## Project Structure

```
meuportefolio/
├── backend/                  # Backend application code
├── frontend/                 # Frontend application code
├── db/                       # Database scripts and configuration
│   ├── connection/           # SQL Server connection/test scripts
│   ├── functions/            # User-defined SQL functions
│   ├── indexes/              # Index creation scripts
│   ├── migrations/           # Migration scripts (full schema builds)
│   ├── procedures/           # Stored procedures
│   ├── schema/               # Table and view definitions
│   ├── test/                 # Test and cleanup scripts
│   ├── triggers/             # Triggers
│   └── README.md             # Database documentation
├── db/docker/                # Docker-specific database setup
│   └── init/                 # Initialization SQL scripts for Docker container
├── drawings/                 # Diagrams and design files
├── report/                   # Project reports and documentation
├── docker-compose.yml        # Docker Compose configuration (root)
├── database_analysis.md      # Database analysis and design notes
└── README.md                 # Project overview (this file)
```

- **db/docker/init/**: Place a single combined SQL script here (e.g., `01_init.sql`) for automatic execution when the SQL Server Docker container starts.
- **docker-compose.yml**: Orchestrates the SQL Server container and will be extended for backend/frontend integration.

> **Note:** If you move or rename folders, update the `docker-compose.yml` volume path accordingly.


