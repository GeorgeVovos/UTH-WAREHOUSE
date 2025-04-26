USE financial_data_warehouse;
GO

-- Enable Ad Hoc Distributed Queries
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO
CREATE OR ALTER PROCEDURE sp_load_user_data
    @dataFile VARCHAR(255) = 'C:\dev\UTH\UTH-WAREHOUSE\users_data.csv',
    @formatFile VARCHAR(255) = 'C:\dev\UTH\UTH-WAREHOUSE\users_format.fmt',
    @errorFile VARCHAR(255) = 'C:\dev\UTH\UTH-WAREHOUSE\users_errors.txt'
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #temp_users (
        id VARCHAR(10),
        current_age VARCHAR(10),
        retirement_age VARCHAR(10),
        birth_year VARCHAR(10),
        birth_month VARCHAR(10),
        gender VARCHAR(10),
        address VARCHAR(100),
        latitude VARCHAR(20),
        longitude VARCHAR(20),
        per_capita_income VARCHAR(20),
        yearly_income VARCHAR(20),
        total_debt VARCHAR(20),
        credit_score VARCHAR(10),
        num_credit_cards VARCHAR(10)
    );
    
    BEGIN TRY
        PRINT 'Starting data load...';
        -- Construct the BULK INSERT statement dynamically because  BULK INSERT does not support parameterized file paths directly

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #temp_users
            FROM ''' + @dataFile + N'''
            WITH (
                FORMATFILE = ''' + @formatFile + N''',
                BATCHSIZE = 100,
                TABLOCK,
                FIRSTROW = 2,
                ERRORFILE = ''' + @errorFile + N''',
                MAXERRORS = 0,
                ROWS_PER_BATCH = 100
            );
        ';

        -- Execute the dynamic SQL
        EXEC sp_executesql @sql;

        
        PRINT 'Data load completed. Processing ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows.';
        
        -- Insert into dim_user with proper type conversion and validation
    INSERT INTO dim_user (
        user_id,
        current_age,
        retirement_age,
        birth_year,
        birth_month,
        gender,
        address,
        latitude,
        longitude,
        per_capita_income,
        yearly_income,
        total_debt,
        credit_score,
        num_credit_cards
    )
        SELECT 
            CASE WHEN ISNUMERIC(id) = 1 THEN CAST(id AS INT) ELSE NULL END as id,
            CASE WHEN ISNUMERIC(current_age) = 1 AND CAST(current_age AS INT) BETWEEN 0 AND 120 
                THEN CAST(current_age AS INT) ELSE NULL END as current_age,
            CASE WHEN ISNUMERIC(retirement_age) = 1 AND CAST(retirement_age AS INT) BETWEEN 0 AND 120 
                THEN CAST(retirement_age AS INT) ELSE NULL END as retirement_age,
            CASE WHEN ISNUMERIC(birth_year) = 1 AND CAST(birth_year AS INT) BETWEEN 1900 AND 2100 
                THEN CAST(birth_year AS INT) ELSE NULL END as birth_year,
            CASE WHEN ISNUMERIC(birth_month) = 1 AND CAST(birth_month AS INT) BETWEEN 1 AND 12 
                THEN CAST(birth_month AS INT) ELSE NULL END as birth_month,
            gender,
            address,
            CASE WHEN ISNUMERIC(latitude) = 1 THEN CAST(latitude AS DECIMAL(9,6)) ELSE NULL END as latitude,
            CASE WHEN ISNUMERIC(longitude) = 1 THEN CAST(longitude AS DECIMAL(9,6)) ELSE NULL END as longitude,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(per_capita_income, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(per_capita_income, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as per_capita_income,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(yearly_income, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(yearly_income, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as yearly_income,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(total_debt, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(total_debt, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as total_debt,
            CASE WHEN ISNUMERIC(credit_score) = 1 AND CAST(credit_score AS INT) BETWEEN 300 AND 850 
                THEN CAST(credit_score AS INT) ELSE NULL END as credit_score,
            CASE WHEN ISNUMERIC(num_credit_cards) = 1 AND CAST(num_credit_cards AS INT) >= 0 
                THEN CAST(num_credit_cards AS INT) ELSE NULL END as num_credit_cards
        FROM #temp_users;
        
        PRINT 'Data conversion completed. Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'Error during user data processing: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
    
    -- Drop temporary table
    DROP TABLE #temp_users;
END

GO

CREATE OR ALTER PROCEDURE sp_load_transaction_data
    @dataFile VARCHAR(255) = 'C:\dev\UTH\UTH-WAREHOUSE\transactions_data_full.csv',
    @errorFile VARCHAR(255) = 'C:\dev\UTH\UTH-WAREHOUSE\transactions_errors.txt'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create temporary table for transactions
    CREATE TABLE #temp_transactions (
        id BIGINT,
        date DATETIME,
        client_id INT,
        card_id INT,
        amount VARCHAR(200),
        use_chip VARCHAR(500),
        merchant_id INT,
        merchant_city VARCHAR(200),
        merchant_state VARCHAR(53),
        zip VARCHAR(10),
        mcc INT,
        errors VARCHAR(100)
    );
    
    BEGIN TRY
         -- Construct the BULK INSERT statement dynamically because  BULK INSERT does not support parameterized file paths directly
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #temp_transactions
            FROM ''' + @dataFile + N'''
            WITH (
                FORMAT = ''CSV'',
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                FIRSTROW = 2,
                TABLOCK,
                ERRORFILE = ''' + @errorFile + N''',
                MAXERRORS = 10
            );
        ';

        -- Execute the dynamic SQL
        EXEC sp_executesql @sql;
        
        PRINT 'Transactions data loaded successfully. Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows.';
        
        -- Load State Dimension
        INSERT INTO dim_state (state_code)
        SELECT DISTINCT merchant_state
        FROM #temp_transactions
        WHERE merchant_state IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dim_state ds 
            WHERE ds.state_code = #temp_transactions.merchant_state
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' states.';
        
        -- Load City Dimension
        INSERT INTO dim_city (city_name, state_id)
        SELECT DISTINCT 
            t.merchant_city,
            s.state_id
        FROM #temp_transactions t
        JOIN dim_state s ON t.merchant_state = s.state_code
        WHERE t.merchant_city IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dim_city dc 
            WHERE dc.city_name = t.merchant_city 
            AND dc.state_id = s.state_id
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' cities.';
        
        -- Load Merchant Dimension
        INSERT INTO dim_merchant (merchant_id, mcc)
        SELECT merchant_id, MAX(mcc) as mcc
        FROM (
            SELECT DISTINCT merchant_id, mcc
            FROM #temp_transactions
            WHERE merchant_id IS NOT NULL
        ) AS source
        WHERE NOT EXISTS (
            SELECT 1 FROM dim_merchant dm 
            WHERE dm.merchant_id = source.merchant_id
        )
        GROUP BY merchant_id;
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' merchants.';
        
        -- Load Merchant Location Bridge Table
        INSERT INTO dim_merchant_location (merchant_id, city_id)
        SELECT DISTINCT 
            t.merchant_id,
            c.city_id
        FROM #temp_transactions t
        JOIN dim_city c ON t.merchant_city = c.city_name
        JOIN dim_state s ON c.state_id = s.state_id AND t.merchant_state = s.state_code
        WHERE NOT EXISTS (
            SELECT 1 FROM dim_merchant_location ml 
            WHERE ml.merchant_id = t.merchant_id 
            AND ml.city_id = c.city_id
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' merchant locations.';
        
        -- Load Date Dimension
        INSERT INTO dim_date (date_id, year, month, day, hour, minute)
        SELECT DISTINCT
            date as date_id,
            YEAR(date) as year,
            MONTH(date) as month,
            DAY(date) as day,
            DATEPART(HOUR, date) as hour,
            DATEPART(MINUTE, date) as minute
        FROM #temp_transactions t
        WHERE NOT EXISTS (
            SELECT 1 FROM dim_date dd 
            WHERE dd.date_id = t.date
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' date records.';
        
        -- Load Card Dimension
        INSERT INTO dim_card (card_id, user_id)
        SELECT DISTINCT 
            card_id,
            client_id as user_id
        FROM #temp_transactions t
        WHERE NOT EXISTS (
            SELECT 1 FROM dim_card dc 
            WHERE dc.card_id = t.card_id
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' cards.';
        
        -- Load Chip Usage Dimension
        INSERT INTO dim_chip_usage (usage_description)
        SELECT DISTINCT use_chip
        FROM #temp_transactions
        WHERE use_chip IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dim_chip_usage dc 
            WHERE dc.usage_description = #temp_transactions.use_chip
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' chip usage types.';
        
        -- Load Transaction Fact Table
        INSERT INTO fact_transaction (
            transaction_id,
            date_id,
            user_id,
            card_id,
            merchant_location_id,
            amount,
            chip_usage_id,
            error
        )
        SELECT 
            t.id as transaction_id,
            t.date as date_id,
            t.client_id as user_id,
            t.card_id,
            --ml.merchant_location_id,
            (SELECT top (1) ml.merchant_location_id 
            from dim_merchant_location
            JOIN dim_city c ON t.merchant_city = c.city_name
            JOIN dim_state s ON c.state_id = s.state_id AND t.merchant_state = s.state_code
            JOIN dim_merchant_location ml ON ml.merchant_id = t.merchant_id AND ml.city_id = c.city_id
            
            ) as merchant_location_id,
            CAST(REPLACE(REPLACE(t.amount, '$', ''), ',', '') AS DECIMAL(10,2)) as amount,
            (SELECT chip_usage_id FROM dim_chip_usage WHERE usage_description = t.use_chip) as chip_usage_id,
            t.errors as error
        FROM #temp_transactions t
                
                PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' transactions.';
            END TRY
            BEGIN CATCH
                PRINT 'Error during transaction data processing: ' + ERROR_MESSAGE();
                THROW;
            END CATCH;
            
            -- Drop temporary table
            DROP TABLE #temp_transactions;
END
GO