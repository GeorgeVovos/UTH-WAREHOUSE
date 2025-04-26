EXEC sp_load_user_data 
    @dataFile = 'C:\dev\UTH\UTH-WAREHOUSE\users_data.csv',
    @formatFile = 'C:\dev\UTH\UTH-WAREHOUSE\users_format.fmt',
    @errorFile = 'C:\dev\UTH\UTH-WAREHOUSE\users_errors.txt';


EXEC sp_load_transaction_data
    @dataFile = 'C:\dev\UTH\UTH-WAREHOUSE\transactions_data_full.csv',
    @errorFile = 'C:\dev\UTH\UTH-WAREHOUSE\transactions_errors.txt';