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


plt.figure(figsize=(10, 6))
ax = df.plot(kind='bar', x='UsageDescription', y='TransactionCount', legend=False, color='lightgreen')


for p in ax.patches:
    ax.annotate(str(int(p.get_height())), 
                (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha='center', va='bottom')


plt.title('Transaction Count by Chip Usage Type')
plt.xlabel('Chip Usage Type')
plt.ylabel('Number of Transactions')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()

plt.show()
