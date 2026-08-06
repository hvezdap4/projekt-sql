--------------------------------------------------------------------------------
-- QUESTION 3: Which food category increases in price the slowest 
--             (has the lowest percentage year-over-year increase)?
-- AUTHOR:     Anna Pasternaková
-- PURPOSE:    This script analyzes food inflation through two sections:
--             1) Main Presentation: A complete market overview calculating 
--                average annual shifts and volatility (standard deviation).
--                Filters ONLY for products with a complete historical timeline (12 YoY changes).
--             2) Bonus Case Study: A deep dive into the yearly price timeline 
--                for the absolute winner (Sugar) and the most stable item (Wine).
--------------------------------------------------------------------------------

-- =============================================================================
-- SECTION 1: Main Market Overview
-- PURPOSE: Evaluates the long-term trend and price stability for all food items.
-- =============================================================================

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
    -- 1) Average YoY growth (Can be skewed by extreme shocks)
    ROUND(AVG(yoy_change_pct)::numeric, 2)::numeric(10,2) AS avg_annual_change_pct,
    -- 2) Median YoY growth (Shows the typical/normal year, ignores extreme spikes)
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY yoy_change_pct)::numeric, 2)::numeric(10,2) AS median_annual_change_pct,
    -- 3) Volatility metric (Standard deviation measuring price stability)
    ROUND(STDDEV(yoy_change_pct)::numeric, 2)::numeric(10,2) AS price_volatility
FROM yoy_price_changes
WHERE yoy_change_pct IS NOT NULL -- Excludes the baseline year (2006)
GROUP BY 
    food_code, 
    food_name
-- CRITICAL FILTER: Ensures a fair comparison by including only products with a full 13-year dataset (12 YoY changes)
HAVING 
    COUNT(yoy_change_pct) = 12 
ORDER BY 
    avg_annual_change_pct ASC; -- Ordered from the slowest growing (or most decreasing) to the fastest
    
    
-- =============================================================================
-- SECTION 2: Bonus Case Study
-- PURPOSE: Provides a granular chronological look at the raw yearly data 
--          for Granulated Sugar, which achieved both the lowest average and median.
-- =============================================================================
    
-- STEP 1: Extract a clean historical timeline strictly for the absolute winner
WITH unique_food_prices AS (
    SELECT DISTINCT wages_year, food_name, avg_price
    FROM t_anna_pasternakova_project_sql_primary_final
    WHERE food_code = 118101 -- Code for granulated sugar
)
SELECT 
    wages_year,
    food_name,
    ROUND(avg_price::numeric, 2) AS price_czk,
    -- STEP 2: Calculate the absolute difference in CZK compared to the previous year
    ROUND((avg_price - LAG(avg_price) OVER (ORDER BY wages_year))::numeric, 2) AS diff_czk,
    -- STEP 3: Calculate the year-over-year percentage change to analyze the volatility trend
    ROUND(((avg_price - LAG(avg_price) OVER (ORDER BY wages_year)) / LAG(avg_price) 
    	OVER (ORDER BY wages_year) * 100)::numeric, 2) AS yoy_change_pct
FROM unique_food_prices
ORDER BY wages_year;