# meuPortfolio - Backend API

## Descrição

O **meuPortfolio Backend** é uma API REST robusta desenvolvida em **Rust** usando o framework **Axum**, projetada para gerenciamento completo de portfólios de investimento. A aplicação oferece funcionalidades avançadas para trading, análise de risco, gestão de ativos e autenticação de usuários.

## Funcionalidades Principais

### **Gestão de Ativos (Asset Management)**
- **40+ Endpoints REST** para operações completas
- Suporte para múltiplos tipos de ativos: Stocks, Crypto, Commodities, Índices
- Histórico de preços com dados OHLC + Volume
- Importação de dados CSV em lote
- Informações detalhadas de empresas e índices

### **Gestão de Usuários**
- Sistema de autenticação com **JWT**
- Hash de senhas com **Argon2**
- Gestão de fundos (depósitos, levantamentos, alocações)
- Sistema de subscriptions premium
- Histórico completo de transações

### **Gestão de Portfólios**
- CRUD completo de portfólios
- Sistema de trading (compra/venda de ativos)
- Análise de holdings e balanços
- Sumários detalhados de performance
- Relatórios de rentabilidade

### **Análise de Risco**
- Métricas de risco por utilizador e portfolio
- Cálculo de volatilidade e drawdown
- Análise de tendências temporais
- Ratios de Sharpe e Beta
- Relatórios agregados de risco

### **Características Técnicas**
- **Performance**: Runtime assíncrono com Tokio
- **Segurança**: JWT authentication + CORS configurado
- **Documentação**: Swagger UI automático (`/swagger-ui`)
- **Monitoring**: Health checks para aplicação e base de dados
- **Database**: Stored procedures para operações complexas

## Stack Tecnológica

### Dependências Principais
```toml
axum = "0.8.4"           # Framework web moderno
tiberius = "0.12"        # Driver SQL Server nativo
tokio = "1"              # Runtime assíncrono
serde = "1"              # Serialização JSON
jsonwebtoken = "9"       # Autenticação JWT
argon2 = "0.5"          # Hash de senhas
utoipa = "5.3.1"        # Documentação OpenAPI
```

### Arquitetura de Módulos
```
src/
├── main.rs           # Configuração da aplicação e rotas
├── handlers/         # Lógica dos endpoints
│   ├── health.rs     # Health checks
│   ├── assets.rs     # Gestão de ativos
│   ├── users.rs      # Gestão de usuários
│   ├── portfolio.rs  # Gestão de portfólios
│   └── risk.rs       # Análise de risco
├── models/           # Estruturas de dados
├── db/              # Conectividade base de dados
└── bin/             # Utilitários auxiliares
```

## Configuração

### 1. Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto backend com as seguintes configurações:

```bash
# Copie o arquivo .env.example e renomeie para .env
cp .env.example .env
```

### 2. Configuração da Base de Dados

As seguintes variáveis devem ser configuradas no arquivo `.env`:

```env
# Database Configuration
DB_HOST=seu_servidor_sql
DB_PORT=1433
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
DB_NAME=minha_base_dados_exemplo
DB_INSTANCE=SQLEXPRESS

# Application Settings
RUST_LOG=info
```

### 3. Pré-requisitos

- **Rust 1.82+** (para desenvolvimento local)
- **Docker & Docker Compose** (recomendado)
- **SQL Server** (local ou remoto)
- **Git**

## Executar com Docker

### Método 1: Docker Compose (Recomendado)

1. **Clone o repositório:**
```bash
git clone <repo-url>
cd meuportefolio
```

2. **Configure o arquivo .env:**
```bash
cd backend
cp .env.example .env
# Edite o .env com suas configurações de base de dados
```

3. **Execute com Docker Compose:**
```bash
# Na raiz do projeto (onde está o docker-compose.yml)
docker-compose up --build backend
```

### Método 2: Docker Build Manual

1. **Entre no diretório backend:**
```bash
cd backend
```

2. **Configure o .env:**
```bash
cp .env.example .env
# Configure suas variáveis de ambiente
```

3. **Build da imagem:**
```bash
docker build -t meuportefolio-backend .
```

4. **Execute o container:**
```bash
docker run -p 8080:8080 --env-file .env meuportefolio-backend
```

## Desenvolvimento Local

### Instalação e Execução

1. **Instale o Rust:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

2. **Clone e configure:**
```bash
git clone <repo-url>
cd meuportefolio/backend
cp .env.example .env
# Configure o .env
```

3. **Execute em modo desenvolvimento:**
```bash
cargo run
```

4. **Teste a conectividade da base de dados:**
```bash
cargo run -- --test-db
```

## Endpoints da API

### Health Checks
- `GET /health` - Status da aplicação
- `GET /db-health` - Status da base de dados

### Asset Management (10 endpoints)
- `GET /api/v1/assets` - Listar ativos
- `POST /api/v1/assets` - Criar ativo
- `GET /api/v1/assets/{id}` - Obter ativo
- `PUT /api/v1/assets/{id}` - Atualizar ativo
- `POST /api/v1/assets/import/csv` - Importar preços CSV

### User Management (18 endpoints)
- `POST /api/v1/users/login` - Login
- `POST /api/v1/users/logout` - Logout
- `POST /api/v1/users` - Criar usuário
- `GET /api/v1/users/{id}` - Obter usuário
- `POST /api/v1/users/{id}/deposit` - Depositar fundos

### Portfolio Management (12 endpoints)
- `GET /api/v1/portfolios` - Listar portfólios
- `POST /api/v1/portfolios` - Criar portfólio
- `POST /api/v1/portfolios/buy` - Comprar ativo
- `POST /api/v1/portfolios/sell` - Vender ativo

### Risk Analysis (8 endpoints)
- `GET /api/v1/risk/metrics/user/{id}` - Métricas de risco
- `GET /api/v1/risk/summary` - Sumário de risco

## Documentação da API

A documentação completa da API está disponível via **Swagger UI**:

```
http://localhost:8080/swagger-ui
```

A especificação OpenAPI está em:
```
http://localhost:8080/api-docs/openapi.json
```

## Testes e Monitorização

### Health Checks
```bash
# Status da aplicação
curl http://localhost:8080/health

# Status da base de dados
curl http://localhost:8080/db-health
```

### Teste de Conectividade
```bash
# Teste automático da base de dados
cargo run -- --test-db
```

## Status dos Serviços

Quando a aplicação inicia com sucesso, você verá:

```
Server running on http://0.0.0.0:8080
API documentation available at http://localhost:8080/swagger-ui
Health check available at http://localhost:8080/health
Database health check available at http://localhost:8080/db-health
=== Database Connection Details ===
Host: seu_servidor_sql
Port: 1433
User: seu_usuario
Database: portfolio
===================================
```

## Troubleshooting

### Problemas Comuns

1. **Erro de conexão à base de dados:**
   - Verifique as variáveis no `.env`
   - Teste a conectividade: `cargo run -- --test-db`

2. **Porta 8080 em uso:**
   - Altere a porta no código ou termine o processo em uso

3. **Erro de permissões Docker:**
   - Execute com `sudo` ou configure o Docker para seu usuário

### Logs
```bash
# Ver logs do container
docker-compose logs -f backend

# Logs em tempo real
RUST_LOG=debug cargo run
```




---

**Desenvolvido com Rust** 