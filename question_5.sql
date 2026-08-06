--------------------------------------------------------------------------------
-- QUESTION 5: 	Does the level of GDP affect changes in wages and food prices? 
-- 				In other words, if GDP increases more significantly in one year, 
-- 				does it translate into a more significant growth in food prices 
-- 				or wages in the same or the following year?
-- AUTHOR:  Anna Pasternakova
-- PURPOSE: This script evaluates the macroeconomic relationship between GDP 
--          fluctuations, national wages, and food prices through two approaches:
--          1) Chronological Matrix: Tracks whether GDP, food, and wages went UP or DOWN 
--             each year and links them with the next year's market data.
--          2) Correlation Analysis measures the strength and direction of 
--             linear trends (r) without implying statistical significance.
--------------------------------------------------------------------------------

-- =============================================================================
-- APPROACH 1: Chronological Macroeconomic Matrix (Grouped Trend View)
-- PURPOSE: This script analyzes the macroeconomic impact of GDP fluctuations 
--          on national wages and food prices through a chronological matrix.
-- =============================================================================

WITH yoy_gdp_change AS (
    -- STEP 1: Calculate raw year-over-year percentage change of Czech GDP
    SELECT 
        "year" AS current_year,
        gdp AS current_gdp_value,
        LAG(gdp) OVER (ORDER BY "year") AS previous_gdp,
        (((gdp - LAG(gdp) OVER (ORDER BY "year")) / LAG(gdp) OVER (ORDER BY "year")::numeric) * 100) AS gdp_change_pct
    FROM t_anna_pasternakova_project_sql_secondary_final
    WHERE country = 'Czech Republic' AND "year" BETWEEN 2006 AND 2018
),

yoy_food_change AS (
    -- STEP 2: Compute the national average year-over-year price change across all food items
    SELECT wages_year AS current_year, AVG(yoy_change_pct) AS avg_food_change_pct
    FROM (
        SELECT wages_year, food_code,
            (((avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)) / LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric) * 100) AS yoy_change_pct
        FROM (SELECT DISTINCT wages_year, food_code, avg_price FROM t_anna_pasternakova_project_sql_primary_final) AS unique_prices
    ) AS food_calculations
    WHERE yoy_change_pct IS NOT NULL GROUP BY wages_year
),

yoy_wage_change AS (
    -- STEP 3: Compute the national average year-over-year wage change across all industry branches
    SELECT 
        wages_year AS current_year,
        AVG(yoy_wage_pct) AS avg_wage_change_pct
    FROM (
        SELECT wages_year, industry_code,
            (((avg_wages - LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)) / LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)::numeric) * 100) AS yoy_wage_pct
        FROM (SELECT DISTINCT wages_year, industry_code, avg_wages FROM t_anna_pasternakova_project_sql_primary_final) AS unique_wages
    ) AS wage_calculations
    WHERE yoy_wage_pct IS NOT NULL GROUP BY wages_year
),

chronological_trends AS (
    -- STEP 4: Build trend directions with NULL checks protecting the 2006 baseline row
    SELECT 
        g.current_year,
        ROUND((g.current_gdp_value / 1000000)::numeric, 0) AS gdp_mil_czk, 
        ROUND(g.gdp_change_pct::numeric, 2)::numeric(10,2) AS gdp_difference_pct, 
        ROUND(f.avg_food_change_pct::numeric, 2)::numeric(10,2) AS food_difference_pct, 
        ROUND(w.avg_wage_change_pct::numeric, 2)::numeric(10,2) AS wage_difference_pct,
        
        CASE 
            WHEN g.gdp_change_pct IS NOT NULL AND g.gdp_change_pct > 0 THEN 'UP' 
            WHEN g.gdp_change_pct < 0 THEN 'DOWN' 
            ELSE NULL 
        END AS gdp_dir,
        
        CASE 
            WHEN w.avg_wage_change_pct IS NOT NULL AND w.avg_wage_change_pct > 0 THEN 'UP' 
            WHEN w.avg_wage_change_pct < 0 THEN 'DOWN' 
            ELSE NULL 
        END AS wage_dir,
        
        CASE 
            WHEN f.avg_food_change_pct IS NOT NULL AND f.avg_food_change_pct > 0 THEN 'UP' 
            WHEN f.avg_food_change_pct < 0 THEN 'DOWN' 
            ELSE NULL 
        END AS food_dir
    FROM yoy_gdp_change g
    LEFT JOIN yoy_food_change f ON g.current_year = f.current_year
    LEFT JOIN yoy_wage_change w ON g.current_year = w.current_year
)
-- STEP 5: Final chronological presentation with fully grouped variables
SELECT 
    current_year,
    gdp_mil_czk,
    gdp_difference_pct,
    wage_difference_pct,
    food_difference_pct,
    gdp_dir AS gdp_trend,
    wage_dir AS wage_trend,
    CASE 
        WHEN gdp_dir IS NOT NULL AND LEAD(wage_dir) OVER (ORDER BY current_year) IS NOT NULL 
        THEN 'GDP ' || gdp_dir || ' = NY ' || LEAD(wage_dir) OVER (ORDER BY current_year)
        ELSE NULL
    END AS next_year_wage_trend,
    food_dir AS food_trend,
    CASE 
        WHEN gdp_dir IS NOT NULL AND LEAD(food_dir) OVER (ORDER BY current_year) IS NOT NULL 
        THEN 'GDP ' || gdp_dir || ' = NY ' || LEAD(food_dir) OVER (ORDER BY current_year)
        ELSE NULL
    END AS next_year_food_trend
FROM chronological_trends
ORDER BY current_year ASC;


-- =============================================================================
-- APPROACH 2: Correlation Analysis Matrix
-- PURPOSE: Calculates the Pearson correlation coefficient (r) to measure the 
--          direction and strength of the linear trend between percentage shifts in GDP 
--          versus wage shifts and food price shifts for the same year (t) and next year (t+1).
--          NOTE: This measures trend alignment only; it does not verify statistical significance.
-- =============================================================================


WITH summary_matrix AS (
    -- STEP 1: Blend raw percentage changes from both data dimensions without internal rounding
    SELECT 
        g."year" AS current_year,
        (((g.gdp - LAG(gdp) OVER (ORDER BY g."year")) / LAG(gdp) OVER (ORDER BY g."year")::numeric) * 100) AS gdp_pct,
        f.avg_food_pct AS food_pct,
        w.avg_wage_pct AS wage_pct
    FROM t_anna_pasternakova_project_sql_secondary_final g
    LEFT JOIN (
        SELECT wages_year, AVG(yoy) AS avg_food_pct FROM (
            SELECT wages_year, food_code, (((avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)) / LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric) * 100) AS yoy
            FROM (SELECT DISTINCT wages_year, food_code, avg_price FROM t_anna_pasternakova_project_sql_primary_final) AS up
        ) AS fc WHERE yoy IS NOT NULL GROUP BY wages_year
    ) f ON g."year" = f.wages_year
    LEFT JOIN (
        SELECT wages_year, AVG(yoy) AS avg_wage_pct FROM (
            SELECT wages_year, industry_code, (((avg_wages - LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)) / LAG(avg_wages) OVER (PARTITION BY industry_code ORDER BY wages_year)::numeric) * 100) AS yoy
            FROM (SELECT DISTINCT wages_year, industry_code, avg_wages FROM t_anna_pasternakova_project_sql_primary_final) AS uw
        ) AS wc WHERE yoy IS NOT NULL GROUP BY wages_year
    ) w ON g."year" = w.wages_year
    WHERE g.country = 'Czech Republic' AND g."year" BETWEEN 2006 AND 2018
),

shifted_matrix AS (
    -- STEP 2: Use LEAD to prepare look-ahead records for the Next Year calculation layer
    SELECT 
        gdp_pct,
        wage_pct,
        food_pct,
        LEAD(wage_pct) OVER (ORDER BY current_year) AS next_wage_pct,
        LEAD(food_pct) OVER (ORDER BY current_year) AS next_food_pct
    FROM summary_matrix
)
-- STEP 3: Aggregate correlation matrix for Same Year and Next Year time horizons
SELECT 
    'Same Year (t)' AS comparison_type,
    ROUND(CORR(wage_pct, gdp_pct)::numeric, 2)::numeric(10,2) AS wage_correlation_r,
    ROUND(CORR(food_pct, gdp_pct)::numeric, 2)::numeric(10,2) AS food_correlation_r
FROM shifted_matrix

UNION ALL

SELECT 
    'Next Year (t+1)' AS comparison_type,
    ROUND(CORR(next_wage_pct, gdp_pct)::numeric, 2)::numeric(10,2) AS wage_correlation_r,
    ROUND(CORR(next_food_pct, gdp_pct)::numeric, 2)::numeric(10,2) AS food_correlation_r
FROM shifted_matrix;
