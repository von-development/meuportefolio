/* ============================================================
meuPortfolio – Trading Procedures v2.0
Asset trading operations with holdings management
============================================================ */

USE meuportefolio;
GO

/* ============================================================
1. ASSET TRADING - BUY OPERATIONS
============================================================ */

-- Buy asset with enhanced fund validation and holdings management
CREATE PROCEDURE portfolio.sp_BuyAsset (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @AssetID INT,
    @Quantity DECIMAL(18,6),
    @UnitPrice DECIMAL(18,4) = NULL -- If NULL, use current market price
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate inputs
        IF @Quantity <= 0
        BEGIN
            RAISERROR('Quantity must be positive', 16, 1);
            RETURN;
        END
        
        -- Check if portfolio belongs to user
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Portfolios 
            WHERE PortfolioID = @PortfolioID AND UserID = @UserID
        )
        BEGIN
            RAISERROR('Portfolio not found or does not belong to user', 16, 1);
            RETURN;
        END
        
        -- Get current asset price if not provided
        IF @UnitPrice IS NULL
        BEGIN
            SELECT @UnitPrice = Price 
            FROM portfolio.Assets 
            WHERE AssetID = @AssetID;
            
            IF @UnitPrice IS NULL
            BEGIN
                RAISERROR('Asset not found', 16, 1);
                RETURN;
            END
        END
        
        -- Calculate total cost
        DECLARE @TotalCost DECIMAL(18,2) = @Quantity * @UnitPrice;
        
        -- Check if portfolio has sufficient funds
        DECLARE @CurrentFunds DECIMAL(18,2);
        SELECT @CurrentFunds = CurrentFunds 
        FROM portfolio.Portfolios 
        WHERE PortfolioID = @PortfolioID;
        
        IF @CurrentFunds < @TotalCost
        BEGIN
            RAISERROR('Insufficient funds in portfolio for this purchase', 16, 1);
            RETURN;
        END
        
        -- Create transaction record
        INSERT INTO portfolio.Transactions (
            UserID, PortfolioID, AssetID, TransactionType, 
            Quantity, UnitPrice, Status
        ) VALUES (
            @UserID, @PortfolioID, @AssetID, 'Buy',
            @Quantity, @UnitPrice, 'Executed'
        );
        
        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();
        
        -- Update portfolio funds
        UPDATE portfolio.Portfolios 
        SET CurrentFunds = CurrentFunds - @TotalCost
        WHERE PortfolioID = @PortfolioID;
        
        -- Update or insert holdings
        IF EXISTS (SELECT 1 FROM portfolio.PortfolioHoldings WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID)
        BEGIN
            -- Update existing holding - calculate new average price
            UPDATE portfolio.PortfolioHoldings 
            SET QuantityHeld = QuantityHeld + @Quantity,
                AveragePrice = ((TotalCost + @TotalCost) / (QuantityHeld + @Quantity)),
                TotalCost = TotalCost + @TotalCost
            WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID;
        END
        ELSE
        BEGIN
            -- Create new holding
            INSERT INTO portfolio.PortfolioHoldings (
                PortfolioID, AssetID, QuantityHeld, AveragePrice, TotalCost
            ) VALUES (
                @PortfolioID, @AssetID, @Quantity, @UnitPrice, @TotalCost
            );
        END
        
        -- Record fund transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, PortfolioID, TransactionType, Amount, 
            BalanceAfter, Description, RelatedAssetTransactionID
        ) VALUES (
            @UserID, @PortfolioID, 'AssetPurchase', -@TotalCost,
            (SELECT CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID),
            CONCAT('Purchased ', @Quantity, ' shares of asset ID ', @AssetID),
            @TransactionID
        );
        
        COMMIT;
        
        -- Return success with transaction details
        SELECT 
            'SUCCESS' AS Status,
            @TransactionID AS TransactionID,
            @Quantity AS QuantityPurchased,
            @UnitPrice AS PricePerShare,
            @TotalCost AS TotalCost,
            (SELECT CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID) AS RemainingFunds;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
2. ASSET TRADING - SELL OPERATIONS
============================================================ */

-- Sell asset with holdings validation and management
CREATE PROCEDURE portfolio.sp_SellAsset (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @AssetID INT,
    @Quantity DECIMAL(18,6),
    @UnitPrice DECIMAL(18,4) = NULL -- If NULL, use current market price
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate inputs
        IF @Quantity <= 0
        BEGIN
            RAISERROR('Quantity must be positive', 16, 1);
            RETURN;
        END
        
        -- Check if portfolio belongs to user
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Portfolios 
            WHERE PortfolioID = @PortfolioID AND UserID = @UserID
        )
        BEGIN
            RAISERROR('Portfolio not found or does not belong to user', 16, 1);
            RETURN;
        END
        
        -- Check current holdings
        DECLARE @CurrentHolding DECIMAL(18,6), @AveragePrice DECIMAL(18,4), @TotalCost DECIMAL(18,2);
        SELECT @CurrentHolding = QuantityHeld, @AveragePrice = AveragePrice, @TotalCost = TotalCost
        FROM portfolio.PortfolioHoldings 
        WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID;
        
        IF @CurrentHolding IS NULL OR @CurrentHolding < @Quantity
        BEGIN
            RAISERROR('Insufficient holdings for this sale', 16, 1);
            RETURN;
        END
        
        -- Get current asset price if not provided
        IF @UnitPrice IS NULL
        BEGIN
            SELECT @UnitPrice = Price 
            FROM portfolio.Assets 
            WHERE AssetID = @AssetID;
            
            IF @UnitPrice IS NULL
            BEGIN
                RAISERROR('Asset not found', 16, 1);
                RETURN;
            END
        END
        
        -- Calculate total proceeds
        DECLARE @TotalProceeds DECIMAL(18,2) = @Quantity * @UnitPrice;
        
        -- Create transaction record
        INSERT INTO portfolio.Transactions (
            UserID, PortfolioID, AssetID, TransactionType, 
            Quantity, UnitPrice, Status
        ) VALUES (
            @UserID, @PortfolioID, @AssetID, 'Sell',
            @Quantity, @UnitPrice, 'Executed'
        );
        
        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();
        
        -- Update portfolio funds (add proceeds)
        UPDATE portfolio.Portfolios 
        SET CurrentFunds = CurrentFunds + @TotalProceeds
        WHERE PortfolioID = @PortfolioID;
        
        -- Update holdings
        DECLARE @NewQuantity DECIMAL(18,6) = @CurrentHolding - @Quantity;
        DECLARE @CostBasis DECIMAL(18,2) = (@Quantity / @CurrentHolding) * @TotalCost;
        
        IF @NewQuantity > 0
        BEGIN
            -- Update existing holding
            UPDATE portfolio.PortfolioHoldings 
            SET QuantityHeld = @NewQuantity,
                TotalCost = @TotalCost - @CostBasis
            WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID;
        END
        ELSE
        BEGIN
            -- Remove holding completely (sold all shares)
            DELETE FROM portfolio.PortfolioHoldings 
            WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID;
        END
        
        -- Record fund transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, PortfolioID, TransactionType, Amount, 
            BalanceAfter, Description, RelatedAssetTransactionID
        ) VALUES (
            @UserID, @PortfolioID, 'AssetSale', @TotalProceeds,
            (SELECT CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID),
            CONCAT('Sold ', @Quantity, ' shares of asset ID ', @AssetID),
            @TransactionID
        );
        
        COMMIT;
        
        -- Return success with transaction details
        SELECT 
            'SUCCESS' AS Status,
            @TransactionID AS TransactionID,
            @Quantity AS QuantitySold,
            @UnitPrice AS PricePerShare,
            @TotalProceeds AS TotalProceeds,
            (SELECT CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID) AS NewFunds,
            @NewQuantity AS RemainingShares;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
3. TRANSACTION MANAGEMENT
============================================================ */

-- Execute basic transaction (legacy support - simplified)
CREATE PROCEDURE portfolio.sp_ExecuteTransaction (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @AssetID INT,
    @TransactionType NVARCHAR(10),
    @Quantity DECIMAL(18,6),
    @UnitPrice DECIMAL(18,4)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate transaction type
        IF @TransactionType NOT IN ('Buy', 'Sell')
        BEGIN
            RAISERROR('Invalid transaction type. Use Buy or Sell', 16, 1);
            RETURN;
        END
        
        -- Route to appropriate procedure
        IF @TransactionType = 'Buy'
        BEGIN
            EXEC portfolio.sp_BuyAsset 
                @UserID = @UserID,
                @PortfolioID = @PortfolioID,
                @AssetID = @AssetID,
                @Quantity = @Quantity,
                @UnitPrice = @UnitPrice;
        END
        ELSE
        BEGIN
            EXEC portfolio.sp_SellAsset 
                @UserID = @UserID,
                @PortfolioID = @PortfolioID,
                @AssetID = @AssetID,
                @Quantity = @Quantity,
                @UnitPrice = @UnitPrice;
        END
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ============================================================
4. PORTFOLIO DATA RETRIEVAL
============================================================ */

-- Get portfolio balance and summary
CREATE PROCEDURE portfolio.sp_GetPortfolioBalance (
    @PortfolioID INT
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID)
    BEGIN
        RAISERROR('Portfolio not found', 16, 1);
        RETURN;
    END
    
    SELECT 
        PortfolioID,
        UserID,
        Name,
        CurrentFunds,
        CurrentProfitPct,
        CreationDate,
        LastUpdated,
        -- Calculate total market value from holdings
        ISNULL((
            SELECT SUM(ph.QuantityHeld * a.Price)
            FROM portfolio.PortfolioHoldings ph
            JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
            WHERE ph.PortfolioID = @PortfolioID
        ), 0) AS CurrentMarketValue,
        -- Calculate total invested amount
        ISNULL((
            SELECT SUM(ph.TotalCost)
            FROM portfolio.PortfolioHoldings ph
            WHERE ph.PortfolioID = @PortfolioID
        ), 0) AS TotalInvested
    FROM portfolio.Portfolios 
    WHERE PortfolioID = @PortfolioID;
END;
GO

-- Get portfolio holdings summary
CREATE PROCEDURE portfolio.sp_GetPortfolioHoldingsSummary (
    @PortfolioID INT
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID)
    BEGIN
        RAISERROR('Portfolio not found', 16, 1);
        RETURN;
    END
    
    SELECT 
        ph.HoldingID,
        ph.PortfolioID,
        ph.AssetID,
        a.Name AS AssetName,
        a.Symbol AS AssetSymbol,
        a.AssetType,
        ph.QuantityHeld,
        ph.AveragePrice,
        ph.TotalCost,
        a.Price AS CurrentPrice,
        (ph.QuantityHeld * a.Price) AS CurrentValue,
        ((ph.QuantityHeld * a.Price) - ph.TotalCost) AS UnrealizedGainLoss,
        CASE 
            WHEN ph.TotalCost > 0 
            THEN (((ph.QuantityHeld * a.Price) - ph.TotalCost) / ph.TotalCost) * 100
            ELSE 0 
        END AS GainLossPercentage,
        ph.LastUpdated
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.PortfolioID = @PortfolioID
    ORDER BY ph.LastUpdated DESC;
END;
GO

PRINT 'Trading procedures created successfully!';
PRINT '';
PRINT 'SUMMARY OF TRADING PROCEDURES CREATED:';
PRINT '✅ sp_BuyAsset - Enhanced buy with fund validation & holdings update';
PRINT '✅ sp_SellAsset - Enhanced sell with holdings validation';
PRINT '✅ sp_ExecuteTransaction - Legacy transaction processor (routes to buy/sell)';
PRINT '✅ sp_GetPortfolioBalance - Portfolio balance with market value calculations';
PRINT '✅ sp_GetPortfolioHoldingsSummary - Detailed holdings with P&L analysis';
PRINT '';
PRINT 'FEATURES:';
PRINT '🚀 Automatic holdings management and cost basis tracking';
PRINT '🚀 Real-time profit/loss calculations';
PRINT '🚀 Comprehensive fund validation and transaction logging';
PRINT '🚀 Enhanced error handling and validation'; 