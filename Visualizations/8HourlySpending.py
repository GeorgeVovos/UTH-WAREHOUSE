import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy

engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')

df = pd.read_sql("""
        SELECT 
            d.hour as Hour,
            SUM(ft.amount) AS TotalAmount
        FROM Fact_Transaction ft
        JOIN Dim_Date d ON ft.DateId = d.DateId
        GROUP BY d.hour
        ORDER BY d.hour;

""", engine)


plt.ticklabel_format(style='plain', axis='y')

df = df.set_index('Hour')

ax = df['TotalAmount'].plot(kind='bar')

plt.title('Hourly Transaction Patterns')
plt.xlabel('Hour of Day')
plt.ylabel('Total Amount ($)')
plt.tight_layout()

plt.show()