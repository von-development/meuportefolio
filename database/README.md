# meuPortfolio - Base de Dados

## Descrição

Esta pasta contém todos os scripts SQL necessários para configurar a base de dados do meuPortfolio, incluindo estrutura de tabelas, stored procedures, funções, views, triggers e dados iniciais.

## Estrutura da Base de Dados

```
database/
├── migrations/        # Scripts de estrutura (executar em ordem)
├── seed/             # Dados iniciais e exemplos
└── README.md         # Este ficheiro
```

## Configuração - Ordem de Execução

### 1. Migrations (Estrutura da Base de Dados)

Execute os scripts na seguinte ordem **obrigatória**:

#### **000_init.sql**
- Inicialização da base de dados e criação do schema `portfolio`

#### **001_tables.sql**
- Criação de todas as tabelas principais do sistema (Users, Assets, Portfolios, AssetPrices, Holdings, Transactions, RiskMetrics, ApplicationLogs)

#### **002_indexes.sql**
- Criação de índices para optimização de performance em chaves estrangeiras e queries frequentes

#### **003_views.sql**
- Views para relatórios, agregações de dados e consultas complexas

#### **004_triggers.sql**
- Triggers para validação de dados, auditoria automática e validações de negócio

#### **005_1_user_procedures.sql**
- Stored procedures para gestão de utilizadores, autenticação e gestão de fundos

#### **005_2_portfolio_procedures.sql**
- Stored procedures para gestão de portfólios e cálculos de balanços

#### **005_3_trading_procedures.sql**
- Stored procedures para operações de trading (compra/venda de ativos)

#### **005_4_asset_procedures.sql**
- Stored procedures para gestão de ativos e importação de preços

#### **005_5_risk_procedures.sql**
- Stored procedures para análise de risco e cálculo de métricas

#### **006_1_functions.sql**
- Funções auxiliares do sistema e cálculos financeiros

#### **006_2_risk_functions.sql**
- Funções específicas para cálculo de risco e métricas avançadas

#### **007_app_logs_v2.sql**
- Sistema avançado de logging e auditoria de operações

### 2. Seed Data (Dados Iniciais)

Após executar todas as migrations, execute os scripts de seed **nesta ordem**:

#### **001_assets_basic.sql**
- Criação dos 28 ativos básicos do sistema
- Stocks: AAPL, GOOGL, META, GALP, EDP, VALE, PBR, BBAS3
- Crypto: BTC, ETH, XRP, ADA, DOGE, SOL
- Commodities: CL, NG, GC, SI, HG, CC
- Índices: SPX, DJI, NDX, PSI20, BVSP, UKX, DAX, CAC

#### **002_asset_details.sql**
- Detalhes específicos dos ativos
- Informações de empresas (para stocks)
- Metadados de criptomoedas
- Especificações de commodities e índices

#### **003_users_comprehensive.sql**
- Utilizadores de exemplo para testes
- Contas com diferentes tipos de subscrição
- Dados de demonstração

#### **004_portfolios_holdings_fixed.sql**
- Portfólios de exemplo
- Holdings de demonstração
- Transações históricas de exemplo
- **Nota:** Use este em vez de `004_portfolios_and_holdings.sql`

#### **005_application_logs.sql**
- Logs de exemplo do sistema
- Dados de auditoria iniciais

## Como Executar

### Pré-requisitos
- SQL Server 2019+ ou SQL Server Express
- SQL Server Management Studio (SSMS) ou Azure Data Studio
- Permissões para criar base de dados e executar scripts

### Passos

1. **Conectar ao SQL Server**
```sql
-- Conectar como administrador (sa ou Windows Authentication)
```

2. **Executar Migrations (em ordem)**
```sql
-- Executar cada ficheiro em ordem sequencial
-- 000_init.sql primeiro, depois 001_tables.sql, etc.
```

3. **Executar Seed Scripts (em ordem)**
```sql
-- Após todas as migrations, executar seed scripts
-- 001_assets_basic.sql primeiro, depois os restantes
```
