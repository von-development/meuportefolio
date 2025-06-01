# meuPortfolio Data Import Scripts

This folder contains scripts for importing historical price data from CSV files into the meuPortfolio database.

## 📋 Prerequisites

### **1. Python Requirements**
```bash
pip install -r requirements.txt
```

Required packages:
- `pyodbc` - SQL Server database connectivity
- `pandas` - Data manipulation and CSV reading

### **2. Database Requirements** 
- ✅ SQL Server with `p6g4` database
- ✅ `portfolio.Assets` table populated (28 assets)
- ✅ `portfolio.sp_import_asset_price` stored procedure

### **3. CSV Data Structure**
CSV files should have these columns:
- `Date` - Date in MM/DD/YYYY format
- `Price` - Closing price 
- `Open` - Opening price
- `High` - High price
- `Low` - Low price
- `Vol.` - Volume (supports K, M, B, T suffixes)

## 🚀 Usage

### **Import All Data**
```bash
python import_historical_data.py
```

### **Import by Asset Type**
```bash
python import_historical_data.py --asset_type stocks
python import_historical_data.py --asset_type crypto
python import_historical_data.py --asset_type commodities
python import_historical_data.py --asset_type indexes
```

### **Import Specific Symbol**
```bash
python import_historical_data.py --symbol AAPL
python import_historical_data.py --symbol BTC
```

### **Import Limited Rows (Testing)**
```bash
python import_historical_data.py --limit 10        # Import only first 10 rows per file
python import_historical_data.py --symbol AAPL --limit 30  # Import 30 days of AAPL data
```

### **Custom Database Connection**
```bash
python import_historical_data.py --server MYSERVER --database MyPortfolio
```

## 📁 Expected Folder Structure

```
scripts/
├── data/
│   ├── stocks/
│   │   ├── APPLE.csv           → AAPL
│   │   ├── ALPHABET.csv        → GOOGL
│   │   ├── META.csv            → META
│   │   ├── GALP.csv            → GALP
│   │   ├── EDP.csv             → EDP
│   │   ├── VALE.csv            → VALE
│   │   ├── PETROBRAS.csv       → PBR
│   │   └── BANCO_BRASIL.csv    → BBAS3
│   ├── crypto/
│   │   ├── Bitcoin Historical Data.csv      → BTC
│   │   ├── Ethereum Historical Data.csv     → ETH
│   │   ├── XRP Historical Data.csv          → XRP
│   │   ├── Cardano Historical Data.csv      → ADA
│   │   ├── Dogecoin Historical Data.csv     → DOGE
│   │   └── Solana Historical Data.csv       → SOL
│   ├── commodities/
│   │   ├── Crude Oil WTI Futures Historical Data.csv     → CL
│   │   ├── Natural Gas Futures Historical Data.csv       → NG
│   │   ├── Gold Futures Historical Data.csv              → GC
│   │   ├── Silver Futures Historical Data.csv            → SI
│   │   ├── Copper Futures Historical Data.csv            → HG
│   │   └── Cocoa Futures Historical Data.csv             → CC
│   └── indexes/
│       ├── S&P 500 Historical Data.csv                   → SPX
│       ├── Dow Jones Industrial Average Historical Data.csv → DJI
│       ├── US Tech 100 Historical Data.csv               → NDX
│       ├── PSI 20 Historical Data.csv                    → PSI20
│       ├── Bovespa Historical Data.csv                   → BVSP
│       ├── FTSE 100 Historical Data.csv                  → UKX
│       ├── DAX Historical Data.csv                       → DAX
│       └── CAC 40 Historical Data.csv                    → CAC
├── import_historical_data.py
├── requirements.txt
└── README.md
```

## 📊 What the Script Does

1. **Connects** to SQL Server database using Windows Authentication
2. **Loads** asset mapping (Symbol → AssetID) from `portfolio.Assets`
3. **Parses** CSV files with proper data type conversion:
   - Dates: MM/DD/YYYY → DATETIME
   - Prices: String → DECIMAL(18,2)
   - Volume: "70.82M" → 70,820,000 (integer)
4. **Imports** data using `portfolio.sp_import_asset_price` stored procedure
5. **Logs** progress and errors to console and `import_log.txt`

## 🔍 Verification Queries

After import, verify data with these SQL queries:

```sql
-- Check total imported records
SELECT 
    a.Symbol,
    a.AssetType,
    COUNT(ap.PriceID) as PriceRecords,
    MIN(ap.AsOf) as EarliestDate,
    MAX(ap.AsOf) as LatestDate
FROM portfolio.Assets a
LEFT JOIN portfolio.AssetPrices ap ON a.AssetID = ap.AssetID
GROUP BY a.Symbol, a.AssetType
ORDER BY a.AssetType, a.Symbol;

-- Check recent AAPL prices
SELECT TOP 10 
    AsOf, Price, OpenPrice, HighPrice, LowPrice, Volume
FROM portfolio.AssetPrices ap
JOIN portfolio.Assets a ON ap.AssetID = a.AssetID
WHERE a.Symbol = 'AAPL'
ORDER BY AsOf DESC;
```

## 🛠️ Troubleshooting

### **Common Issues:**

1. **"Module 'pyodbc' not found"**
   ```bash
   pip install pyodbc
   ```

2. **"Unable to connect to database"**
   - Check SQL Server is running
   - Verify Windows Authentication is enabled
   - Test connection: `sqlcmd -S localhost -E`

3. **"Symbol XXX not found in database"** 
   - Run asset seeding scripts first:
     - `database/seed/001_assets_basic.sql`
     - `database/seed/002_asset_details.sql`

4. **"File not found" errors**
   - Check CSV files exist in correct folders
   - Verify file names match expected patterns

5. **Date parsing errors**
   - Ensure dates are in MM/DD/YYYY format
   - Check for empty/invalid date cells

### **Performance Tips:**
- Use `--limit 10` for testing
- Import by asset type for parallel processing
- Monitor `import_log.txt` for detailed progress

## 📈 Expected Results

**Successful import will show:**
```
2025-06-01 10:45:00 - INFO - === meuPortfolio Historical Data Import ===
2025-06-01 10:45:00 - INFO - Connected to database: localhost/p6g4
2025-06-01 10:45:00 - INFO - Loaded 28 assets from database
2025-06-01 10:45:00 - INFO - Found 28 files to process
2025-06-01 10:45:01 - INFO - Processing AAPL: data/stocks/APPLE.csv
2025-06-01 10:45:01 - INFO - Loaded 102 rows from data/stocks/APPLE.csv
2025-06-01 10:45:02 - INFO - Completed AAPL: 102 success, 0 errors
...
2025-06-01 10:50:00 - INFO - Import completed: 28/28 files processed successfully
2025-06-01 10:50:00 - INFO - ✅ Import completed successfully!
```

---

**Ready to import your historical data!** 🚀 