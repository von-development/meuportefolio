#!/usr/bin/env python3
"""
meuPortfolio - Historical Data Import Script
============================================
Imports historical price data from CSV files into the database
using the portfolio.sp_import_asset_price stored procedure.

Requirements:
- pyodbc: pip install pyodbc
- pandas: pip install pandas
- python-dotenv: pip install python-dotenv

Usage:
    python import_historical_data.py [--asset_type] [--symbol] [--limit]
    
Examples:
    python import_historical_data.py                    # Import all data
    python import_historical_data.py --asset_type stocks # Import only stocks
    python import_historical_data.py --symbol AAPL      # Import only AAPL
    python import_historical_data.py --limit 30         # Import last 30 days only
"""

import pyodbc
import pandas as pd
import os
import re
import argparse
from datetime import datetime
from decimal import Decimal
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('import_log.txt'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class HistoricalDataImporter:
    def __init__(self, server=None, database=None, user=None, password=None, port=None):
        """Initialize database connection"""
        # Load from environment variables if not provided
        self.server = server or os.getenv('DATABASE_HOST', 'localhost')
        self.database = database or os.getenv('DATABASE_NAME', 'p6g4')
        self.user = user or os.getenv('DATABASE_USER')
        self.password = password or os.getenv('DATABASE_PASSWORD')
        self.port = port or os.getenv('DATABASE_PORT', '1433')
        self.driver = os.getenv('DATABASE_DRIVER', 'ODBC Driver 17 for SQL Server')
        self.timeout = os.getenv('DATABASE_TIMEOUT', '30')
        
        self.connection = None
        self.asset_mapping = {}  # Symbol -> AssetID mapping
        
        # Log connection details (without password)
        logger.info(f"Database config: {self.server}:{self.port}/{self.database} (User: {self.user})")
        
    def connect(self):
        """Establish database connection"""
        try:
            # Build connection string for SQL Server authentication
            if self.user and self.password:
                conn_str = (
                    f"DRIVER={{{self.driver}}};"
                    f"SERVER={self.server},{self.port};"
                    f"DATABASE={self.database};"
                    f"UID={self.user};"
                    f"PWD={self.password};"
                    f"Connection Timeout={self.timeout};"
                )
            else:
                # Fall back to Windows Authentication
                conn_str = (
                    f"DRIVER={{{self.driver}}};"
                    f"SERVER={self.server},{self.port};"
                    f"DATABASE={self.database};"
                    f"Trusted_Connection=yes;"
                    f"Connection Timeout={self.timeout};"
                )
            
            self.connection = pyodbc.connect(conn_str)
            logger.info(f"Connected to database: {self.server}:{self.port}/{self.database}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            logger.error(f"Connection details: {self.server}:{self.port}/{self.database}")
            return False
    
    def load_asset_mapping(self):
        """Load symbol to AssetID mapping from database"""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT AssetID, Symbol, AssetType FROM portfolio.Assets")
            
            for row in cursor.fetchall():
                asset_id, symbol, asset_type = row
                self.asset_mapping[symbol] = {
                    'AssetID': asset_id,
                    'AssetType': asset_type
                }
            
            logger.info(f"Loaded {len(self.asset_mapping)} assets from database")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load asset mapping: {e}")
            return False
    
    def parse_volume_string(self, volume_str):
        """Convert volume string like '70.82M' to integer"""
        if pd.isna(volume_str) or volume_str == '':
            return 0
            
        volume_str = str(volume_str).strip().upper()
        
        # Remove any commas
        volume_str = volume_str.replace(',', '')
        
        # Handle different suffixes
        multipliers = {
            'K': 1_000,
            'M': 1_000_000,
            'B': 1_000_000_000,
            'T': 1_000_000_000_000
        }
        
        for suffix, multiplier in multipliers.items():
            if volume_str.endswith(suffix):
                try:
                    number = float(volume_str[:-1])
                    return int(number * multiplier)
                except ValueError:
                    pass
        
        # Try to parse as direct number
        try:
            return int(float(volume_str))
        except ValueError:
            logger.warning(f"Could not parse volume: {volume_str}")
            return 0
    
    def parse_change_percent(self, change_str):
        """Convert change percentage string like '0.45%' to decimal"""
        if pd.isna(change_str) or change_str == '':
            return None
            
        try:
            # Remove % sign and convert to float
            clean_change = str(change_str).strip().replace('%', '')
            return float(clean_change)
        except ValueError:
            logger.warning(f"Could not parse change percentage: {change_str}")
            return None
    
    def parse_price(self, price_str):
        """Convert price string to decimal"""
        if pd.isna(price_str) or price_str == '':
            return 0.0
            
        try:
            # Remove any commas and convert to float
            clean_price = str(price_str).replace(',', '')
            return float(clean_price)
        except ValueError:
            logger.warning(f"Could not parse price: {price_str}")
            return 0.0
    
    def parse_date(self, date_str):
        """Parse date string to datetime"""
        try:
            # Try MM/DD/YYYY format first
            return datetime.strptime(date_str, '%m/%d/%Y')
        except ValueError:
            try:
                # Try DD/MM/YYYY format
                return datetime.strptime(date_str, '%d/%m/%Y')
            except ValueError:
                try:
                    # Try YYYY-MM-DD format
                    return datetime.strptime(date_str, '%Y-%m-%d')
                except ValueError:
                    logger.error(f"Could not parse date: {date_str}")
                    return None
    
    def get_csv_files(self, asset_type=None, symbol=None):
        """Get list of CSV files to process"""
        data_dir = 'data'
        csv_files = []
        
        # Define folder mapping
        folder_mapping = {
            'stocks': ['APPLE.csv', 'ALPHABET.csv', 'META.csv', 'GALP.csv', 
                      'EDP.csv', 'VALE.csv', 'PETROBRAS.csv', 'BANCO_BRASIL.csv'],
            'crypto': ['Bitcoin Historical Data.csv', 'Ethereum Historical Data.csv',
                      'XRP Historical Data.csv', 'Cardano Historical Data.csv',
                      'Dogecoin Historical Data.csv', 'Solana Historical Data.csv'],
            'commodities': ['Crude Oil WTI Futures Historical Data.csv', 
                           'Natural Gas Futures Historical Data.csv',
                           'Gold Futures Historical Data.csv', 
                           'Silver Futures Historical Data.csv',
                           'Copper Futures Historical Data.csv', 
                           'Cocoa Futures Historical Data.csv'],
            'indexes': ['S&P 500 Historical Data.csv', 'Dow Jones Industrial Average Historical Data.csv',
                       'US Tech 100 Historical Data.csv', 'PSI 20 Historical Data.csv',
                       'Bovespa Historical Data.csv', 'FTSE 100 Historical Data.csv',
                       'DAX Historical Data.csv', 'CAC 40 Historical Data.csv']
        }
        
        # Symbol to filename mapping
        symbol_to_file = {
            # Stocks
            'AAPL': 'stocks/APPLE.csv',
            'GOOGL': 'stocks/Alphabet A Stock Price Histor.csv', 
            'META': 'stocks/Meta Platforms Stock Price History.csv',
            'GALP': 'stocks/Galp Energia Stock Price History.csv',
            'EDP': 'stocks/EDP Stock Price History.csv',
            'VALE': 'stocks/Vale DRC Stock Price History.csv',
            'PBR': 'stocks/PETROBRAS PN Stock Price History.csv',
            'BBAS3': 'stocks/Banco Do Brasil SA Stock Price History.csv',
            
            # Crypto
            'BTC': 'crypto/Bitcoin Historical Data.csv',
            'ETH': 'crypto/Ethereum Historical Data.csv',
            'XRP': 'crypto/XRP Historical Data.csv',
            'ADA': 'crypto/Cardano Historical Data.csv',
            'DOGE': 'crypto/Dogecoin Historical Data.csv',
            'SOL': 'crypto/Solana Historical Data.csv',
            
            # Commodities
            'CL': 'commodities/Crude Oil WTI Futures Historical Data.csv',
            'NG': 'commodities/Natural Gas Futures Historical Data.csv',
            'GC': 'commodities/Gold Futures Historical Data.csv',
            'SI': 'commodities/Silver Futures Historical Data.csv',
            'HG': 'commodities/Copper Futures Historical Data.csv',
            'CC': 'commodities/London Cocoa Futures Historical Data.csv',
            
            # Indexes
            'SPX': 'indexes/S&P 500 Historical Data.csv',
            'DJI': 'indexes/Dow Jones Industrial Average Historical Data.csv',
            'NDX': 'indexes/Nasdaq 100 Historical Data.csv',
            'PSI20': 'indexes/PSI Historical Data.csv',
            'BVSP': 'indexes/Bovespa Historical Data.csv',
            'UKX': 'indexes/FTSE 100 Historical Data.csv',
            'DAX': 'indexes/DAX Historical Data.csv',
            'CAC': 'indexes/CAC 40 Historical Data.csv'
        }
        
        if symbol:
            # Import specific symbol
            if symbol in symbol_to_file:
                file_path = os.path.join(data_dir, symbol_to_file[symbol])
                if os.path.exists(file_path):
                    csv_files.append((symbol, file_path))
                else:
                    logger.warning(f"File not found for symbol {symbol}: {file_path}")
        else:
            # Import by asset type or all
            for sym, file_rel_path in symbol_to_file.items():
                if asset_type and not file_rel_path.startswith(asset_type):
                    continue
                    
                file_path = os.path.join(data_dir, file_rel_path)
                if os.path.exists(file_path):
                    csv_files.append((sym, file_path))
        
        return csv_files
    
    def import_csv_file(self, symbol, file_path, limit_rows=None):
        """Import data from a single CSV file"""
        logger.info(f"Processing {symbol}: {file_path}")
        
        if symbol not in self.asset_mapping:
            logger.error(f"Symbol {symbol} not found in database")
            return False
        
        asset_id = self.asset_mapping[symbol]['AssetID']
        
        try:
            # Read CSV file
            df = pd.read_csv(file_path)
            
            # Limit rows if specified
            if limit_rows:
                df = df.head(limit_rows)
            
            logger.info(f"Loaded {len(df)} rows from {file_path}")
            
            success_count = 0
            error_count = 0
            
            cursor = self.connection.cursor()
            
            for index, row in df.iterrows():
                try:
                    # Parse data from CSV
                    date_str = str(row['Date']).strip()
                    price_date = self.parse_date(date_str)
                    
                    if not price_date:
                        error_count += 1
                        continue
                    
                    price = self.parse_price(row['Price'])
                    open_price = self.parse_price(row['Open'])
                    high_price = self.parse_price(row['High'])
                    low_price = self.parse_price(row['Low'])
                    volume = self.parse_volume_string(row['Vol.'])
                    change_percent = self.parse_change_percent(row['Change %'])
                    
                    # Skip if essential data is missing
                    if price <= 0 or open_price <= 0:
                        logger.warning(f"Skipping row {index}: invalid price data")
                        error_count += 1
                        continue
                    
                    # Call stored procedure
                    cursor.execute("""
                        EXEC portfolio.sp_import_asset_price 
                            @AssetID = ?, 
                            @Price = ?, 
                            @PriceDate = ?, 
                            @OpenPrice = ?, 
                            @HighPrice = ?, 
                            @LowPrice = ?, 
                            @Volume = ?,
                            @ChangePercent = ?,
                            @UpdateCurrentPrice = 0
                    """, asset_id, price, price_date, open_price, high_price, low_price, volume, change_percent)
                    
                    success_count += 1
                    
                    if success_count % 10 == 0:
                        logger.info(f"Imported {success_count} records for {symbol}")
                
                except Exception as e:
                    logger.error(f"Error importing row {index} for {symbol}: {e}")
                    error_count += 1
            
            # Commit all changes for this file
            self.connection.commit()
            
            logger.info(f"Completed {symbol}: {success_count} success, {error_count} errors")
            return True
            
        except Exception as e:
            logger.error(f"Failed to process {file_path}: {e}")
            return False
    
    def import_all_data(self, asset_type=None, symbol=None, limit_rows=None):
        """Import all historical data"""
        if not self.connect():
            return False
        
        if not self.load_asset_mapping():
            return False
        
        csv_files = self.get_csv_files(asset_type, symbol)
        
        if not csv_files:
            logger.warning("No CSV files found to process")
            return False
        
        logger.info(f"Found {len(csv_files)} files to process")
        
        success_files = 0
        total_files = len(csv_files)
        
        for symbol, file_path in csv_files:
            if self.import_csv_file(symbol, file_path, limit_rows):
                success_files += 1
        
        logger.info(f"Import completed: {success_files}/{total_files} files processed successfully")
        
        if self.connection:
            self.connection.close()
        
        return success_files == total_files


def main():
    parser = argparse.ArgumentParser(description='Import historical price data from CSV files')
    parser.add_argument('--asset_type', choices=['stocks', 'crypto', 'commodities', 'indexes'], 
                       help='Import only specific asset type')
    parser.add_argument('--symbol', help='Import only specific symbol (e.g., AAPL)')
    parser.add_argument('--limit', type=int, help='Limit number of rows per file')
    parser.add_argument('--server', help='Database server (overrides .env)')
    parser.add_argument('--database', help='Database name (overrides .env)')
    parser.add_argument('--user', help='Database user (overrides .env)')
    parser.add_argument('--password', help='Database password (overrides .env)')
    parser.add_argument('--port', help='Database port (overrides .env)')
    
    args = parser.parse_args()
    
    logger.info("=== meuPortfolio Historical Data Import ===")
    logger.info(f"Asset Type: {args.asset_type or 'All'}")
    logger.info(f"Symbol: {args.symbol or 'All'}")
    logger.info(f"Row Limit: {args.limit or 'None'}")
    
    # Create importer with optional command line overrides
    importer = HistoricalDataImporter(
        server=args.server,
        database=args.database,
        user=args.user,
        password=args.password,
        port=args.port
    )
    
    success = importer.import_all_data(
        asset_type=args.asset_type,
        symbol=args.symbol,
        limit_rows=args.limit
    )
    
    if success:
        logger.info("[SUCCESS] Import completed successfully!")
        exit(0)
    else:
        logger.error("[FAILED] Import failed!")
        exit(1)


if __name__ == "__main__":
    main() 