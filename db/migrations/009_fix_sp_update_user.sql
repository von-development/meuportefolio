/* ------------------------------------------------------------
meuPortfolio – Fix Update User Stored Procedure (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Fix sp_UpdateUser procedure to work with triggers
============================================================ */

-- Drop existing procedure
DROP PROCEDURE IF EXISTS portfolio.sp_UpdateUser;
GO

-- Create fixed update user procedure (without OUTPUT clause to avoid trigger conflict)
CREATE PROCEDURE portfolio.sp_UpdateUser (
    @UserID UNIQUEIDENTIFIER,
    @Name NVARCHAR(100) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Password NVARCHAR(100) = NULL,
    @CountryOfResidence NVARCHAR(100) = NULL,
    @IBAN NVARCHAR(34) = NULL,
    @UserType NVARCHAR(20) = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        -- If email is being updated, check for duplicates
        IF @Email IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM portfolio.Users WHERE Email = @Email AND UserID != @UserID)
            BEGIN
                RAISERROR('Email already exists', 16, 1);
                RETURN;
            END
        END
        
        -- Check if any fields are provided for update
        IF @Name IS NULL AND @Email IS NULL AND @Password IS NULL 
           AND @CountryOfResidence IS NULL AND @IBAN IS NULL AND @UserType IS NULL
        BEGIN
            RAISERROR('No fields to update', 16, 1);
            RETURN;
        END
        
        -- Perform the update with only non-null fields
        UPDATE portfolio.Users 
        SET 
            Name = COALESCE(@Name, Name),
            Email = COALESCE(@Email, Email),
            Password = COALESCE(@Password, Password),
            CountryOfResidence = COALESCE(@CountryOfResidence, CountryOfResidence),
            IBAN = COALESCE(@IBAN, IBAN),
            UserType = COALESCE(@UserType, UserType)
            -- Note: UpdatedAt will be set automatically by the trigger
        WHERE UserID = @UserID;
        
        -- Check if update actually affected any rows
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('User not found after update', 16, 1);
            RETURN;
        END
        
        -- Return the updated user data
        SELECT 
            UserID,
            Name,
            Email,
            CountryOfResidence,
            IBAN,
            UserType,
            CreatedAt,
            UpdatedAt
        FROM portfolio.Users 
        WHERE UserID = @UserID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

PRINT 'sp_UpdateUser stored procedure fixed successfully'; 