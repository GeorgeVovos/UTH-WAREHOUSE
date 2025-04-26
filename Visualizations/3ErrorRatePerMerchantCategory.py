import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')
df = pd.read_sql("""
                SELECT top 10
                    m.MCC,
                    (SUM(CASE WHEN ft.error IS NOT NULL AND ft.error != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(ft.TransactionId)) AS ErrorPercentage
                FROM Fact_Transaction ft
                JOIN Dim_MerchantLocation ml ON ft.MerchantLocationId = ml.MerchantLocationId
                JOIN Dim_Merchant m ON ml.MerchantId = m.MerchantId
                GROUP BY m.MCC
                HAVING COUNT(ft.TransactionId) > 100
                ORDER BY ErrorPercentage DESC;
""", engine)


df = df.set_index('MCC')
ax = df['ErrorPercentage'].plot(kind='bar', color='salmon')

plt.title('Error Rate by Merchant Category (MCC)')
plt.xlabel('Merchant Category Code (MCC)')
plt.ylabel('Error Percentage (%)')
plt.tight_layout()


for p in ax.patches:
    ax.annotate(f"{p.get_height():.2f}%", 
                (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha = 'center', va = 'bottom')

plt.show()