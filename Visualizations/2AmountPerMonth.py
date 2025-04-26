import pandas as pd
import matplotlib.pyplot as plt
import sqlalchemy


engine = sqlalchemy.create_engine('mssql+pyodbc://localhost/FinancialDataWarehouse?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes')
df = pd.read_sql("""
                -- 2. Transaction Volume by Month
                -- Helps identify seasonal patterns in spending
                SELECT 
                    (CAST(d.year as varchar(5)) + '/' + CAST(d.month as varchar(3)))  as' Month',
                
                    CAST(SUM(ft.amount) AS INT) AS TotalAmount
                FROM Fact_Transaction ft
                JOIN Dim_Date d ON ft.DateId = d.DateId
                WHERE YEAR=2018
                GROUP BY d.year, d.month
                ORDER BY d.year, d.month;

""", engine)

# Create a figure and axis
plt.figure(figsize=(12, 6))

# Create bar chart with Month as X-axis and TotalAmount as Y-axis
bars = plt.bar(df[' Month'], df['TotalAmount'], color='skyblue')

# Add title and labels
plt.title('Transaction Volume by Month (2018)', fontsize=16)
plt.xlabel('Month', fontsize=12)
plt.ylabel('Total Amount', fontsize=12)

# Improve readability
plt.xticks(rotation=45)
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Add data value labels on top of each bar - updated to display as integers
for bar in bars:
    height = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2., height,
             f'{int(height):,}', ha='center', va='bottom', rotation=0)

# Adjust layout
plt.tight_layout()

plt.show()
