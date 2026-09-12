/*
===============================================================================
Procedure: silver.load_silver
===============================================================================
Purpose:
    Load cleaned and transformed data from the Bronze layer into the
    Silver layer of the Data Warehouse.

Transformation Summary:
    - Remove duplicate customer records.
    - Trim unnecessary spaces from text fields.
    - Standardize categorical values such as gender and marital status.
    - Extract category and product keys from product identifiers.
    - Replace missing numeric values with appropriate defaults.
    - Convert coded values into descriptive values.
    - Validate and convert date fields.
    - Recalculate incorrect sales and price values.
    - Standardize customer IDs and country names.
    - Remove invalid future birth dates.
    - Calculate product end dates using LEAD().

Execution:
    EXEC silver.load_silver;

Note:
    Silver tables are truncated and fully reloaded on every execution.
    The Bronze layer should be loaded successfully before running this
    procedure.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY
		SET @batch_start_time = GETDATE() 
		PRINT '=========================';
		PRINT 'Loading Silver Layer';
		PRINT '=========================';


		PRINT '-----------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-----------------------';

		SET @start_time = GETDATE() 
		PRINT '=> Truncating Table: crm_cust_info' 
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '=> Inserting Data Into: crm_cust_info'
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		SELECT
			cst_id,
			cst_key,

			-- Remove leading and trailing spaces from first name
			-- Example: ' John ' → 'John'
			TRIM(cst_firstname) AS cst_firstname,

			-- Remove leading and trailing spaces from last name
			-- Example: ' Smith ' → 'Smith'
			TRIM(cst_lastname) AS cst_lastname,

			-- Normalize marital status values
			-- Example: 'S' → 'Single', 'M' → 'Married', unknown → 'n/a'
			CASE 		
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END cst_marital_status,

			-- Normalize gender values
			-- Example: 'F' → 'Female', 'M' → 'Male', unknown → 'n/a'
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM (
			SELECT 
				*,

				-- Assign a ranking to each customer based on the latest creation date
				-- Example: duplicate customer IDs → newest record gets flag = 1
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
			FROM bronze.crm_cust_info

			-- Remove records where the customer ID is missing
			WHERE cst_id IS NOT NULL
			)rank 

		-- Keep only the latest record for each customer
		WHERE flag = 1

		SET @end_time = GETDATE()

		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: crm_prd_info' 
		TRUNCATE TABLE silver.crm_prd_info
		PRINT '=> Inserting Data Into: crm_prd_info'
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,

			-- Extract category ID from product key and replace '-' with '_'
			-- Example: 'AC-HE' → 'AC_HE'
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_' ) AS cat_id,

			-- Extract product key from the original product key
			-- Example: 'AC-HE-123' → '123'
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

			prd_nm,

			-- Replace NULL product cost with 0
			ISNULL(prd_cost, 0) AS prd_cost,

			-- Normalize product line codes
			-- Example: 'R' → 'Road', 'M' → 'Mountain', 'T' → 'Touring'
			CASE UPPER(TRIM(prd_line))
				WHEN 'R' THEN 'Road'
				WHEN 'M' THEN 'Mountain'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,

			-- Convert product start date to DATE format
			CAST(prd_start_dt AS DATE) AS prd_start_dt,

			-- Calculate product end date based on the next start date
			-- Example: next start date = 2024-01-01 → current end date = 2023-12-31
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE()

		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: crm_sales_details' 
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '=> Inserting Data Into: crm_sales_details'
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,

			-- Convert order date from YYYYMMDD format to DATE
			-- Example: 20240115 → 2024-01-15
			-- Invalid or zero dates → NULL
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,

			-- Convert ship date from YYYYMMDD format to DATE
			-- Invalid or zero dates → NULL
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,

			-- Convert due date from YYYYMMDD format to DATE
			-- Invalid or zero dates → NULL
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,

			-- Recalculate sales when the value is NULL, invalid, or inconsistent
			-- Formula: Sales = Absolute Price × Quantity
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != ABS(sls_price) * sls_quantity 
					THEN ABS(sls_price)* sls_quantity 
				ELSE sls_sales
			END AS sls_sales,

			sls_quantity,

			-- Clean and calculate the price when necessary
			-- NULL or 0 price → calculate from Sales / Quantity
			-- Negative price → convert to positive
			CASE 
				WHEN sls_price IS NULL OR sls_price = 0 
					THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
				WHEN sls_price < 0 
					THEN ABS(sls_price)
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE()

		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_cust_az12'  
		TRUNCATE TABLE silver.erp_cust_az12

		PRINT '=> Inserting Data Into: erp_cust_az12'
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		 SELECT

			-- Remove 'NAS' prefix from customer ID
			-- Example: 'NAS12345' → '12345'
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END AS cid,

			-- Replace future birth dates with NULL
			CASE WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END AS bdate,

			-- Normalize gender values
			-- Example: 'F'/'FEMALE' → 'Female', 'M'/'MALE' → 'Male'
			CASE 
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen
		FROM bronze.erp_cust_az12 
		SET @end_time = GETDATE()

		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_loc_a101' 
		TRUNCATE TABLE silver.erp_loc_a101

		PRINT '=> Inserting Data Into: erp_loc_a101'
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT

			-- Remove '-' characters from customer ID
			-- Example: 'AW-123-45' → 'AW12345'
			REPLACE(cid, '-','') AS cid,

			-- Normalize country names and handle missing values
			-- Example: 'DE' → 'Germany', 'US'/'USA' → 'United States', blank/NULL → 'n/a'
			CASE 
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN cntry = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE()

		PRINT '=> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '--------------------------'

		SET @start_time = GETDATE()
		PRINT '=> Truncating Table: erp_px_cat_g1v2' 
		TRUNCATE TABLE silver.erp_px_cat_g1v2

		PRINT '=> Inserting Data Into: erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2

		SET @batch_end_time = GETDATE()

		PRINT 'Loading Silver Layer is Completed'
		PRINT '	 - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds'
	END TRY
	BEGIN CATCH
		PRINT '==========================================';
		PRINT 'ERROR OCCURRED DURING SILVER EXECUTION';
		PRINT 'ERROR Message: ' + ERROR_MESSAGE()
		PRINT 'ERROR_NUMBER'    + CAST(ERROR_NUMBER() AS NVARCHAR)
		PRINT 'ERROR_STATE'     + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT 'ERROR_LINE'      + CAST(ERROR_LINE() AS NVARCHAR)
		PRINT '==========================================';
		
		THROW;
	END CATCH
END
GO

EXEC silver.load_silver;
GO
