-- 1. Top 10 Users by Total Transaction Amount
-- This query identifies your highest value customers
SELECT TOP 10
    u.user_id,
    u.yearly_income,
    u.credit_score,
    COUNT(ft.transaction_id) AS transaction_count,
    SUM(ft.amount) AS total_amount
FROM dim_user u
JOIN fact_transaction ft ON u.user_id = ft.user_id
GROUP BY u.user_id, u.yearly_income, u.credit_score
ORDER BY total_amount DESC;

-- 2. Transaction Volume by Month
-- Helps identify seasonal patterns in spending
SELECT 
    d.year,
    d.month,
    COUNT(ft.transaction_id) AS transaction_count,
    SUM(ft.amount) AS total_amount
FROM fact_transaction ft
JOIN dim_date d ON ft.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 3. Merchant Categories with Highest Error Rates
-- Helps identify potential fraud or technical issues with specific merchant types
SELECT 
    m.mcc,
    COUNT(ft.transaction_id) AS total_transactions,
    SUM(CASE WHEN ft.error IS NOT NULL AND ft.error != '' THEN 1 ELSE 0 END) AS error_count,
    (SUM(CASE WHEN ft.error IS NOT NULL AND ft.error != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(ft.transaction_id)) AS error_percentage
FROM fact_transaction ft
JOIN dim_merchant_location ml ON ft.merchant_location_id = ml.merchant_location_id
JOIN dim_merchant m ON ml.merchant_id = m.merchant_id
GROUP BY m.mcc
HAVING COUNT(ft.transaction_id) > 100
ORDER BY error_percentage DESC;

-- 4. Average Transaction Amount by Age Group
-- Helps understand spending patterns across different demographics
SELECT 
    CASE 
        WHEN u.current_age < 25 THEN 'Under 25'
        WHEN u.current_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.current_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.current_age BETWEEN 45 AND 54 THEN '45-54'
        WHEN u.current_age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and older'
    END AS age_group,
    COUNT(DISTINCT u.user_id) AS user_count,
    COUNT(ft.transaction_id) AS transaction_count,
    AVG(ft.amount) AS avg_transaction_amount,
    SUM(ft.amount) / COUNT(DISTINCT u.user_id) AS avg_spend_per_user
FROM dim_user u
JOIN fact_transaction ft ON u.user_id = ft.user_id
GROUP BY 
    CASE 
        WHEN u.current_age < 25 THEN 'Under 25'
        WHEN u.current_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.current_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.current_age BETWEEN 45 AND 54 THEN '45-54'
        WHEN u.current_age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and older'
    END
ORDER BY age_group;

-- 5. Chip Usage Analysis
-- Tracks adoption of different card technologies
SELECT 
    cu.usage_description,
    COUNT(ft.transaction_id) AS transaction_count,
    SUM(ft.amount) AS total_amount,
    AVG(ft.amount) AS avg_amount
FROM fact_transaction ft
JOIN dim_chip_usage cu ON ft.chip_usage_id = cu.chip_usage_id
GROUP BY cu.usage_description
ORDER BY transaction_count DESC;

-- 6. Top Cities by Transaction Volume
-- Identifies geographic hotspots for transactions
SELECT TOP 20
    c.city_name,
    s.state_code,
    COUNT(ft.transaction_id) AS transaction_count,
    SUM(ft.amount) AS total_amount,
    COUNT(DISTINCT ft.user_id) AS unique_users
FROM fact_transaction ft
JOIN dim_merchant_location ml ON ft.merchant_location_id = ml.merchant_location_id
JOIN dim_city c ON ml.city_id = c.city_id
JOIN dim_state s ON c.state_id = s.state_id
GROUP BY c.city_name, s.state_code
ORDER BY total_amount DESC;

-- 7. Credit Score Impact on Spending Patterns
-- Analyzes how credit scores correlate with spending
SELECT 
    CASE 
        WHEN u.credit_score < 580 THEN 'Poor (< 580)'
        WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END AS credit_score_range,
    COUNT(DISTINCT u.user_id) AS num_users,
    AVG(u.yearly_income) AS avg_income,
    AVG(u.total_debt) AS avg_debt,
    COUNT(ft.transaction_id) / COUNT(DISTINCT u.user_id) AS avg_transactions_per_user,
    SUM(ft.amount) / COUNT(DISTINCT u.user_id) AS avg_spend_per_user
FROM dim_user u
JOIN fact_transaction ft ON u.user_id = ft.user_id
GROUP BY 
    CASE 
        WHEN u.credit_score < 580 THEN 'Poor (< 580)'
        WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END
ORDER BY avg_spend_per_user DESC;

-- 8. Hourly Transaction Patterns
-- Identifies peak transaction times throughout the day
SELECT 
    d.hour,
    COUNT(ft.transaction_id) AS transaction_count,
    SUM(ft.amount) AS total_amount,
    AVG(ft.amount) AS avg_transaction_amount
FROM fact_transaction ft
JOIN dim_date d ON ft.date_id = d.date_id
GROUP BY d.hour
ORDER BY d.hour;
