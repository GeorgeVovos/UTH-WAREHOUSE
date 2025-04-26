
## Data
The datasets (.csv) files can be found at https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data   
Ensure the line endings in the files use "CRLF" (you can edit them using VS Code or another editor)

Uses_data.csv is included in this repo.    
The original transactions_data.csv is 1.3GB , a subset of it is included in this repo as transactions_data_small.csv

## Instructions
- Have an instance of Microsoft SQL Server 2022 available (Express, Developer, etc)
- Run 01CreateDataWarehouse.sql to create a new database and the related tables
- Run 02CreateStoredProcs.sql to create the stored procedures that insert the data into tables
- Run 03ExecureStoredProcsToLoadData.sql to read the .csv files and insert data into the db (use valid file path for the arguments)
- Run any number of the queries available in 04Queries.sql
- (Optional) - Run 05CreateETLJob.sql
