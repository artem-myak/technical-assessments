/*
================================================================================
BUN DESLIGA PLAYER ANALYSIS - CASE STUDY
================================================================================
Author: Artem
Tooling: ClickHouse Cloud
Dataset: Bundesliga Soccer Players (Kaggle)
Link: https://www.kaggle.com/datasets/oles04/bundesliga-soccer-player

TECHNICAL SETUP:
- Data imported via CSV into 'bundesliga_player' table.
- Column 'id' added to ensure correct header parsing.
- Data types optimized for ClickHouse performance.
================================================================================
*/

-- 1. ТОР-3 клуби із найдорожчим захистом (Defender-*)
-- Використано фільтрацію за підрядком, щоб охопити всі варіації захисних позицій.
SELECT
    club,
    SUM(price) AS total_def_price
FROM bundesliga_player
WHERE position LIKE '%Defender%'
GROUP BY club
ORDER BY total_def_price DESC
LIMIT 3;


-- 2. Кількість гравців, що підписали контракт після конкретного гравця (у розрізі клубу)
-- ОПТИМІЗАЦІЯ: Використано віконний фрейм ROWS BETWEEN для точного підрахунку наступних рядків,
-- що коректно обробляє випадки з однаковими датами приєднання (joined_club).
SELECT
    club,
    name,
    joined_club,
    COUNT(*) OVER (
        PARTITION BY club 
        ORDER BY joined_club ASC 
        ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
    ) as players_joined_after
FROM bundesliga_player
ORDER BY club, joined_club;


-- 3. Клуби, де середня вартість французьких гравців більша за 5 млн
SELECT
    club,
    round(avg(price), 2) as avg_price
FROM bundesliga_player
WHERE nationality LIKE '%France%'
GROUP BY club
HAVING avg_price > 5
ORDER BY avg_price DESC;


-- 4. Клуби, де частка німців вища за 90%
SELECT
    club,
    ROUND(100.0 * SUM(CASE WHEN nationality LIKE '%Germany%' THEN 1 ELSE 0 END) / count(*), 2) AS germany_share
FROM bundesliga_player
GROUP BY club
HAVING germany_share > 90
ORDER BY germany_share DESC;


-- 5. Найдорожчий гравець у кожній віковій категорії
WITH ranked_players AS
(
    SELECT
        name,
        price,
        age,
        rank() over(partition by age ORDER BY price DESC) as price_rank
    FROM bundesliga_player
)
SELECT
    name,
    price,
    age
FROM ranked_players
WHERE price_rank = 1
ORDER BY age;


-- 6. Гравці з вартістю у 1.5 раза вищою за середню по своїй позиції
WITH avg_position_price AS
(
    SELECT
        name,
        position,
        price,
        avg(price) over(partition by position) as avg_pos_price
    FROM bundesliga_player
)
SELECT
    name,
    position,
    price,
    round(avg_pos_price, 2) as avg_pos_price
FROM avg_position_price
WHERE price >= 1.5 * avg_pos_price
ORDER BY price DESC;


-- 7. Позиція, на якій найважче отримати контракт з екіпірувальником (Puma/Adidas/Nike)
-- ОПТИМІЗАЦІЯ: Аналіз перенесено з агентів на поле 'outfitter' (технічні спонсори) для відповіді на бізнес-запит.
SELECT
    position,
    round(100.0 * SUM(CASE WHEN outfitter = '' OR outfitter IS NULL THEN 1 ELSE 0 END) / count(*), 2) AS no_outfitter_share
FROM bundesliga_player
GROUP BY position
ORDER BY no_outfitter_share DESC
LIMIT 1;


-- 8. Команда, у якої найперше закінчиться контракт одночасно у 5 гравців
-- Використано двоступеневе ранжування для ідентифікації "черги на вибуття".
WITH contract_players AS
(
    SELECT
        club,
        contract_expires,
        dateDiff('day', today(), contract_expires) as contract_days_left,
        row_number() over(partition by club ORDER BY contract_expires ASC) as lost_player_order
    FROM bundesliga_player
    WHERE contract_expires > today()
),
fifth_player_deadline AS
(
    SELECT
        club,
        contract_days_left,
        rank() over(ORDER BY contract_days_left ASC) AS final_rank
    FROM contract_players
    WHERE lost_player_order = 5
)
SELECT
    club,
    contract_days_left
FROM fifth_player_deadline
WHERE final_rank = 1
ORDER BY club;


-- 9. Вік, у якому гравці найчастіше виходять на індивідуальний пік вартості
-- ОПТИМІЗАЦІЯ: Замість медіани цін використано порівняння з 'max_price' для аналізу життєвого циклу гравця.
SELECT
    age,
    count(*) as players_at_peak_count
FROM bundesliga_player
WHERE price = max_price AND price > 0
GROUP BY age
ORDER BY players_at_peak_count DESC
LIMIT 1;


-- 10. Найзіграніший склад (найвищий медіанний час перебування в клубі)
-- Медіана обрана для усунення впливу "аутлаєрів" (ветеранів або новачків) на загальну статистику зіграності.
WITH team_together AS
(
    SELECT
        club,
        dateDiff('day', joined_club, today()) as days_in_club
    FROM bundesliga_player
    WHERE contract_expires > today()
)
SELECT
    club,
    median(days_in_club) AS median_days_together
FROM team_together
GROUP BY club
ORDER BY median_days_together DESC
LIMIT 1;


-- 11. Клуби, де є тезки (гравці з однаковими іменами)
WITH same_name_clubs AS
(
    SELECT
        club,
        splitByChar(' ', name)[1] AS first_name,
        count(*) AS first_name_cnt
    FROM bundesliga_player
    GROUP BY club, first_name
    HAVING first_name_cnt > 1
)
SELECT
    club
FROM same_name_clubs
GROUP BY club
ORDER BY club;


-- 12. Команди з високою концентрацією капіталу (Топ-3 гравці > 50% бюджету)
-- Аналіз фінансових ризиків: ідентифікація залежності клубу від вузького кола лідерів.
WITH valuable_players_rank AS
(
    SELECT
        club,
        price,
        dense_rank() over(partition by club ORDER BY price DESC) as highest_price_rank,
        sum(price) over(partition by club) as total_salary
    FROM bundesliga_player
),
top3_calc AS
(
    SELECT
        club,
        sum(CASE WHEN highest_price_rank <= 3 THEN price ELSE 0 END) as top3_salary,
        max(total_salary) AS club_total    
    FROM valuable_players_rank
    GROUP BY club
)
SELECT
    club
FROM top3_calc
WHERE top3_salary >= club_total * 0.5
ORDER BY club;