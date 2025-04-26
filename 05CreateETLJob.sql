USE [msdb];
GO


IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'UTH_Warehouse_Nightly_ETL')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'UTH_Warehouse_Nightly_ETL', @delete_unused_schedule = 1;
END
GO


IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N'Data Warehouse' AND category_class = 1)
BEGIN
    EXEC msdb.dbo.sp_add_category 
        @class = N'JOB', 
        @type = N'LOCAL', 
        @name = N'Data Warehouse';
END
GO


DECLARE @owner_login_name NVARCHAR(128)
SET @owner_login_name = SUSER_SNAME()

EXEC msdb.dbo.sp_add_job 
    @job_name = N'UTH_Warehouse_Nightly_ETL',
    @description = N'Job to load data into the UTH data warehouse nightly',
    @category_name = N'Data Warehouse',
    @owner_login_name = @owner_login_name,
    @enabled = 1;
GO


EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'UTH_Warehouse_Nightly_ETL',
    @step_name = N'Execute ETL Stored Procedures',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 1,  -- Quit with success
    @on_fail_action = 2,     -- Quit with failure
    @retry_attempts = 3,
    @retry_interval = 5,     -- 5 minutes between retries
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC sp_load_user_data 
    @dataFile = ''C:\dev\UTH\UTH-WAREHOUSE\users_data.csv'',
    @formatFile = ''C:\dev\UTH\UTH-WAREHOUSE\users_format.fmt'',
    @errorFile = ''C:\dev\UTH\UTH-WAREHOUSE\users_errors.txt'';

EXEC sp_load_transaction_data
    @dataFile = ''C:\dev\UTH\UTH-WAREHOUSE\transactions_data_full.csv'',
    @errorFile = ''C:\dev\UTH\UTH-WAREHOUSE\transactions_errors.txt'';',
    @database_name = N'FinancialDataWarehouse',
    @flags = 0;
GO

EXEC msdb.dbo.sp_add_jobserver 
    @job_name = N'UTH_Warehouse_Nightly_ETL',
    @server_name = N'(local)';
GO

-- Create a schedule to run nightly at 2:00 AM
DECLARE @schedule_id INT;
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name = N'UTH_Warehouse_Nightly_ETL',
    @name = N'Daily at 2AM',
    @freq_type = 4,          -- Daily
    @freq_interval = 1,      -- Every 1 day
    @freq_subday_type = 1,   -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 0,
    @active_start_date = 20230101,  -- Start date (YYYYMMDD)
    @active_end_date = 99991231,    -- End date (YYYYMMDD)
    @active_start_time = 20000,     -- 2:00 AM (HHMMSS)
    @active_end_time = 235959,      -- 11:59:59 PM
    @schedule_id = @schedule_id OUTPUT,
    @schedule_uid = NULL,
    @enabled = 1;
GO

PRINT 'UTH_Warehouse_Nightly_ETL job has been created successfully and scheduled to run daily at 2:00 AM.';
GO