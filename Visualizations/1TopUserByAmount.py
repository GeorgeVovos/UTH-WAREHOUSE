import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')
df = pd.read_sql("""
                    SELECT TOP 10
                        u.UserId,
                        COUNT(ft.TransactionId) AS TransactionCount,
                        SUM(ft.amount) AS TotalAmount
                    FROM Dim_User u
                    JOIN Fact_Transaction ft ON u.UserId = ft.UserId
                    GROUP BY u.UserId
                    ORDER BY TotalAmount DESC;

""", engine)


plt.ticklabel_format(style='plain', axis='y')

df = df.set_index('UserId')
ax = df['TotalAmount'].plot(kind='bar')

plt.title('Total Transaction Amount by User')
plt.xlabel('User ID')
plt.ylabel('Total Amount ($)')
plt.tight_layout()

plt.show()
