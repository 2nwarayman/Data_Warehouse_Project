-- Use the master database
USE master;
GO

-- Check if DataWarehouse already exists
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN
    -- Allow only one connection and disconnect existing users
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Delete the existing database
    DROP DATABASE DataWarehouse;
END;
GO

-- Create a new DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

-- Use the newly created database
USE DataWarehouse;
GO

-- Create the Bronze layer for raw data
CREATE SCHEMA bronze;
GO

-- Create the Silver layer for cleaned/transformed data
CREATE SCHEMA silver;
GO

-- Create the Gold layer for business-ready data
CREATE SCHEMA gold;
GO
