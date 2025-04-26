import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')


df = pd.read_sql("""
    SELECT 
        CASE 
            WHEN u.CurrentAge < 25 THEN 'Under 25'
            WHEN u.CurrentAge BETWEEN 25 AND 34 THEN '25-34'
            WHEN u.CurrentAge BETWEEN 35 AND 44 THEN '35-44'
            WHEN u.CurrentAge BETWEEN 45 AND 54 THEN '45-54'
            WHEN u.CurrentAge BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65 and older'
        END AS AgeGroup,
        COUNT(ft.TransactionId) AS TransactionCount
    FROM Dim_User u
    JOIN Fact_Transaction ft ON u.UserId = ft.UserId
    GROUP BY 
        CASE 
            WHEN u.CurrentAge < 25 THEN 'Under 25'
            WHEN u.CurrentAge BETWEEN 25 AND 34 THEN '25-34'
            WHEN u.CurrentAge BETWEEN 35 AND 44 THEN '35-44'
            WHEN u.CurrentAge BETWEEN 45 AND 54 THEN '45-54'
            WHEN u.CurrentAge BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65 and older'
        END
    ORDER BY AgeGroup;
""", engine)


plt.figure(figsize=(10, 6))
ax = df.plot(kind='bar', x='AgeGroup', y='TransactionCount', legend=False, color='skyblue')


for p in ax.patches:
    ax.annotate(str(int(p.get_height())), 
                (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha='center', va='bottom')


plt.title('Transaction Count by Age Group')
plt.xlabel('Age Group')
plt.ylabel('Number of Transactions')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()


plt.show()