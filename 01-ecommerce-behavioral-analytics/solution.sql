/* ================================================================================
E-COMMERCE BEHAVIORAL ANALYTICS CASE STUDY
SQL Solution Script
================================================================================
*/

-- 1.1. Базова агрегація: ТОП-10 країн за кількістю реєстрацій у 2024 році
/*
Логіка:
1. Групуємо за країною та підраховуємо унікальних користувачів.
2. Фільтруємо за 2024 роком (універсальний формат дати).
3. Сортуємо за спаданням та обмежуємо вибірку 10 записами.
*/
SELECT 
    country,
    COUNT(user_id) AS user_cnt
FROM users
WHERE registration_date >= '2024-01-01' 
  AND registration_date < '2025-01-01'
GROUP BY country
ORDER BY user_cnt DESC
LIMIT 10;


-- 1.2. Конверсія: З реєстрації в перше замовлення (%) по місяцях
/*
Логіка:
1. Використовуємо LEFT JOIN, щоб врахувати всіх зареєстрованих юзерів.
2. Конверсія рахується як (Користувачі із замовленнями / Усі зареєстровані користувачі) * 100.
*/
SELECT
    strftime('%Y-%m', u.registration_date) AS month,
    COUNT(u.user_id) AS total_users,
    COUNT(DISTINCT o.user_id) AS total_buyers,
    ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(u.user_id), 2) AS conversion_rate
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY month
ORDER BY month;


-- 1.3. Фільтрація: Користувачі з >3 транзакціями та 0 успішних статусів
/*
Логіка:
1. Групуємо за користувачем.
2. Умова SUM(CASE...) = 0 гарантує відсутність статусу 'completed' у всій історії транзакцій юзера.
*/
SELECT
    user_id,
    COUNT(user_id) AS transaction_cnt
FROM orders 
GROUP BY user_id
HAVING COUNT(user_id) > 3 
   AND SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) = 0
ORDER BY transaction_cnt DESC;


-- 1.4. Когортний аналіз: Retention Day 1, Day 7, Day 30
/*
Логіка:
1. Вираховуємо різницю в днях між реєстрацією та подією через julianday().
2. Рахуємо унікальних юзерів, що повернулися у конкретний день, відносно розміру когорти.
*/
SELECT
    strftime('%Y-%m', u.registration_date) AS cohort_month,
    COUNT(DISTINCT u.user_id) AS total_users,
    ROUND(COUNT(DISTINCT CASE WHEN CAST(julianday(e.event_date) - julianday(u.registration_date) AS INTEGER) = 1 THEN u.user_id END) * 100.0 / COUNT(DISTINCT u.user_id), 2) AS retention_day1,
    ROUND(COUNT(DISTINCT CASE WHEN CAST(julianday(e.event_date) - julianday(u.registration_date) AS INTEGER) = 7 THEN u.user_id END) * 100.0 / COUNT(DISTINCT u.user_id), 2) AS retention_day7,
    ROUND(COUNT(DISTINCT CASE WHEN CAST(julianday(e.event_date) - julianday(u.registration_date) AS INTEGER) = 30 THEN u.user_id END) * 100.0 / COUNT(DISTINCT u.user_id), 2) AS retention_day30
FROM users u
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY cohort_month
ORDER BY cohort_month;


-- 1.5. Віконні функції: Динаміка AOV (Average Order Value) та WoW Growth %
/*
Логіка:
1. CTE WeeklyAOV розраховує середній чек по тижнях.
2. LAG() підтягує дані попереднього тижня для розрахунку відсоткової зміни.
*/
WITH WeeklyAOV AS
(
    SELECT
        strftime('%Y-%W', order_date) AS week_num,
        ROUND(AVG(amount), 2) AS AOV
    FROM orders
    GROUP BY week_num
)
SELECT
    week_num,
    AOV,
    LAG(AOV) OVER(ORDER BY week_num) AS prev_AOV,
    ROUND((AOV - LAG(AOV) OVER(ORDER BY week_num)) * 100.0 / LAG(AOV) OVER(ORDER BY week_num), 2) AS percent_change
FROM WeeklyAOV
ORDER BY week_num;