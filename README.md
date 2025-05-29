<p align="center">
  <img src="report/img/meu_portefolio_logo.png" alt="meuPortefólio Logo" width="150"/>
</p>

# meuPortefólio

O meuPortefólio é um projeto acadêmico desenvolvido para a disciplina de Bases de Dados, focado na implementação de uma plataforma completa de gestão de investimentos com ênfase em Fractional Shares trading.

## Objetivo
Desenvolver uma base de dados robusta e eficiente que suporte uma plataforma de gestão de portfólios de investimento, permitindo aos usuários:
- Criar e gerenciar contas de investimento
- Monitorar diversos tipos de ativos (ações, índices, matérias-primas e criptomoedas)
- Realizar transações fracionadas
- Acompanhar métricas e análises de desempenho

## Estrutura do Projeto

```
meuportefolio/
├── frontend/           # Aplicação Next.js
├── backend/            # API REST em Rust
├── scripts/            # Scripts de configuração
├── db/                 # Scripts SQL
├── docker-compose.yml  # Configuração dos containers
└── README.md
```

## Tecnologias

- **Frontend**: Next.js 15, TypeScript, Tailwind CSS
- **Backend**: Rust, Actix-web
- **Database**: Microsoft SQL Server
- **Deployment**: Docker, Docker Compose

## Como Iniciar

### Pré-requisitos
- Docker
- Docker Compose

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/von-development/meuportefolio.git
cd meuportefolio
```

2. Inicie a aplicação:
```bash
docker-compose up --build
```

3. Acesse:
- Frontend: http://localhost:3000
- API: http://localhost:8080
- Database: localhost:1433

### Desenvolvimento

Para desenvolvimento individual dos serviços:

```bash
# Frontend
docker-compose up frontend

# Backend
docker-compose up api

# Database
docker-compose up db
```

## Funcionalidades

- Sistema de autenticação de usuários
- Gestão de portfólios de investimento
- Monitoramento de ativos financeiros
- Análise de risco e performance
- Interface responsiva

## Status

Projeto acadêmico em desenvolvimento para a disciplina de Bases de Dados.

### Características Principais
- Sistema completo de gestão de usuários e contas
- Suporte a múltiplos tipos de ativos
- Análise avançada de portfólio (pacote premium)
- Interface intuitiva para gestão de investimentos
- Sistema de subscrição com planos Basic e Premium

###  Tecnologias 
- Microsoft SQL Server Management Studio
- Base de Dados SQL Server
- Rust






