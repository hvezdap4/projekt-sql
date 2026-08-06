--------------------------------------------------------------------------------
-- QUESTION 5: Does the level of GDP affect changes in wages and food prices? 
--             If GDP increases significantly in one year, does it translate into 
--             a more significant growth in food prices or wages in the same 
--             or the following year?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script blends aggregate year-over-year percentage changes of 
--             GDP, food prices, and wages into a single chronological matrix 
--             to analyze potential macroeconomic time lags. 
--------------------------------------------------------------------------------

WITH yoy_gdp_change AS (
    -- STEP 1: Calculate year-over-year percentage change of Czech GDP from the secondary table
    SELECT 
        "year" AS current_year,
        gdp AS current_gdp_value, -- Keeps the exact raw GDP value for percentage logic
        LAG(gdp) OVER (ORDER BY "year") AS previous_gdp,
        ROUND(
            (
                (gdp - LAG(gdp) OVER (ORDER BY "year")) 
                / 
                LAG(gdp) OVER (ORDER BY "year")::numeric * 100
            )::numeric, 2
        ) AS gdp_change_pct
    FROM t_anna_pasternakova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
      AND "year" BETWEEN 2006 AND 2018 -- Ensures full alignment with primary data scope
),

yoy_food_change AS (
    -- STEP 2: Compute the national average year-over-year price change across all food items
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
    -- STEP 3: Compute the national average year-over-year wage change across all industry branches
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

-- STEP 4: Combine all economic layers into a single chronological matrix with GDP in millions
SELECT 
    g.current_year,
    -- Divided by 1 million and rounded to 0 decimal places to show clean millions for data presentation
    ROUND((g.current_gdp_value / 1000000)::NUMERIC, 0) AS avg_gdp_mil_czk, 
    ROUND(g.gdp_change_pct::numeric, 2)::numeric(10,2) AS avg_gdp_difference_pct, 
    ROUND(f.avg_food_change_pct::numeric, 2)::numeric(10,2) AS avg_food_difference_pct, 
    ROUND(w.avg_wage_change_pct::numeric, 2)::numeric(10,2) AS avg_wage_difference_pct  
FROM yoy_gdp_change g
-- Changed to LEFT JOIN so the baseline year 2006 stays in the output even without YoY differences
LEFT JOIN yoy_food_change f ON g.current_year = f.current_year
LEFT JOIN yoy_wage_change w ON g.current_year = w.current_year
ORDER BY 
    g.current_year ASC;
