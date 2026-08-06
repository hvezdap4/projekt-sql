--------------------------------------------------------------------------------
-- QUESTION 3: Which food category increases in price the slowest 
--             (has the lowest percentage year-over-year increase)?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script analyzes food inflation through two sections:
--             1) Main Presentation: A complete market overview calculating 
--                average annual shifts and volatility (standard deviation).
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


-- =============================================================================
-- SECTION 2: Bonus Case Study (Deep Dive into Extremes)
-- PURPOSE: Provides a granular chronological look at the raw yearly data 
--          for Granulated Sugar (lowest average) and White Wine (highest stability).
-- =============================================================================

WITH baseline_prices AS (
    -- STEP 1: Extract distinct historical timelines for the two targeted products
    SELECT DISTINCT 
        wages_year, 
        food_code, 
        food_name, 
        avg_price
    FROM t_anna_pasternakova_project_sql_primary_final
    WHERE food_code IN (118101, 212101) -- 118101: Granulated Sugar | 212101: Quality White Wine
),

calculated_timeline AS (
    -- STEP 2: Formulate year-over-year differences and percentage shifts
    SELECT 
        wages_year,
        food_code,
        food_name,
        ROUND(avg_price::numeric, 2)::numeric(10,2) AS price_czk,
        ROUND((avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year))::numeric, 2)::numeric(10,2) AS quantity_difference,
        ROUND(
            (
                (avg_price - LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)) 
                / 
                LAG(avg_price) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric * 100
            )::numeric, 2
        )::numeric(10,2) AS quantity_difference_pct
    FROM baseline_prices
)
-- STEP 3: Final Case Study presentation sorted by product and time
SELECT 
    wages_year,
    food_name,
    price_czk,
    quantity_difference,
    quantity_difference_pct
FROM calculated_timeline
ORDER BY 
    food_code ASC, 
    wages_year ASC;

