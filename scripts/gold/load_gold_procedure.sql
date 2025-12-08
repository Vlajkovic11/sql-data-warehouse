/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
===============================================================================
Gold Layer represents Star Schema
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'gold' schema tables from the 'silver' schema.
	Actions Performed:
		- Truncates gold fact table.
		- Deletes rows from gold dimension tables and resets IDENTITY counters.
		- Inserts transformed data from Silver into Gold tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.load_gold;
===============================================================================
*/
CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();

		TRUNCATE TABLE gold.fact_sales;

		DELETE FROM gold.dim_customers;
		DBCC CHECKIDENT ('gold.dim_customers', RESEED, 0);

		DELETE FROM gold.dim_products;
		DBCC CHECKIDENT ('gold.dim_products', RESEED, 0);

		INSERT INTO gold.dim_customers(
			customer_id,
			customer_number,
			first_name,
			last_name,
			marital_status,
			country,
			gender,
			birthdate,
			create_date
		)
		SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		la.cntry,
		CASE WHEN ci.cst_gndr != 'UNKNOWN' 
			 THEN ci.cst_gndr
			 ELSE COALESCE(ca.gen, 'UNKNOWN')
		END gender,
		ca.BDATE,
		ci.cst_create_date
		FROM silver.crm_cust_info ci
		LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key = ca.cid
		LEFT JOIN silver.erp_loc_a101 la
		ON ci.cst_key = la.cid

		
		INSERT INTO gold.dim_products(
			product_id,
			product_number,
			product_name,
			category_id,
			category,
			subcategory,
			maintenance,
			cost,
			product_line,
			start_date
		)
		SELECT
		pn.prd_id,
		pn.prd_key,
		pn.prd_nm,
		pn.cat_id,
		pc.cat,
		pc.subcat,
		pc.maintenance,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt
		FROM silver.crm_prd_info pn
		LEFT JOIN silver.erp_px_cat_g1v2 pc
		ON pn.cat_id = pc.id
		WHERE prd_end_dt IS NULL


		INSERT INTO gold.fact_sales(
			order_number,  
			product_key, 
			customer_key,  
			order_date,   
			ship_date,     
			due_date, 
			sales_amount,
			quantity,  
			unit_price 
		)
		SELECT 
		sd.sls_ord_num,
		pr.product_key,
		cu.customer_key,
		sd.sls_order_dt,
		sd.sls_ship_dt,
		sd.sls_due_dt,
		sd.sls_sales,
		sd.sls_quantity,
		sd.sls_price
		FROM silver.crm_sales_details sd
		LEFT JOIN gold.dim_products pr
		ON sd.sls_prd_key = pr.product_number
		LEFT JOIN gold.dim_customers cu
		ON sd.sls_cust_id = cu.customer_id

		SET @batch_end_time = GETDATE();
		PRINT 'BATCH LOAD DURATION: '+ CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING GOLD LAYER'
	END CATCH
END

