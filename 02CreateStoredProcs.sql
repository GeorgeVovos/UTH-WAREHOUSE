USE FinancialDataWarehouse;
GO

-- Enable Ad Hoc Distributed Queries
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO
CREATE OR ALTER PROCEDURE sp_load_user_data
    @dataFile VARCHAR(255),
    @formatFile VARCHAR(255),
    @errorFile VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #temp_users (
        id VARCHAR(10),
        CurrentAge VARCHAR(10),
        RetirementAge VARCHAR(10),
        BirthYear VARCHAR(10),
        BirthMonth VARCHAR(10),
        Gender VARCHAR(10),
        Address VARCHAR(100),
        Latitude VARCHAR(20),
        Longitude VARCHAR(20),
        PerCapitaIncome VARCHAR(20),
        YearlyIncome VARCHAR(20),
        TotalDebt VARCHAR(20),
        CreditScore VARCHAR(10),
        NumberOfCreditCards VARCHAR(10)
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
        
        -- Insert into Dim_User with proper type conversion and validation
    INSERT INTO Dim_User (
        UserId,
        CurrentAge,
        RetirementAge,
        BirthYear,
        BirthMonth,
        Gender,
        Address,
        Latitude,
        Longitude,
        PerCapitaIncome,
        YearlyIncome,
        TotalDebt,
        CreditScore,
        NumberOfCreditCards
    )
        SELECT 
            CASE WHEN ISNUMERIC(id) = 1 THEN CAST(id AS INT) ELSE NULL END as id,
            CASE WHEN ISNUMERIC(CurrentAge) = 1 AND CAST(CurrentAge AS INT) BETWEEN 0 AND 120 
                THEN CAST(CurrentAge AS INT) ELSE NULL END as CurrentAge,
            CASE WHEN ISNUMERIC(RetirementAge) = 1 AND CAST(RetirementAge AS INT) BETWEEN 0 AND 120 
                THEN CAST(RetirementAge AS INT) ELSE NULL END as RetirementAge,
            CASE WHEN ISNUMERIC(BirthYear) = 1 AND CAST(BirthYear AS INT) BETWEEN 1900 AND 2100 
                THEN CAST(BirthYear AS INT) ELSE NULL END as BirthYear,
            CASE WHEN ISNUMERIC(BirthMonth) = 1 AND CAST(BirthMonth AS INT) BETWEEN 1 AND 12 
                THEN CAST(BirthMonth AS INT) ELSE NULL END as BirthMonth,
            Gender,
            Address,
            CASE WHEN ISNUMERIC(Latitude) = 1 THEN CAST(Latitude AS DECIMAL(9,6)) ELSE NULL END as Latitude,
            CASE WHEN ISNUMERIC(Longitude) = 1 THEN CAST(Longitude AS DECIMAL(9,6)) ELSE NULL END as Longitude,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(PerCapitaIncome, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(PerCapitaIncome, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as PerCapitaIncome,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(YearlyIncome, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(YearlyIncome, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as YearlyIncome,
            CASE WHEN ISNUMERIC(REPLACE(REPLACE(TotalDebt, '$', ''), ',', '')) = 1 
                THEN CAST(REPLACE(REPLACE(TotalDebt, '$', ''), ',', '') AS DECIMAL(10,2)) ELSE NULL END as TotalDebt,
            CASE WHEN ISNUMERIC(CreditScore) = 1 AND CAST(CreditScore AS INT) BETWEEN 300 AND 850 
                THEN CAST(CreditScore AS INT) ELSE NULL END as CreditScore,
            CASE WHEN ISNUMERIC(NumberOfCreditCards) = 1 AND CAST(NumberOfCreditCards AS INT) >= 0 
                THEN CAST(NumberOfCreditCards AS INT) ELSE NULL END as NumberOfCreditCards
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
    @dataFile VARCHAR(255) ,
    @errorFile VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create temporary table for transactions
    CREATE TABLE #temp_transactions (
        id BIGINT,
        date DATETIME,
        client_id INT,
        CardId INT,
        amount VARCHAR(200),
        use_chip VARCHAR(500),
        MerchantId INT,
        merchant_city VARCHAR(200),
        merchant_state VARCHAR(53),
        zip VARCHAR(10),
        MCC INT,
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
        INSERT INTO Dim_State (StateCode)
        SELECT DISTINCT merchant_state
        FROM #temp_transactions
        WHERE merchant_state IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM Dim_State ds 
            WHERE ds.StateCode = #temp_transactions.merchant_state
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' states.';
        
        -- Load City Dimension
        INSERT INTO Dim_City (CityName, StateId)
        SELECT DISTINCT 
            t.merchant_city,
            s.StateId
        FROM #temp_transactions t
        JOIN Dim_State s ON t.merchant_state = s.StateCode
        WHERE t.merchant_city IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM Dim_City dc 
            WHERE dc.CityName = t.merchant_city 
            AND dc.StateId = s.StateId
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' cities.';
        
        -- Load Merchant Dimension
        INSERT INTO Dim_Merchant (MerchantId, MCC)
        SELECT MerchantId, MAX(MCC) as MCC
        FROM (
            SELECT DISTINCT MerchantId, MCC
            FROM #temp_transactions
            WHERE MerchantId IS NOT NULL
        ) AS source
        WHERE NOT EXISTS (
            SELECT 1 FROM Dim_Merchant dm 
            WHERE dm.MerchantId = source.MerchantId
        )
        GROUP BY MerchantId;
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' merchants.';
        
        -- Load Merchant Location Bridge Table
        INSERT INTO Dim_MerchantLocation (MerchantId, CityId)
        SELECT DISTINCT 
            t.MerchantId,
            c.CityId
        FROM #temp_transactions t
        JOIN Dim_City c ON t.merchant_city = c.CityName
        JOIN Dim_State s ON c.StateId = s.StateId AND t.merchant_state = s.StateCode
        WHERE NOT EXISTS (
            SELECT 1 FROM Dim_MerchantLocation ml 
            WHERE ml.MerchantId = t.MerchantId 
            AND ml.CityId = c.CityId
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' merchant locations.';
        
        -- Load Date Dimension
        INSERT INTO Dim_Date (DateId, year, month, day, hour, minute)
        SELECT DISTINCT
            date as DateId,
            YEAR(date) as year,
            MONTH(date) as month,
            DAY(date) as day,
            DATEPART(HOUR, date) as hour,
            DATEPART(MINUTE, date) as minute
        FROM #temp_transactions t
        WHERE NOT EXISTS (
            SELECT 1 FROM Dim_Date dd 
            WHERE dd.DateId = t.date
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' date records.';
        
        -- Load Card Dimension
        INSERT INTO Dim_Card (CardId, UserId)
        SELECT DISTINCT 
            CardId,
            client_id as UserId
        FROM #temp_transactions t
        WHERE NOT EXISTS (
            SELECT 1 FROM Dim_Card dc 
            WHERE dc.CardId = t.CardId
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' cards.';
        
        -- Load Chip Usage Dimension
        INSERT INTO Dim_ChipUsage (UsageDescription)
        SELECT DISTINCT use_chip
        FROM #temp_transactions
        WHERE use_chip IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM Dim_ChipUsage dc 
            WHERE dc.UsageDescription = #temp_transactions.use_chip
        );
        PRINT 'Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' chip usage types.';
        
        -- Load Transaction Fact Table
        INSERT INTO Fact_Transaction (
            TransactionId,
            DateId,
            UserId,
            CardId,
            MerchantLocationId,
            amount,
            ChipUsageId,
            error
        )
        SELECT 
            t.id as TransactionId,
            t.date as DateId,
            t.client_id as UserId,
            t.CardId,
            --ml.MerchantLocationId,
            (SELECT top (1) ml.MerchantLocationId 
            from Dim_MerchantLocation
            JOIN Dim_City c ON t.merchant_city = c.CityName
            JOIN Dim_State s ON c.StateId = s.StateId AND t.merchant_state = s.StateCode
            JOIN Dim_MerchantLocation ml ON ml.MerchantId = t.MerchantId AND ml.CityId = c.CityId
            
            ) as MerchantLocationId,
            CAST(REPLACE(REPLACE(t.amount, '$', ''), ',', '') AS DECIMAL(10,2)) as amount,
            (SELECT ChipUsageId FROM Dim_ChipUsage WHERE UsageDescription = t.use_chip) as ChipUsageId,
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