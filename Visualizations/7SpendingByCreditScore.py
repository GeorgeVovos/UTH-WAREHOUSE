import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')


df = pd.read_sql("""
        SELECT 
            CASE 
                WHEN u.CreditScore < 580 THEN 'Poor (< 580)'
                WHEN u.CreditScore BETWEEN 580 AND 669 THEN 'Fair (580-669)'
                WHEN u.CreditScore BETWEEN 670 AND 739 THEN 'Good (670-739)'
                WHEN u.CreditScore BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
                ELSE 'Excellent (800+)'
            END AS CreditScoreRange,
            COUNT(DISTINCT u.UserId) AS NumberOfUsers,
            AVG(u.YearlyIncome) AS AvgIncome,
            AVG(u.TotalDebt) AS AvgDebt,
            COUNT(ft.TransactionId) / COUNT(DISTINCT u.UserId) AS AvgTransactionsPerUser,
            SUM(ft.amount) / COUNT(DISTINCT u.UserId) AS AvgSpendPerUser
        FROM Dim_User u
        JOIN Fact_Transaction ft ON u.UserId = ft.UserId
        GROUP BY 
            CASE 
                WHEN u.CreditScore < 580 THEN 'Poor (< 580)'
                WHEN u.CreditScore BETWEEN 580 AND 669 THEN 'Fair (580-669)'
                WHEN u.CreditScore BETWEEN 670 AND 739 THEN 'Good (670-739)'
                WHEN u.CreditScore BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
                ELSE 'Excellent (800+)'
            END
        ORDER BY AvgSpendPerUser DESC;
""", engine)


plt.figure(figsize=(12, 6))
ax = df.plot(kind='bar', x='CreditScoreRange', y='AvgSpendPerUser', legend=False, color='purple')


plt.ticklabel_format(style='plain', axis='y')


for p in ax.patches:
    ax.annotate(f'${p.get_height():,.2f}', 
                (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha='center', va='bottom')


plt.title('Average Spending per User by Credit Score Range')
plt.xlabel('Credit Score Range')
plt.ylabel('Average Spending per User ($)')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()


plt.show()