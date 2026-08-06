--------------------------------------------------------------------------------
-- QUESTION 2: How many liters of milk and kilograms of bread can be bought 
--             for the first and last comparable periods in the available data?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script analyzes purchasing power through two approaches:
--             1) Compares how much of each food product can be bought for the average wage 
--                and calculates their change between 2006 and 2018.
--             2) Compares how many combined shopping baskets (1kg bread + 1l milk) can be bought
--                together for the average wage and calculates its change between 2006 and 2018.
--------------------------------------------------------------------------------

-- =============================================================================
-- APPROACH 1: Individual Commodities with Purchasing Power Shifts
-- =============================================================================

WITH affordable_totals AS (
    -- STEP 1: Calculate national averages and affordable quantities per year
    SELECT 
        wages_year,
        food_code,
        food_name,
        ROUND(avg_price::numeric, 2) AS avg_price_czk,
        package_value,
        package_unit,
        ROUND(AVG(avg_wages)::numeric, 2) AS avg_wage_czk,
        -- The resulting affordable quantity is rounded down because you cannot buy less than a whole unit
        FLOOR(AVG(avg_wages) / avg_price) AS affordable_quantity
    FROM t_anna_pasternakova_project_sql_primary_final
    WHERE wages_year IN (2006, 2018) 
      AND food_code IN (111301, 114201)
    GROUP BY 
        wages_year, 
        food_code, 
        food_name, 
        package_value, 
        package_unit, 
        avg_price
)
-- STEP 2: Use LAG to calculate net and percentage differences in purchasing power
SELECT 
    wages_year,
    food_code,
    food_name,
    avg_price_czk::numeric(10,2) AS avg_price_czk,
    package_value,
    package_unit,
    avg_wage_czk::numeric(10,2) AS avg_wage_czk,
    affordable_quantity,
    -- Net difference: 2018 quantity minus 2006 quantity
    affordable_quantity - LAG(affordable_quantity) OVER (
        PARTITION BY food_code 
        ORDER BY wages_year
    ) AS quantity_difference,
    -- Percentage difference: relative shift from the 2006 baseline
    ROUND(
        (
            ((affordable_quantity - LAG(affordable_quantity) OVER (PARTITION BY food_code ORDER BY wages_year)) 
            / 
            LAG(affordable_quantity) OVER (PARTITION BY food_code ORDER BY wages_year)::numeric) * 100
        )::numeric, 2
    )::numeric(10,2) AS quantity_difference_pct
FROM affordable_totals
ORDER BY 
    food_code ASC, 
    wages_year ASC;


-- =============================================================================
-- APPROACH 2: Combined Shopping Basket (1kg Bread + 1l Milk Together)
-- =============================================================================

WITH basket_prices AS (
    -- STEP 1: Collect unique annual average prices for both required commodities
    SELECT DISTINCT 
        wages_year, 
        food_code, 
        avg_price
    FROM t_anna_pasternakova_project_sql_primary_final
    WHERE wages_year IN (2006, 2018) 
      AND food_code IN (111301, 114201)
),

basket_sums AS (
    -- STEP 2: Sum the prices together to find the total average price of a combined basket per year
    SELECT 
        wages_year, 
        SUM(avg_price)::numeric AS combined_basket_price_czk
    FROM basket_prices
    GROUP BY wages_year
),

national_wages AS (
    -- STEP 3: Compute the national average wage for the same periods
    SELECT 
        wages_year, 
        AVG(avg_wages)::numeric AS national_avg_wage_czk
    FROM t_anna_pasternakova_project_sql_primary_final
    WHERE wages_year IN (2006, 2018)
    GROUP BY wages_year
),

basket_calculations AS (
    -- STEP 4: Calculate affordable baskets for each year and pull the 2006 value next to 2018 for comparison
    SELECT 
        w.wages_year,
        w.national_avg_wage_czk,
        b.combined_basket_price_czk,
        FLOOR(w.national_avg_wage_czk / b.combined_basket_price_czk) AS current_baskets,
        LAG(FLOOR(w.national_avg_wage_czk / b.combined_basket_price_czk)) 
        	OVER (ORDER BY w.wages_year) AS previous_baskets
    FROM national_wages w
    JOIN basket_sums b 
        ON w.wages_year = b.wages_year
)
-- STEP 5: Final output with absolute and percentage differences
SELECT 
    wages_year,
    ROUND(national_avg_wage_czk, 2)::numeric(10,2) AS avg_wage_czk, 
    ROUND(combined_basket_price_czk, 2)::numeric(10,2) AS basket_price_czk, 
    current_baskets AS affordable_baskets, 
    (current_baskets - previous_baskets) AS baskets_difference, 
    -- Percentage difference: relative shift from the 2006 baseline
    ROUND(
        (
            ((current_baskets - previous_baskets) / previous_baskets::numeric) * 100
        )::numeric, 2
    )::numeric(10,2) AS baskets_difference_pct
FROM basket_calculations
ORDER BY 
    wages_year ASC;