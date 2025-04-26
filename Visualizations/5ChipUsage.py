import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')


df = pd.read_sql("""
    SELECT 
        cu.UsageDescription,
        COUNT(ft.TransactionId) AS TransactionCount
    FROM Fact_Transaction ft
    JOIN Dim_ChipUsage cu ON ft.ChipUsageId = cu.ChipUsageId
    GROUP BY cu.UsageDescription
    ORDER BY TransactionCount DESC;
""", engine)


plt.figure(figsize=(10, 8))
plt.pie(df['TransactionCount'], labels=df['UsageDescription'], autopct='%1.1f%%', 
        startangle=90, shadow=True, explode=[0.05] * len(df), 
        colors=plt.cm.Paired(range(len(df))))

plt.title('Transaction Count by Chip Usage Type')
plt.axis('equal') 
plt.tight_layout()

plt.show()
