import pandas as pd
import os
import xml.etree.ElementTree as ET

data_folder = 'data'  # шлях до папки з файлами
all_rows_data = [] # створюємо порожній список для відпарсених даних

# проходимо по всіх файлах у папці
for filename in os.listdir(data_folder):
    if filename.endswith('.xml'):
        # отримуємо id клієнта з назви файлу
        client_id = filename

        # читаємо структуру XML
        filepath = os.path.join(data_folder, filename)
        tree = ET.parse(filepath)
        root = tree.getroot()

        # знаходимо всі кредити клієнта (шукаємо тег на усіх рівнях вкладеності)
        crdeals = root.findall('.//crdeal')

        for deal in crdeals:
            # номер кредиту
            loan_id = deal.get('dlref', 'unknown')

            # знаходимо всю історію станів по цьому кредиту (loan historical periods)
            deallifes = deal.findall('deallife')
            if not deallifes:
                continue  # якщо історії немає, пропускаємо

            # проходимо по всій історії кредиту
            for state in deallifes:
                # витягуємо дату зрізу (якщо немає, ставимо дуже стару, щоб вона не була максимальною при сортуванні)
                date_calc = state.get('dldateclc', '1900-01-01')

                # витягуємо інші дані з обробкою помилок
                # статус кредиту
                try:
                    status = int(state.get('dlflstat', 0))
                except ValueError:
                    status = 0
                # кількість днів просрочення
                try:
                    days_exp = int(state.get('dldayexp', 0))
                except ValueError:
                    days_exp = 0
                # сума просрочення
                try:
                    exp_amount = float(state.get('dlamtexp', 0.0))
                except ValueError:
                    exp_amount = 0.0

                # додаємо рядок із даними у кінець нашого списку
                all_rows_data.append({
                    'Client_id': client_id,
                    'Loan_id': loan_id,
                    'Report_Date': date_calc,
                    'Loan_Status': status,
                    'Days_Expired': days_exp,
                    'Expired_Amount': exp_amount
                })

# конвертуємо список у датафрейм
df = pd.DataFrame(all_rows_data)

df['Report_Date'] = pd.to_datetime(df['Report_Date'])

# cортуємо таблицю за клієнтом, кредитом і датою зрізу (за зростанням)
# тепер для кожного кредиту найсвіжіший запис буде знаходитися найнижче
df = df.sort_values(by=['Client_id', 'Loan_id', 'Report_Date'])

# видаляємо дублікати, залишаючи останній (насвіжіший за датою) запис
df = df.drop_duplicates(subset=['Client_id', 'Loan_id'], keep='last')

# Total count of loans (Загальна кількість кредитів)
total_loans = df.groupby('Client_id')['Loan_id'].count()

# Ratio of closed loans count over total loans count
ratio_closed_loans = (((df['Loan_Status'] == 2).groupby(df['Client_id']).mean())*100.0).round(2)

# Sum of currently expired deals amount over 30+ days
sum_expired_30plus = df[df['Days_Expired'] > 30].groupby('Client_id')['Expired_Amount'].sum()

# збираємо всі метрики у фінальну таблицю
final_report = pd.DataFrame({
    'Total_Loans': total_loans,
    'Ratio_Closed': ratio_closed_loans,
    'Sum_Expired_30+': sum_expired_30plus
}).fillna(0)  # замінюємо NaN на 0, якщо у клієнта не було прострочок взагалі

print(final_report)
# для зручного копіювання у файл results.docx
#final_report.to_csv('my_results.csv', sep=';')