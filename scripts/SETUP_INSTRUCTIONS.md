# Setup Instructions for meuPortfolio Data Import

## 🔧 Environment Setup

### **Step 1: Create Environment File**
Rename the environment variables file:

```bash
# In the scripts folder
rename env_var.txt .env
```

Or using PowerShell:
```powershell
# In the scripts folder
Move-Item env_var.txt .env
```

Or manually:
- Right-click `env_var.txt`
- Select "Rename"
- Change name to `.env`

### **Step 2: Install Python Dependencies**
```bash
cd scripts
pip install -r requirements.txt
```

This will install:
- `pyodbc` - SQL Server connectivity
- `pandas` - Data processing
- `python-dotenv` - Environment variable loading

### **Step 3: Verify Environment File**
Your `.env` file should contain:
```
DATABASE_HOST=mednat.ieeta.pt
DATABASE_PORT=8101
DATABASE_USER=p6g4
DATABASE_PASSWORD=VictorMaria123
DATABASE_NAME=p6g4
DATABASE_INSTANCE=SQLSERVER
DATABASE_DRIVER=ODBC Driver 17 for SQL Server
DATABASE_TIMEOUT=30
```

## 🚀 Running the Import Script

### **Test Connection First**
```bash
python import_historical_data.py --symbol AAPL --limit 5
```

This will:
- Test database connection
- Import only 5 rows of AAPL data
- Show any connection issues

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

## 🔍 Expected Output

**Successful connection will show:**
```
2025-06-01 10:45:00 - INFO - === meuPortfolio Historical Data Import ===
2025-06-01 10:45:00 - INFO - Database config: mednat.ieeta.pt:8101/p6g4 (User: p6g4)
2025-06-01 10:45:01 - INFO - Connected to database: mednat.ieeta.pt:8101/p6g4
2025-06-01 10:45:01 - INFO - Loaded 28 assets from database
2025-06-01 10:45:01 - INFO - Found 1 files to process
2025-06-01 10:45:01 - INFO - Processing AAPL: data/stocks/APPLE.csv
2025-06-01 10:45:01 - INFO - Loaded 5 rows from data/stocks/APPLE.csv
2025-06-01 10:45:02 - INFO - Imported 10 records for AAPL
2025-06-01 10:45:02 - INFO - Completed AAPL: 5 success, 0 errors
2025-06-01 10:45:02 - INFO - Import completed: 1/1 files processed successfully
2025-06-01 10:45:02 - INFO - ✅ Import completed successfully!
```

## 🛠️ Troubleshooting

### **1. "Module not found" errors**
```bash
pip install -r requirements.txt
```

### **2. "Unable to connect to database"**
Check that:
- ✅ `.env` file exists and has correct values
- ✅ Database server `mednat.ieeta.pt:8101` is accessible
- ✅ User `p6g4` has correct password
- ✅ Database `p6g4` exists

### **3. Test database connection manually**
```bash
# Test with sqlcmd (if available)
sqlcmd -S mednat.ieeta.pt,8101 -d p6g4 -U p6g4 -P VictorMaria123

# Or test with Python
python -c "
import pyodbc
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=mednat.ieeta.pt,8101;DATABASE=p6g4;UID=p6g4;PWD=VictorMaria123')
print('✅ Connection successful!')
conn.close()
"
```

### **4. Override environment variables**
If you need to use different settings temporarily:
```bash
python import_historical_data.py --server localhost --user myuser --password mypass --database mydb
```

### **5. "Symbol XXX not found in database"**
Ensure you've run the asset seeding scripts:
- `database/seed/001_assets_basic.sql`
- `database/seed/002_asset_details.sql`

## 📊 Verification

After import, check the data in SQL Server:
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
```

## 🔐 Security Notes

- ⚠️ **Never commit `.env` files to version control**
- ✅ Add `.env` to your `.gitignore` file
- ✅ Use environment variables for sensitive data
- ✅ Consider using Azure Key Vault or similar for production

---

**Ready to import your data!** 🚀 