/* ------------------------------------------------------------
meuPortfolio – Fix Transaction Status Constraint (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Fix existing Transaction Status values
============================================================ */

-- First, let's see what status values currently exist
PRINT 'Current Status values in Transactions table:';
SELECT DISTINCT Status, COUNT(*) as Count
FROM portfolio.Transactions 
GROUP BY Status;
GO

-- Update any NULL or incompatible status values to 'Pending'
UPDATE portfolio.Transactions 
SET Status = 'Pending'
WHERE Status IS NULL 
   OR Status NOT IN ('Pending', 'Executed', 'Failed', 'Cancelled');
GO

-- Check how many records were updated
PRINT 'Updated incompatible status values to ''Pending''';
GO

-- Now drop the existing constraint if it exists
ALTER TABLE portfolio.Transactions 
DROP CONSTRAINT IF EXISTS CK_Transactions_Status;
GO

-- Add the new constraint
ALTER TABLE portfolio.Transactions 
ADD CONSTRAINT CK_Transactions_Status 
CHECK (Status IN ('Pending', 'Executed', 'Failed', 'Cancelled'));
GO

-- Verify the constraint was added successfully
PRINT 'Transaction status constraint updated successfully!';
GO

-- Show final status distribution
PRINT 'Final Status values in Transactions table:';
SELECT DISTINCT Status, COUNT(*) as Count
FROM portfolio.Transactions 
GROUP BY Status;
GO 