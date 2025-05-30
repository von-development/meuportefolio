/* ------------------------------------------------------------
meuPortfolio – Update Stored Procedures for Password Change (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Update sp_CreateUser procedure for new password field
============================================================ */

-- Drop existing procedure
DROP PROCEDURE IF EXISTS portfolio.sp_CreateUser;
GO

-- Create updated procedure with Password instead of PasswordHash
CREATE PROCEDURE portfolio.sp_CreateUser (
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @Password NVARCHAR(100),
    @CountryOfResidence NVARCHAR(100),
    @IBAN NVARCHAR(34),
    @UserType NVARCHAR(20)
) AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID UNIQUEIDENTIFIER = NEWID();
    
    INSERT INTO portfolio.Users (
        UserID, Name, Email, Password, 
        CountryOfResidence, IBAN, UserType
    )
    VALUES (
        @UserID, @Name, @Email, @Password,
        @CountryOfResidence, @IBAN, @UserType
    );
    
    SELECT @UserID AS UserID;
END;
GO

PRINT 'Stored procedure updated successfully'; 