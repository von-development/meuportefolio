/* ------------------------------------------------------------
meuPortfolio – Password Field Migration (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Change password field from hash to plain text
============================================================ */

-- Add new Password column
ALTER TABLE portfolio.Users 
ADD Password NVARCHAR(100) NULL;
GO

-- Update existing users with simple passwords (for testing)
UPDATE portfolio.Users 
SET Password = 'password123' 
WHERE Password IS NULL;
GO

-- Make Password column NOT NULL
ALTER TABLE portfolio.Users 
ALTER COLUMN Password NVARCHAR(100) NOT NULL;
GO

-- Drop the old PasswordHash column
ALTER TABLE portfolio.Users 
DROP COLUMN PasswordHash;
GO

PRINT 'Password field migration completed successfully'; 