--------------------------------------------------------------------------------
-- QUESTION 3: Which food category increases in price the slowest 
--             (has the lowest percentage year-over-year increase)?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script calculates the annual year-over-year (YoY) percentage 
--             price changes for all food categories and identifies the slowest growing one
--             while evaluating market stability using standard deviation.
--------------------------------------------------------------------------------

WITH unique_food_prices AS (
    -- STEP 1: Prepare a clean dataset of unique year-food price pairs
    SELECT DISTINCT 
        wages_year,
        food_code,
        food_name,
        avg_price
    FROM t_anna_pasternakova_project_sql_primary_final
),

yoy_price_changes AS (
    -- STEP 2: Calculate the year-over-year percentage change for each food item
    SELECT 
        wages_year,
        food_code,
        food_name,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year) AS previous_avg_price,
        ROUND(
            (
                (avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)) 
                / 
                LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric * 100
            )::numeric, 2
        ) AS yoy_change_pct
    FROM unique_food_prices
)
-- STEP 3: Aggregate all annual changes to track long-term trends and volatility
SELECT 
	food_name,
    -- 1) Main trend metric: Average annual percentage shift over the whole period (2006–2018)
    ROUND(AVG(yoy_change_pct)::numeric, 2)::numeric(10,2) AS avg_annual_change_pct,
    -- 2) Volatility metric: Standard deviation measuring price stability (lower = more stable)
    ROUND(STDDEV(yoy_change_pct)::numeric, 2)::numeric(10,2) AS price_volatility
FROM yoy_price_changes
WHERE yoy_change_pct IS NOT NULL -- Excludes the baseline year (2006)
GROUP BY 
    food_code, 
    food_name
ORDER BY 
    avg_annual_change_pct ASC; -- Ordered from the slowest growing (or most decreasing) to the fastest
