/* ------------------------------------------------------------
meuPortfolio – Enhanced Trading Procedures (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Enhanced Trading Stored Procedures
============================================================ */

-- Drop existing trading procedure if it exists
DROP PROCEDURE IF EXISTS portfolio.sp_ExecuteTransaction;
GO

-- Buy Asset (Enhanced with Fund Validation)
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
        SET CurrentFunds = CurrentFunds - @TotalCost,
            LastUpdated = SYSDATETIME()
        WHERE PortfolioID = @PortfolioID;
        
        -- Update or insert holdings
        IF EXISTS (SELECT 1 FROM portfolio.PortfolioHoldings WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID)
        BEGIN
            -- Update existing holding - calculate new average price
            UPDATE portfolio.PortfolioHoldings 
            SET QuantityHeld = QuantityHeld + @Quantity,
                AveragePrice = ((TotalCost + @TotalCost) / (QuantityHeld + @Quantity)),
                TotalCost = TotalCost + @TotalCost,
                LastUpdated = SYSDATETIME()
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

-- Sell Asset (Enhanced with Holdings Validation)
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
        SET CurrentFunds = CurrentFunds + @TotalProceeds,
            LastUpdated = SYSDATETIME()
        WHERE PortfolioID = @PortfolioID;
        
        -- Update holdings
        DECLARE @NewQuantity DECIMAL(18,6) = @CurrentHolding - @Quantity;
        DECLARE @CostReduction DECIMAL(18,2) = (@TotalCost / @CurrentHolding) * @Quantity;
        
        IF @NewQuantity > 0
        BEGIN
            -- Update existing holding
            UPDATE portfolio.PortfolioHoldings 
            SET QuantityHeld = @NewQuantity,
                TotalCost = TotalCost - @CostReduction,
                LastUpdated = SYSDATETIME()
            WHERE PortfolioID = @PortfolioID AND AssetID = @AssetID;
        END
        ELSE
        BEGIN
            -- Remove holding completely
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
            (SELECT CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID) AS NewFundsBalance;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Get Portfolio Balance Summary
CREATE PROCEDURE portfolio.sp_GetPortfolioBalance (
    @PortfolioID INT
) AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.PortfolioID,
        p.Name AS PortfolioName,
        p.CurrentFunds AS CashBalance,
        ISNULL(holdings.TotalMarketValue, 0) AS HoldingsValue,
        p.CurrentFunds + ISNULL(holdings.TotalMarketValue, 0) AS TotalPortfolioValue,
        holdings.HoldingsCount
    FROM portfolio.Portfolios p
    LEFT JOIN (
        SELECT 
            h.PortfolioID,
            SUM(h.QuantityHeld * a.Price) AS TotalMarketValue,
            COUNT(*) AS HoldingsCount
        FROM portfolio.PortfolioHoldings h
        JOIN portfolio.Assets a ON a.AssetID = h.AssetID
        GROUP BY h.PortfolioID
    ) holdings ON holdings.PortfolioID = p.PortfolioID
    WHERE p.PortfolioID = @PortfolioID;
END;
GO

-- Get User Account Summary
CREATE PROCEDURE portfolio.sp_GetUserAccountSummary (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.UserID,
        u.Name,
        u.UserType,
        u.AccountBalance,
        ISNULL(portfolios.TotalPortfolioValue, 0) AS TotalPortfolioValue,
        u.AccountBalance + ISNULL(portfolios.TotalPortfolioValue, 0) AS TotalNetWorth,
        ISNULL(portfolios.PortfolioCount, 0) AS PortfolioCount
    FROM portfolio.Users u
    LEFT JOIN (
        SELECT 
            p.UserID,
            SUM(p.CurrentFunds + ISNULL(holdings.HoldingsValue, 0)) AS TotalPortfolioValue,
            COUNT(p.PortfolioID) AS PortfolioCount
        FROM portfolio.Portfolios p
        LEFT JOIN (
            SELECT 
                h.PortfolioID,
                SUM(h.QuantityHeld * a.Price) AS HoldingsValue
            FROM portfolio.PortfolioHoldings h
            JOIN portfolio.Assets a ON a.AssetID = h.AssetID
            GROUP BY h.PortfolioID
        ) holdings ON holdings.PortfolioID = p.PortfolioID
        GROUP BY p.UserID
    ) portfolios ON portfolios.UserID = u.UserID
    WHERE u.UserID = @UserID;
END;
GO

PRINT 'Enhanced trading procedures created successfully!';
PRINT 'Created procedures: sp_BuyAsset, sp_SellAsset, sp_GetPortfolioBalance, sp_GetUserAccountSummary'; 