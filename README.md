# MeuPortfolio v2.0

Simple portfolio management application with **TypeScript**, **React**, and **SQL Server**.

## 🚀 Quick Setup

### 1. Start SQL Server
```bash
npm run start-db
```

### 2. Run Database Migrations
```bash
npm run setup
```

This will:
- Start SQL Server in Docker (localhost:1433)
- Show you which migration files to run in SQL Server Management Studio

### 3. Connect with SQL Server Management Studio
- **Server**: `localhost,1433`
- **Login**: `sa`
- **Password**: `YourStrong!Passw0rd`

### 4. Run Migration Files (in order)
Open and execute these files in SQL Server Management Studio:

1. `database/sqlserver/migrations/001_tables_v2.sql`
2. `database/sqlserver/migrations/002_indexes.sql`
3. `database/sqlserver/migrations/003_views_v2.sql`
4. `database/sqlserver/migrations/004_triggers.sql`
5. `database/sqlserver/migrations/005_1_user_procedures.sql`
6. `database/sqlserver/migrations/005_2_portfolio_procedures.sql`
7. `database/sqlserver/migrations/005_3_trading_procedures.sql`
8. `database/sqlserver/migrations/005_4_asset_procedures.sql`
9. `database/sqlserver/migrations/006_functions.sql`

### 5. Start the Application
```bash
npm start
```

This starts:
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- SQL Server: localhost:1433

## 🗂️ Project Structure

```
meuportefolio/
├── database/sqlserver/migrations/    # Your v2 SQL scripts
├── backend/                          # TypeScript API
├── frontend/                         # React app
├── docker/                           # Docker setup
└── scripts/                          # Setup scripts
```

## 🔄 Connecting to Existing Database

If you have an existing SQL Server database:

1. Copy `env.example` to `.env`
2. Update the database settings:
```
DB_HOST=your-server-name
DB_SA_PASSWORD=your-password
DB_NAME=your-database-name
```

## 📝 Development

- Backend development: `npm run dev:backend`
- Frontend development: `npm run dev:frontend`
- Stop all services: `npm run stop`

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






