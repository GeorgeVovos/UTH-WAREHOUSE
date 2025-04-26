USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'FinancialDataWarehouse')
BEGIN
    ALTER DATABASE FinancialDataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FinancialDataWarehouse;
END
GO

CREATE DATABASE FinancialDataWarehouse;
GO

USE FinancialDataWarehouse;
GO


CREATE TABLE Dim_User (
    UserId INT PRIMARY KEY,
    CurrentAge INT,
    RetirementAge INT,
    BirthYear INT,
    BirthMonth INT,
    Gender VARCHAR(10),
    Address VARCHAR(100),
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    PerCapitaIncome DECIMAL(10,2),
    YearlyIncome DECIMAL(10,2),
    TotalDebt DECIMAL(10,2),
    CreditScore INT,
    NumberOfCreditCards INT
);
GO

CREATE TABLE Dim_State (
    StateId INT IDENTITY(1,1) PRIMARY KEY,
    StateCode VARCHAR(50) UNIQUE
);
GO

CREATE TABLE Dim_City (
    CityId INT IDENTITY(1,1) PRIMARY KEY,
    CityName VARCHAR(100),
    StateId INT,
    CONSTRAINT FK_city_state FOREIGN KEY (StateId) REFERENCES Dim_State(StateId)
);
GO

CREATE TABLE Dim_Merchant (
    MerchantId INT PRIMARY KEY,
    MCC INT
);
GO

CREATE TABLE Dim_MerchantLocation (
    MerchantLocationId INT IDENTITY(1,1) PRIMARY KEY,
    MerchantId INT,
    CityId INT,
    CONSTRAINT FK_merchant_location_merchant FOREIGN KEY (MerchantId) REFERENCES Dim_Merchant(MerchantId),
    CONSTRAINT FK_merchant_location_city FOREIGN KEY (CityId) REFERENCES Dim_City(CityId),
    CONSTRAINT UQ_merchant_city UNIQUE (MerchantId, CityId)
);
GO

CREATE TABLE Dim_Date (
    DateId DATETIME PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    hour INT,
    minute INT
);
GO


CREATE TABLE Dim_ChipUsage (
    ChipUsageId INT IDENTITY(1,1) PRIMARY KEY,
    UsageDescription VARCHAR(50) UNIQUE
);
GO

CREATE TABLE Dim_Card (
    CardId INT PRIMARY KEY,
    UserId INT,
    CONSTRAINT FK_dim_card_user FOREIGN KEY (UserId) REFERENCES Dim_User(UserId)
);
GO


CREATE TABLE Fact_Transaction (
    TransactionId INT PRIMARY KEY,
    DateId DATETIME,
    UserId INT,
    CardId INT,
    MerchantLocationId INT,
    amount DECIMAL(10,2),
    ChipUsageId INT,
    error VARCHAR(100),
    CONSTRAINT FK_fact_transaction_date FOREIGN KEY (DateId) REFERENCES Dim_Date(DateId),
    CONSTRAINT FK_fact_transaction_user FOREIGN KEY (UserId) REFERENCES Dim_User(UserId),
    CONSTRAINT FK_fact_transaction_card FOREIGN KEY (CardId) REFERENCES Dim_Card(CardId),
    CONSTRAINT FK_fact_transaction_merchant_location FOREIGN KEY (MerchantLocationId) REFERENCES Dim_MerchantLocation(MerchantLocationId),
    CONSTRAINT FK_fact_transaction_chip_usage FOREIGN KEY (ChipUsageId) REFERENCES Dim_ChipUsage(ChipUsageId)
);
GO