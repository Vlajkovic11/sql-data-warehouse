/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'gold' Tables
===============================================================================
*/

IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
    DROP TABLE gold.dim_customers;
GO

CREATE TABLE gold.dim_customers(
	customer_key INT IDENTITY(1,1) PRIMARY KEY,
	customer_id INT,
	customer_number NVARCHAR(50),
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	marital_status NVARCHAR(50),
	country NVARCHAR(50),
	gender NVARCHAR(50),
	birthdate DATE,
	create_date DATE
);
GO

IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL
    DROP TABLE gold.dim_products;
GO
CREATE TABLE gold.dim_products(
	product_key INT IDENTITY(1,1) PRIMARY KEY,
	product_id INT,
	product_number NVARCHAR(50),
	product_name NVARCHAR(50),
	category_id NVARCHAR(50),
	category NVARCHAR(50),
	subcategory NVARCHAR(50),
	maintenance NVARCHAR(50),
	cost INT,
	product_line NVARCHAR(50),
	start_date DATE
);
GO

IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_sales;
GO

CREATE TABLE gold.fact_sales (
	  order_number  NVARCHAR(50) NOT NULL,
    product_key   INT NOT NULL,
    customer_key  INT NOT NULL,
    order_date    DATE,
    ship_date     DATE,
    due_date      DATE,
    sales_amount  INT,
    quantity      INT,
    unit_price    INT,

    CONSTRAINT PK_fact_sales 
        PRIMARY KEY (order_number, product_key, customer_key),

    CONSTRAINT FK_fact_sales_product
        FOREIGN KEY (product_key)
        REFERENCES gold.dim_products(product_key),

    CONSTRAINT FK_fact_sales_customer
        FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customers(customer_key)
);
