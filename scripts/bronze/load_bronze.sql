/*
=============================================================
Load Bronze Layer
=============================================================
Script Purpose:
    This stored procedure loads raw data from CRM and ERP
    source CSV files into the Bronze layer of the Data Warehouse.

    The procedure:
        - Truncates existing Bronze tables.
        - Loads fresh data from source CSV files.
        - Tracks the load duration for each table.
        - Tracks the total batch load duration.
        - Handles and displays errors during execution.

    Source Systems:
        - CRM
        - ERP

    Target Layer:
        - Bronze

WARNING:
    This procedure uses TRUNCATE TABLE before loading data.
    Existing data in the Bronze tables will be permanently
    removed and replaced with the latest source data.

    Make sure the CSV file paths are accessible by SQL Server.
=============================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN 
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME 
	BEGIN TRY
		SET @batch_start_time = GETDATE()
		PRINT '=========================';
		PRINT 'Loading Bronze Layer';
		PRINT '=========================';

		PRINT '-----------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-----------------------';

		SET @start_time = GETDATE() 
		PRINT '=> Truncating Table: crm_cust_info' 
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '=> Inserting Data Into: crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: crm_prd_info' 
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '=> Inserting Data Into: crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: crm_sales_details' 
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '=> Inserting Data Into: crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		PRINT '-----------------------';
		PRINT 'Loading ERP Tables' ;
		PRINT '-----------------------';

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_cust_az12' 
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '=> Inserting Data Into: erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
	  SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'


		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_loc_a101' 
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '=> Inserting Data Into: erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_px_cat_g1v2' 
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '=> Inserting Data Into: erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Track\Baraa\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @batch_end_time = GETDATE()
		PRINT 'Loading Bronze Layer is Completed'
		PRINT '	 - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds'
	END TRY
	BEGIN CATCH
		PRINT '==========================================';
		PRINT 'ERROR OCCURED DURING BRONZE EXECUTION';
		PRINT 'ERROR Message ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER '  + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE '   + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT 'ERROR LINE '    + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '==========================================';

		THROW;
	END CATCH
END;
GO

EXEC bronze.load_bronze;
GO
