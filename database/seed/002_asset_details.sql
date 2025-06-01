/* ============================================================
meuPortfolio – Asset Details Seed Data v2.0
Populate asset-specific details with current market data as of June 1, 2025
============================================================ */

USE p6g4;
GO

PRINT 'Starting asset details seeding process...';
PRINT 'Populating asset-specific details (June 1, 2025)';
PRINT '';

BEGIN TRANSACTION;

-- ============================================================
-- 1. STOCK DETAILS
-- ============================================================

PRINT 'Seeding STOCK DETAILS...';

-- Apple Inc. (AAPL)
DECLARE @AppleID INT;
SELECT @AppleID = AssetID FROM portfolio.Assets WHERE Symbol = 'AAPL';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @AppleID,
    @Sector = 'Technology',
    @Country = 'United States',
    @MarketCap = 2999000000000.00; -- $2.999 Trillion

-- Alphabet Inc. Class A (GOOGL)
DECLARE @AlphabetID INT;
SELECT @AlphabetID = AssetID FROM portfolio.Assets WHERE Symbol = 'GOOGL';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @AlphabetID,
    @Sector = 'Technology',
    @Country = 'United States',
    @MarketCap = 2090000000000.00; -- $2.090 Trillion

-- Meta Platforms Inc. (META)
DECLARE @MetaID INT;
SELECT @MetaID = AssetID FROM portfolio.Assets WHERE Symbol = 'META';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @MetaID,
    @Sector = 'Technology',
    @Country = 'United States',
    @MarketCap = 1232000000000.00; -- $1.232 Trillion

-- Galp Energia SGPS SA (GALP)
DECLARE @GalpID INT;
SELECT @GalpID = AssetID FROM portfolio.Assets WHERE Symbol = 'GALP';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @GalpID,
    @Sector = 'Energy',
    @Country = 'Portugal',
    @MarketCap = 14000000000.00; -- $14 Billion

-- EDP - Energias de Portugal SA (EDP)
DECLARE @EDPID INT;
SELECT @EDPID = AssetID FROM portfolio.Assets WHERE Symbol = 'EDP';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @EDPID,
    @Sector = 'Utilities',
    @Country = 'Portugal',
    @MarketCap = 14417000000.00; -- $14.417 Billion

-- Vale SA (VALE)
DECLARE @ValeID INT;
SELECT @ValeID = AssetID FROM portfolio.Assets WHERE Symbol = 'VALE';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @ValeID,
    @Sector = 'Basic Materials',
    @Country = 'Brazil',
    @MarketCap = 57000000000.00; -- $57 Billion

-- Petróleo Brasileiro SA (PBR)
DECLARE @PetrobrasID INT;
SELECT @PetrobrasID = AssetID FROM portfolio.Assets WHERE Symbol = 'PBR';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @PetrobrasID,
    @Sector = 'Energy',
    @Country = 'Brazil',
    @MarketCap = 121770000000.00; -- $121.77 Billion

-- Banco do Brasil SA (BBAS3)
DECLARE @BancoID INT;
SELECT @BancoID = AssetID FROM portfolio.Assets WHERE Symbol = 'BBAS3';
EXEC portfolio.sp_UpsertStockDetails 
    @AssetID = @BancoID,
    @Sector = 'Financial Services',
    @Country = 'Brazil',
    @MarketCap = 59850000000.00; -- $59.85 Billion

-- ============================================================
-- 2. CRYPTOCURRENCY DETAILS
-- ============================================================

PRINT 'Seeding CRYPTOCURRENCY DETAILS...';

-- Bitcoin (BTC)
DECLARE @BitcoinID INT;
SELECT @BitcoinID = AssetID FROM portfolio.Assets WHERE Symbol = 'BTC';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @BitcoinID,
    @Blockchain = 'Bitcoin',
    @MaxSupply = 21000000,
    @CirculatingSupply = 19872915;

-- Ethereum (ETH)
DECLARE @EthereumID INT;
SELECT @EthereumID = AssetID FROM portfolio.Assets WHERE Symbol = 'ETH';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @EthereumID,
    @Blockchain = 'Ethereum',
    @MaxSupply = NULL, -- No maximum supply
    @CirculatingSupply = 120279464;

-- XRP (XRP)
DECLARE @XRPID INT;
SELECT @XRPID = AssetID FROM portfolio.Assets WHERE Symbol = 'XRP';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @XRPID,
    @Blockchain = 'XRP Ledger',
    @MaxSupply = 100000000000,
    @CirculatingSupply = 56931242696;

-- Cardano (ADA)
DECLARE @CardanoID INT;
SELECT @CardanoID = AssetID FROM portfolio.Assets WHERE Symbol = 'ADA';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @CardanoID,
    @Blockchain = 'Cardano',
    @MaxSupply = 45000000000,
    @CirculatingSupply = 35045020830;

-- Dogecoin (DOGE)
DECLARE @DogecoinID INT;
SELECT @DogecoinID = AssetID FROM portfolio.Assets WHERE Symbol = 'DOGE';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @DogecoinID,
    @Blockchain = 'Dogecoin',
    @MaxSupply = NULL, -- No maximum supply
    @CirculatingSupply = 145066626384;

-- Solana (SOL)
DECLARE @SolanaID INT;
SELECT @SolanaID = AssetID FROM portfolio.Assets WHERE Symbol = 'SOL';
EXEC portfolio.sp_UpsertCryptoDetails 
    @AssetID = @SolanaID,
    @Blockchain = 'Solana',
    @MaxSupply = NULL, -- No maximum supply
    @CirculatingSupply = 467113329;

-- ============================================================
-- 3. COMMODITY DETAILS
-- ============================================================

PRINT 'Seeding COMMODITY DETAILS...';

-- Crude Oil WTI Futures (CL)
DECLARE @CrudeOilID INT;
SELECT @CrudeOilID = AssetID FROM portfolio.Assets WHERE Symbol = 'CL';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @CrudeOilID,
    @Category = 'Energy',
    @Unit = 'barrel';

-- Natural Gas Futures (NG)
DECLARE @NaturalGasID INT;
SELECT @NaturalGasID = AssetID FROM portfolio.Assets WHERE Symbol = 'NG';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @NaturalGasID,
    @Category = 'Energy',
    @Unit = 'million BTU';

-- Gold Futures (GC)
DECLARE @GoldID INT;
SELECT @GoldID = AssetID FROM portfolio.Assets WHERE Symbol = 'GC';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @GoldID,
    @Category = 'Precious Metals',
    @Unit = 'troy ounce';

-- Silver Futures (SI)
DECLARE @SilverID INT;
SELECT @SilverID = AssetID FROM portfolio.Assets WHERE Symbol = 'SI';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @SilverID,
    @Category = 'Precious Metals',
    @Unit = 'troy ounce';

-- Copper Futures (HG)
DECLARE @CopperID INT;
SELECT @CopperID = AssetID FROM portfolio.Assets WHERE Symbol = 'HG';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @CopperID,
    @Category = 'Industrial Metals',
    @Unit = 'pound';

-- Cocoa Futures (CC)
DECLARE @CocoaID INT;
SELECT @CocoaID = AssetID FROM portfolio.Assets WHERE Symbol = 'CC';
EXEC portfolio.sp_UpsertCommodityDetails 
    @AssetID = @CocoaID,
    @Category = 'Agriculture',
    @Unit = 'metric ton';

-- ============================================================
-- 4. INDEX DETAILS
-- ============================================================

PRINT 'Seeding INDEX DETAILS...';

-- S&P 500 (SPX)
DECLARE @SPXID INT;
SELECT @SPXID = AssetID FROM portfolio.Assets WHERE Symbol = 'SPX';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @SPXID,
    @Country = 'United States',
    @Region = 'North America',
    @IndexType = 'Broad Market',
    @ComponentCount = 500;

-- Dow Jones Industrial Average (DJI)
DECLARE @DJIID INT;
SELECT @DJIID = AssetID FROM portfolio.Assets WHERE Symbol = 'DJI';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @DJIID,
    @Country = 'United States',
    @Region = 'North America',
    @IndexType = 'Large Cap',
    @ComponentCount = 30;

-- Nasdaq 100 (NDX)
DECLARE @NDXID INT;
SELECT @NDXID = AssetID FROM portfolio.Assets WHERE Symbol = 'NDX';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @NDXID,
    @Country = 'United States',
    @Region = 'North America',
    @IndexType = 'Technology Heavy',
    @ComponentCount = 100;

-- PSI 20 (PSI20)
DECLARE @PSI20ID INT;
SELECT @PSI20ID = AssetID FROM portfolio.Assets WHERE Symbol = 'PSI20';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @PSI20ID,
    @Country = 'Portugal',
    @Region = 'Europe',
    @IndexType = 'Broad Market',
    @ComponentCount = 20;

-- Bovespa (BVSP)
DECLARE @BVSPID INT;
SELECT @BVSPID = AssetID FROM portfolio.Assets WHERE Symbol = 'BVSP';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @BVSPID,
    @Country = 'Brazil',
    @Region = 'South America',
    @IndexType = 'Broad Market',
    @ComponentCount = 65;

-- FTSE 100 (UKX)
DECLARE @UKXID INT;
SELECT @UKXID = AssetID FROM portfolio.Assets WHERE Symbol = 'UKX';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @UKXID,
    @Country = 'United Kingdom',
    @Region = 'Europe',
    @IndexType = 'Large Cap',
    @ComponentCount = 100;

-- DAX (DAX)
DECLARE @DAXID INT;
SELECT @DAXID = AssetID FROM portfolio.Assets WHERE Symbol = 'DAX';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @DAXID,
    @Country = 'Germany',
    @Region = 'Europe',
    @IndexType = 'Large Cap',
    @ComponentCount = 40;

-- CAC 40 (CAC)
DECLARE @CACID INT;
SELECT @CACID = AssetID FROM portfolio.Assets WHERE Symbol = 'CAC';
EXEC portfolio.sp_UpsertIndexDetails 
    @AssetID = @CACID,
    @Country = 'France',
    @Region = 'Europe',
    @IndexType = 'Large Cap',
    @ComponentCount = 40;

COMMIT TRANSACTION;

PRINT 'Asset details seeding completed successfully!';
