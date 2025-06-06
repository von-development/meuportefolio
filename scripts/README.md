# meuPortfolio - Scripts de Importação de Dados

## Descrição

Scripts Python para importação de dados históricos de preços de ativos financeiros (ações, criptomoedas, commodities e índices) para a base de dados do meuPortfolio. Os scripts processam arquivos CSV e inserem os dados utilizando stored procedures.

**Fonte dos Dados:** Todos os dados históricos foram obtidos do [Investing.com](https://www.investing.com)

**IMPORTANTE:** Antes de executar estes scripts, certifique-se de que seguiu as instruções na pasta `database/` para configurar correctamente a base de dados, tabelas e stored procedures.

## Funcionalidades

- Importação de dados históricos de preços OHLC + Volume
- Suporte para 28 ativos diferentes (stocks, crypto, commodities, indexes)
- Conversão automática de formatos de volume (K, M, B, T)
- Validação e tratamento de dados
- Logging detalhado de operações
- Mapeamento automático de símbolos para AssetID

## Pré-requisitos

### Base de Dados
- SQL Server com base de dados configurada
- Tabela `portfolio.Assets` populada com os 28 ativos
- Stored procedure `portfolio.sp_import_asset_price` disponível

**Configuração da Base de Dados:** Consulte a pasta `database/` para instruções completas sobre setup, schemas e scripts de inicialização.

### Python e Ambiente Virtual

1. **Criar ambiente virtual:**
```bash
python -m venv venv
```

2. **Ativar ambiente virtual:**
```bash
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

3. **Instalar dependências:**
```bash
pip install -r requirements.txt
```

### Dependências Necessárias
```
pyodbc     # Conectividade SQL Server
pandas     # Manipulação de dados CSV
```

## Estrutura dos Dados CSV

Os arquivos CSV devem conter as seguintes colunas:
- `Date` - Data em formato MM/DD/YYYY
- `Price` - Preço de fechamento
- `Open` - Preço de abertura
- `High` - Preço máximo
- `Low` - Preço mínimo
- `Vol.` - Volume (suporta sufixos K, M, B, T)

## Organização dos Arquivos

```
scripts/
├── data/
│   ├── stocks/          # Ações (AAPL, GOOGL, META, etc.)
│   ├── crypto/          # Criptomoedas (BTC, ETH, XRP, etc.)
│   ├── commodities/     # Commodities (Gold, Oil, etc.)
│   └── indexes/         # Índices (S&P500, PSI20, etc.)
├── import_historical_data.py
├── requirements.txt
└── README.md
```

## Como Utilizar

### Importar todos os dados
```bash
python import_historical_data.py
```

### Importar por tipo de ativo
```bash
python import_historical_data.py --asset_type stocks
python import_historical_data.py --asset_type crypto
python import_historical_data.py --asset_type commodities
python import_historical_data.py --asset_type indexes
```

### Importar ativo específico
```bash
python import_historical_data.py --symbol AAPL
python import_historical_data.py --symbol BTC
```

### Teste com dados limitados
```bash
python import_historical_data.py --limit 10
```

## Configuração da Base de Dados

O script conecta-se por padrão usando:
- **Servidor:** localhost
- **Autenticação:** Windows Authentication
- **Base de dados:** Detectada automaticamente

Para configuração personalizada:
```bash
python import_historical_data.py --server MEUSERVIDOR --database MinhaBaseDados
```

## Verificação dos Dados

Após a importação, verificar com SQL:

```sql
-- Total de registos importados
SELECT 
    a.Symbol,
    a.AssetType,
    COUNT(ap.PriceID) as TotalRecords
FROM portfolio.Assets a
LEFT JOIN portfolio.AssetPrices ap ON a.AssetID = ap.AssetID
GROUP BY a.Symbol, a.AssetType
ORDER BY a.AssetType, a.Symbol;

-- Preços recentes de um ativo
SELECT TOP 10 
    AsOf, Price, OpenPrice, HighPrice, LowPrice, Volume
FROM portfolio.AssetPrices ap
JOIN portfolio.Assets a ON ap.AssetID = a.AssetID
WHERE a.Symbol = 'AAPL'
ORDER BY AsOf DESC;
```

## Troubleshooting

### Problemas Comuns

**1. Erro de módulo pyodbc:**
```bash
pip install pyodbc
```

**2. Erro de conexão à base de dados:**
- Verificar se o SQL Server está em execução
- Confirmar que Windows Authentication está habilitada
- Testar: `sqlcmd -S localhost -E`

**3. Símbolo não encontrado:**
- Executar primeiro os scripts de seeding da base de dados:
  - `database/seed/001_assets_basic.sql`
  - `database/seed/002_asset_details.sql`

**4. Arquivos não encontrados:**
- Verificar se os arquivos CSV estão nas pastas corretas
- Confirmar os nomes dos arquivos

**5. Erros de formato de data:**
- Garantir que as datas estão em formato MM/DD/YYYY
- Verificar células vazias ou inválidas

## Logs

O script gera logs detalhados em:
- Console (tempo real)
- Arquivo `import_log.txt`

## Resultado Esperado

Importação bem-sucedida mostrará:
```
2025-01-01 10:45:00 - INFO - === meuPortfolio Historical Data Import ===
2025-01-01 10:45:00 - INFO - Connected to database: localhost/portfolio
2025-01-01 10:45:00 - INFO - Loaded 28 assets from database
2025-01-01 10:45:01 - INFO - Processing AAPL: data/stocks/APPLE.csv
2025-01-01 10:45:02 - INFO - Completed AAPL: 102 success, 0 errors
...
2025-01-01 10:50:00 - INFO - Import completed: 28/28 files processed successfully
```

---

**Scripts prontos para importação de dados históricos** 