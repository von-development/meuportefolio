/* ============================================================
meuPortfolio – Asset Seed Data v2.0
Basic asset creation with current market data as of June 1, 2025
============================================================ */

USE p6g4;
GO

PRINT 'Starting asset seeding process...';
PRINT 'Creating basic assets with current market data (June 1, 2025)';
PRINT '';

BEGIN TRANSACTION;

-- ============================================================
-- 1. STOCKS (8 assets)
-- ============================================================

PRINT 'Seeding STOCKS...';

-- Apple Inc.
DECLARE @AppleAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'AAPL',
    @Name = 'Apple Inc.',
    @AssetType = 'Stock',
    @InitialPrice = 200.85,
    @InitialVolume = 70820000,
    @AvailableShares = 15440000000.0,
    @AssetID = @AppleAssetID OUTPUT;

-- Alphabet Inc. Class A
DECLARE @AlphabetAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'GOOGL',
    @Name = 'Alphabet Inc. Class A',
    @AssetType = 'Stock',
    @InitialPrice = 175.25,
    @InitialVolume = 25000000,
    @AvailableShares = 12300000000.0,
    @AssetID = @AlphabetAssetID OUTPUT;

-- Meta Platforms Inc.
DECLARE @MetaAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'META',
    @Name = 'Meta Platforms Inc.',
    @AssetType = 'Stock',
    @InitialPrice = 485.30,
    @InitialVolume = 18500000,
    @AvailableShares = 2540000000.0,
    @AssetID = @MetaAssetID OUTPUT;

-- Galp Energia SGPS SA
DECLARE @GalpAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'GALP',
    @Name = 'Galp Energia SGPS SA',
    @AssetType = 'Stock',
    @InitialPrice = 16.85,
    @InitialVolume = 2500000,
    @AvailableShares = 830000000.0,
    @AssetID = @GalpAssetID OUTPUT;

-- EDP - Energias de Portugal SA
DECLARE @EDPAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'EDP',
    @Name = 'EDP - Energias de Portugal SA',
    @AssetType = 'Stock',
    @InitialPrice = 3.95,
    @InitialVolume = 15000000,
    @AvailableShares = 3650000000.0,
    @AssetID = @EDPAssetID OUTPUT;

-- Vale SA
DECLARE @ValeAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'VALE',
    @Name = 'Vale SA',
    @AssetType = 'Stock',
    @InitialPrice = 12.45,
    @InitialVolume = 28000000,
    @AvailableShares = 4580000000.0,
    @AssetID = @ValeAssetID OUTPUT;

-- Petróleo Brasileiro SA (Petrobras)
DECLARE @PetrobrasAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'PBR',
    @Name = 'Petróleo Brasileiro SA',
    @AssetType = 'Stock',
    @InitialPrice = 14.85,
    @InitialVolume = 35000000,
    @AvailableShares = 8200000000.0,
    @AssetID = @PetrobrasAssetID OUTPUT;

-- Banco do Brasil SA
DECLARE @BancoAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'BBAS3',
    @Name = 'Banco do Brasil SA',
    @AssetType = 'Stock',
    @InitialPrice = 28.50,
    @InitialVolume = 12000000,
    @AvailableShares = 2100000000.0,
    @AssetID = @BancoAssetID OUTPUT;

-- ============================================================
-- 2. CRYPTOCURRENCIES (6 assets)
-- ============================================================

PRINT 'Seeding CRYPTOCURRENCIES...';

-- Bitcoin
DECLARE @BitcoinAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'BTC',
    @Name = 'Bitcoin',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 104167.60,
    @InitialVolume = 29530,
    @AvailableShares = 19872915.0,
    @AssetID = @BitcoinAssetID OUTPUT;

-- Ethereum
DECLARE @EthereumAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'ETH',
    @Name = 'Ethereum',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 2501.66,
    @InitialVolume = 850000,
    @AvailableShares = 120279464.0,
    @AssetID = @EthereumAssetID OUTPUT;

-- XRP
DECLARE @XRPAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'XRP',
    @Name = 'XRP',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 2.14,
    @InitialVolume = 2500000,
    @AvailableShares = 56931242696.0,
    @AssetID = @XRPAssetID OUTPUT;

-- Cardano
DECLARE @CardanoAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'ADA',
    @Name = 'Cardano',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 0.6646,
    @InitialVolume = 1200000,
    @AvailableShares = 35045020830.0,
    @AssetID = @CardanoAssetID OUTPUT;

-- Dogecoin
DECLARE @DogecoinAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'DOGE',
    @Name = 'Dogecoin',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 0.1888,
    @InitialVolume = 3800000,
    @AvailableShares = 145066626384.0,
    @AssetID = @DogecoinAssetID OUTPUT;

-- Solana
DECLARE @SolanaAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'SOL',
    @Name = 'Solana',
    @AssetType = 'Cryptocurrency',
    @InitialPrice = 152.80,
    @InitialVolume = 950000,
    @AvailableShares = 467113329.0,
    @AssetID = @SolanaAssetID OUTPUT;

-- ============================================================
-- 3. COMMODITIES (6 assets)
-- ============================================================

PRINT 'Seeding COMMODITIES...';

-- Crude Oil WTI Futures
DECLARE @CrudeOilAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'CL',
    @Name = 'Crude Oil WTI Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 77.15,
    @InitialVolume = 425000,
    @AvailableShares = 2500000.0,  -- Realistic open interest for WTI futures
    @AssetID = @CrudeOilAssetID OUTPUT;

-- Natural Gas Futures
DECLARE @NaturalGasAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'NG',
    @Name = 'Natural Gas Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 2.95,
    @InitialVolume = 180000,
    @AvailableShares = 1200000.0,  -- Realistic open interest for NG futures
    @AssetID = @NaturalGasAssetID OUTPUT;

-- Gold Futures
DECLARE @GoldAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'GC',
    @Name = 'Gold Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 3315.40,
    @InitialVolume = 19000,
    @AvailableShares = 500000.0,   -- Realistic open interest for Gold futures
    @AssetID = @GoldAssetID OUTPUT;

-- Silver Futures
DECLARE @SilverAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'SI',
    @Name = 'Silver Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 32.89,
    @InitialVolume = 248160,
    @AvailableShares = 150000.0,   -- Realistic open interest for Silver futures
    @AssetID = @SilverAssetID OUTPUT;

-- Copper Futures
DECLARE @CopperAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'HG',
    @Name = 'Copper Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 4.65,
    @InitialVolume = 125000,
    @AvailableShares = 300000.0,   -- Realistic open interest for Copper futures
    @AssetID = @CopperAssetID OUTPUT;

-- Cocoa Futures
DECLARE @CocoaAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'CC',
    @Name = 'Cocoa Futures',
    @AssetType = 'Commodity',
    @InitialPrice = 8850.00,
    @InitialVolume = 15000,
    @AvailableShares = 80000.0,    -- Realistic open interest for Cocoa futures
    @AssetID = @CocoaAssetID OUTPUT;

-- ============================================================
-- 4. INDEXES (8 assets)
-- ============================================================

PRINT 'Seeding INDEXES...';

-- S&P 500
DECLARE @SPXAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'SPX',
    @Name = 'S&P 500 Index',
    @AssetType = 'Index',
    @InitialPrice = 5911.69,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @SPXAssetID OUTPUT;

-- Dow Jones Industrial Average
DECLARE @DJIAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'DJI',
    @Name = 'Dow Jones Industrial Average',
    @AssetType = 'Index',
    @InitialPrice = 42270.07,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @DJIAssetID OUTPUT;

-- Nasdaq 100
DECLARE @NDXAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'NDX',
    @Name = 'Nasdaq 100 Index',
    @AssetType = 'Index',
    @InitialPrice = 19113.77,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @NDXAssetID OUTPUT;

-- PSI 20 (Portugal)
DECLARE @PSI20AssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'PSI20',
    @Name = 'PSI 20 Index',
    @AssetType = 'Index',
    @InitialPrice = 6850.25,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @PSI20AssetID OUTPUT;

-- Bovespa (Brazil)
DECLARE @BVSPAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'BVSP',
    @Name = 'Bovespa Index',
    @AssetType = 'Index',
    @InitialPrice = 126850.00,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @BVSPAssetID OUTPUT;

-- FTSE 100 (UK)
DECLARE @UKXAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'UKX',
    @Name = 'FTSE 100 Index',
    @AssetType = 'Index',
    @InitialPrice = 8285.50,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @UKXAssetID OUTPUT;

-- DAX (Germany)
DECLARE @DAXAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'DAX',
    @Name = 'DAX Index',
    @AssetType = 'Index',
    @InitialPrice = 18650.75,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @DAXAssetID OUTPUT;

-- CAC 40 (France)
DECLARE @CACAssetID INT;
EXEC portfolio.sp_ensure_asset 
    @Symbol = 'CAC',
    @Name = 'CAC 40 Index',
    @AssetType = 'Index',
    @InitialPrice = 7915.25,
    @InitialVolume = 0,
    @AvailableShares = 1.0,        -- Index represents a single calculated unit
    @AssetID = @CACAssetID OUTPUT;

COMMIT TRANSACTION;

PRINT 'Asset seeding completed successfully!';
PRINT '';
PRINT 'SUMMARY:';
PRINT '✅ 8 Stocks created';
PRINT '✅ 6 Cryptocurrencies created';
PRINT '✅ 6 Commodities created';
PRINT '✅ 8 Indexes created';
PRINT '✅ Total: 28 assets created';
PRINT '';
PRINT 'Next step: Run 002_asset_details.sql to populate asset-specific details'; 