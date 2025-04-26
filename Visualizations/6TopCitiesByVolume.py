import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')


df = pd.read_sql("""
            SELECT TOP 20
                c.CityName + '-' +s.StateCode as 'City',
                SUM(ft.amount) AS TotalAmount
            FROM Fact_Transaction ft
            JOIN Dim_MerchantLocation ml ON ft.MerchantLocationId = ml.MerchantLocationId
            JOIN Dim_City c ON ml.CityId = c.CityId
            JOIN Dim_State s ON c.StateId = s.StateId
            GROUP BY c.CityName, s.StateCode
            ORDER BY TotalAmount DESC;
""", engine)


plt.figure(figsize=(12, 8))
ax = df.plot(kind='barh', x='City', y='TotalAmount', legend=False, color='coral')


plt.ticklabel_format(style='plain', axis='x')


for i, v in enumerate(df['TotalAmount']):
    ax.text(v + (v * 0.01), i, f'${v:,.0f}', va='center')


plt.title('Top 20 Cities by Transaction Volume')
plt.xlabel('Total Amount ($)')
plt.ylabel('City')
plt.grid(axis='x', linestyle='--', alpha=0.7)
plt.tight_layout()


plt.show()