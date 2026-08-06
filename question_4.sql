--------------------------------------------------------------------------------
-- QUESTION 4: Is there a year where the year-over-year increase in food prices 
--             was significantly higher than wage growth (greater than a 10% difference)?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script calculates and compares the aggregate national annual 
--             percentage change of food prices against national wage changes.
--------------------------------------------------------------------------------

WITH yoy_food_change AS (
    -- STEP 1: Compute the national average year-over-year price change across all food items
    SELECT 
        wages_year AS current_year,
        AVG(yoy_change_pct) AS avg_food_change_pct
    FROM (
        SELECT 
            wages_year,
            food_code,
            ROUND(
                (
                    (avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)) 
                    / 
                    LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric * 100
                )::numeric, 2
            ) AS yoy_change_pct
        FROM (
            SELECT DISTINCT wages_year, food_code, avg_price 
            FROM t_anna_pasternakova_project_sql_primary_final
        ) AS unique_prices
    ) AS food_calculations
    WHERE yoy_change_pct IS NOT NULL
    GROUP BY wages_year
),

yoy_wage_change AS (
    -- STEP 2: Compute the national average year-over-year wage change across all industry branches
    SELECT 
        wages_year AS current_year,
        AVG(yoy_wage_pct) AS avg_wage_change_pct
    FROM (
        SELECT 
            wages_year,
            industry_code,
            ROUND(
                (
                    (avg_wages - LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)) 
                    / 
                    LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)::numeric * 100
                )::numeric, 2
            ) AS yoy_wage_pct
        FROM (
            SELECT DISTINCT wages_year, industry_code, avg_wages 
            FROM t_anna_pasternakova_project_sql_primary_final
        ) AS unique_wages
    ) AS wage_calculations
    WHERE yoy_wage_pct IS NOT NULL
    GROUP BY wages_year
)

-- STEP 3: Merge both perspectives and evaluate the absolute macroeconomic difference
SELECT 
    f.current_year,
    ROUND(f.avg_food_change_pct::numeric, 2)::numeric(10,2) AS avg_food_change_pct, 
    ROUND(w.avg_wage_change_pct::numeric, 2)::numeric(10,2) AS avg_wage_change_pct, 
    -- Food price variance minus wage variance to find the net financial pressure on citizens
    ROUND((f.avg_food_change_pct - w.avg_wage_change_pct)::numeric, 2)::numeric(10,2) AS difference_pct,
    -- Case statement to explicitly flag years that satisfy 10% condition
    CASE 
        WHEN (f.avg_food_change_pct - w.avg_wage_change_pct) > 10 THEN 'YES - Food shifted > 10% faster'
        ELSE 'NO'
    END AS is_significantly_higher
FROM yoy_food_change f
JOIN yoy_wage_change w 
    ON f.current_year = w.current_year
ORDER BY 
    difference_pct DESC;
