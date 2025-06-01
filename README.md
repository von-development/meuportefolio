# meuPortfolio

Sistema de gestão de portfólios de investimento desenvolvido no âmbito da disciplina de Bases de Dados da Universidade de Aveiro (2024/2025).

## Estrutura do Projeto

O projeto está organizado em quatro componentes principais:

### Backend (Rust)
- **Localização**: `backend/`
- **Tecnologia**: Rust com framework Axum
- **Funcionalidade**: API REST de alta performance
- **Base de dados**: SQL Server com Tiberius driver
- **Containerização**: Docker Compose para desenvolvimento

### Frontend (React)
- **Localização**: `frontend/`
- **Tecnologia**: Next.js 14 com TypeScript
- **UI**: Tailwind CSS e Shadcn/ui components
- **Funcionalidade**: Interface moderna e responsiva para gestão de portfólios

### Base de Dados
- **Localização**: `database/`
- **Tecnologia**: SQL Server Management Studio
- **Migração**: Scripts SQL organizados sequencialmente
- **Funcionalidade**: Sistema completo de trading fracionário e análise de risco

### Documentação e Relatórios
- **Localização**: `docs/`
- **Conteúdo**: Relatórios técnicos, análise de requisitos, documentação da arquitetura
- **Screenshots**: Interfaces documentadas em `docs/interface/`

### Automação (Python)
- **Localização**: `scripts/`
- **Funcionalidade**: Scripts de importação de dados e automação de processos
- **Uso**: População da base de dados com dados históricos de mercado

## Funcionalidades Principais

- Gestão de utilizadores (Basic e Premium)
- Sistema de trading fracionário
- Análise de risco automatizada (Premium)
- Gestão de múltiplos portfólios
- Histórico completo de transações
- Sistema de auditoria e logging

## Instalação e Execução

### Pré-requisitos
- Docker e Docker Compose
- Node.js 18+ e npm
- Git

### 1. Clonar o Repositório
```bash
git clone https://github.com/your-username/meuportefolio.git
cd meuportefolio
```

### 2. Iniciar Backend e Base de Dados
```bash
cd backend
docker-compose up --build
```
O backend estará disponível em `http://localhost:8080`

### 3. Iniciar Frontend
```bash
cd frontend
npm install
npm run dev
```
O frontend estará disponível em `http://localhost:3000`

## Tecnologias Utilizadas

- **Backend**: Rust, Axum, Tiberius
- **Frontend**: Next.js, TypeScript, Tailwind CSS
- **Base de Dados**: SQL Server
- **Containerização**: Docker
- **Automação**: Python
- **Documentação**: Markdown

## Contexto Académico

Este projeto foi desenvolvido como trabalho prático da disciplina de Bases de Dados, demonstrando competências em:
- Modelação e normalização de bases de dados
- Implementação de sistemas relacionais complexos
- Desenvolvimento de APIs REST
- Criação de interfaces de utilizador modernas
- Integração de sistemas distribuídos

## Estrutura da Base de Dados

O sistema implementa 13 entidades principais organizadas em grupos funcionais:
- Gestão de utilizadores e contas
- Portfólios e trading
- Ativos e mercado
- Auditoria e logs

Para mais detalhes, consulte a documentação técnica em `docs/`.

## Contribuição

Este é um projeto académico desenvolvido para fins educacionais na Universidade de Aveiro.