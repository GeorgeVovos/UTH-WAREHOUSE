-- Create the data warehouse database
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'financial_data_warehouse')
BEGIN
    ALTER DATABASE financial_data_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE financial_data_warehouse;
END
GO

CREATE DATABASE financial_data_warehouse;
GO

USE financial_data_warehouse;
GO

-- Create dimension tables first

-- User Dimension
CREATE TABLE dim_user (
    user_id INT PRIMARY KEY,
    current_age INT,
    retirement_age INT,
    birth_year INT,
    birth_month INT,
    gender VARCHAR(10),
    address VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    per_capita_income DECIMAL(10,2),
    yearly_income DECIMAL(10,2),
    total_debt DECIMAL(10,2),
    credit_score INT,
    num_credit_cards INT
);
GO

-- State Dimension
CREATE TABLE dim_state (
    state_id INT IDENTITY(1,1) PRIMARY KEY,
    state_code VARCHAR(50) UNIQUE
);
GO

-- City Dimension
CREATE TABLE dim_city (
    city_id INT IDENTITY(1,1) PRIMARY KEY,
    city_name VARCHAR(100),
    state_id INT,
    CONSTRAINT FK_city_state FOREIGN KEY (state_id) REFERENCES dim_state(state_id)
);
GO

-- Merchant Dimension
CREATE TABLE dim_merchant (
    merchant_id INT PRIMARY KEY,
    mcc INT
);
GO

-- Merchant Location Bridge Table (handles many-to-many relationship between merchants and cities)
CREATE TABLE dim_merchant_location (
    merchant_location_id INT IDENTITY(1,1) PRIMARY KEY,
    merchant_id INT,
    city_id INT,
    CONSTRAINT FK_merchant_location_merchant FOREIGN KEY (merchant_id) REFERENCES dim_merchant(merchant_id),
    CONSTRAINT FK_merchant_location_city FOREIGN KEY (city_id) REFERENCES dim_city(city_id),
    CONSTRAINT UQ_merchant_city UNIQUE (merchant_id, city_id)
);
GO

-- Date Dimension
CREATE TABLE dim_date (
    date_id DATETIME PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    hour INT,
    minute INT
);
GO

-- Chip Usage Dimension
CREATE TABLE dim_chip_usage (
    chip_usage_id INT IDENTITY(1,1) PRIMARY KEY,
    usage_description VARCHAR(50) UNIQUE
);
GO

-- Card Dimension
CREATE TABLE dim_card (
    card_id INT PRIMARY KEY,
    user_id INT,
    CONSTRAINT FK_dim_card_user FOREIGN KEY (user_id) REFERENCES dim_user(user_id)
);
GO

-- Create Fact table for transactions
CREATE TABLE fact_transaction (
    transaction_id INT PRIMARY KEY,
    date_id DATETIME,
    user_id INT,
    card_id INT,
    merchant_location_id INT,
    amount DECIMAL(10,2),
    chip_usage_id INT,
    error VARCHAR(100),
    CONSTRAINT FK_fact_transaction_date FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    CONSTRAINT FK_fact_transaction_user FOREIGN KEY (user_id) REFERENCES dim_user(user_id),
    CONSTRAINT FK_fact_transaction_card FOREIGN KEY (card_id) REFERENCES dim_card(card_id),
    CONSTRAINT FK_fact_transaction_merchant_location FOREIGN KEY (merchant_location_id) REFERENCES dim_merchant_location(merchant_location_id),
    CONSTRAINT FK_fact_transaction_chip_usage FOREIGN KEY (chip_usage_id) REFERENCES dim_chip_usage(chip_usage_id)
);
GO