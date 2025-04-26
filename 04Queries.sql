-- 1. Top 10 Users by Total Transaction Amount
-- This query identifies your highest value customers
SELECT TOP 10
    u.UserId,
    u.YearlyIncome,
    u.CreditScore,
    COUNT(ft.TransactionId) AS TransactionCount,
    SUM(ft.amount) AS TotalAmount
FROM Dim_User u
JOIN Fact_Transaction ft ON u.UserId = ft.UserId
GROUP BY u.UserId, u.YearlyIncome, u.CreditScore
ORDER BY TotalAmount DESC;

-- 2. Transaction Volume by Month
-- Helps identify seasonal patterns in spending
SELECT 
    d.year,
    d.month,
    COUNT(ft.TransactionId) AS TransactionCount,
    SUM(ft.amount) AS TotalAmount
FROM Fact_Transaction ft
JOIN Dim_Date d ON ft.DateId = d.DateId
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 3. Merchant Categories with Highest Error Rates
-- Helps identify potential fraud or technical issues with specific merchant types
SELECT 
    m.MCC,
    COUNT(ft.TransactionId) AS total_transactions,
    SUM(CASE WHEN ft.error IS NOT NULL AND ft.error != '' THEN 1 ELSE 0 END) AS error_count,
    (SUM(CASE WHEN ft.error IS NOT NULL AND ft.error != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(ft.TransactionId)) AS ErrorPercentage
FROM Fact_Transaction ft
JOIN Dim_MerchantLocation ml ON ft.MerchantLocationId = ml.MerchantLocationId
JOIN Dim_Merchant m ON ml.MerchantId = m.MerchantId
GROUP BY m.MCC
HAVING COUNT(ft.TransactionId) > 100
ORDER BY ErrorPercentage DESC;

-- 4. Average Transaction Amount by Age Group
-- Helps understand spending patterns across different demographics
SELECT 
    CASE 
        WHEN u.CurrentAge < 25 THEN 'Under 25'
        WHEN u.CurrentAge BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.CurrentAge BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.CurrentAge BETWEEN 45 AND 54 THEN '45-54'
        WHEN u.CurrentAge BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and older'
    END AS age_group,
    COUNT(DISTINCT u.UserId) AS UserCount,
    COUNT(ft.TransactionId) AS TransactionCount,
    AVG(ft.amount) AS AvgTransactionAmount,
    SUM(ft.amount) / COUNT(DISTINCT u.UserId) AS AvgSpendPerUser
FROM Dim_User u
JOIN Fact_Transaction ft ON u.UserId = ft.UserId
GROUP BY 
    CASE 
        WHEN u.CurrentAge < 25 THEN 'Under 25'
        WHEN u.CurrentAge BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.CurrentAge BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.CurrentAge BETWEEN 45 AND 54 THEN '45-54'
        WHEN u.CurrentAge BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and older'
    END
ORDER BY age_group;

-- 5. Chip Usage Analysis
-- Tracks adoption of different card technologies
SELECT 
    cu.UsageDescription,
    COUNT(ft.TransactionId) AS TransactionCount,
    SUM(ft.amount) AS TotalAmount,
    AVG(ft.amount) AS avg_amount
FROM Fact_Transaction ft
JOIN Dim_ChipUsage cu ON ft.ChipUsageId = cu.ChipUsageId
GROUP BY cu.UsageDescription
ORDER BY TransactionCount DESC;

-- 6. Top Cities by Transaction Volume
-- Identifies geographic hotspots for transactions
SELECT TOP 20
    c.CityName,
    s.StateCode,
    COUNT(ft.TransactionId) AS TransactionCount,
    SUM(ft.amount) AS TotalAmount,
    COUNT(DISTINCT ft.UserId) AS unique_users
FROM Fact_Transaction ft
JOIN Dim_MerchantLocation ml ON ft.MerchantLocationId = ml.MerchantLocationId
JOIN Dim_City c ON ml.CityId = c.CityId
JOIN Dim_State s ON c.StateId = s.StateId
GROUP BY c.CityName, s.StateCode
ORDER BY TotalAmount DESC;

-- 7. Credit Score Impact on Spending Patterns
-- Analyzes how credit scores correlate with spending
SELECT 
    CASE 
        WHEN u.CreditScore < 580 THEN 'Poor (< 580)'
        WHEN u.CreditScore BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN u.CreditScore BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN u.CreditScore BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END AS credit_score_range,
    COUNT(DISTINCT u.UserId) AS NumberOfUsers,
    AVG(u.YearlyIncome) AS AvgIncome,
    AVG(u.TotalDebt) AS AvgDebt,
    COUNT(ft.TransactionId) / COUNT(DISTINCT u.UserId) AS AvgTransactionsPerUser,
    SUM(ft.amount) / COUNT(DISTINCT u.UserId) AS AvgSpendPerUser
FROM Dim_User u
JOIN Fact_Transaction ft ON u.UserId = ft.UserId
GROUP BY 
    CASE 
        WHEN u.CreditScore < 580 THEN 'Poor (< 580)'
        WHEN u.CreditScore BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN u.CreditScore BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN u.CreditScore BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END
ORDER BY AvgSpendPerUser DESC;

-- 8. Hourly Transaction Patterns
-- Identifies peak transaction times throughout the day
SELECT 
    d.hour,
    COUNT(ft.TransactionId) AS TransactionCount,
    SUM(ft.amount) AS TotalAmount,
    AVG(ft.amount) AS AvgTransactionAmount
FROM Fact_Transaction ft
JOIN Dim_Date d ON ft.DateId = d.DateId
GROUP BY d.hour
ORDER BY d.hour;
