--------------------------------------------------------------------------------
-- QUESTION 2: How many liters of milk and kilograms of bread can be bought 
--             for the first and last comparable periods in the available data?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script calculates the purchasing power of the national average wage
--             specifically for bread and milk in the years 2006 and 2018.
--------------------------------------------------------------------------------

WITH affordable_totals AS (
	SELECT 
	    wages_year,
	    food_code,
	    food_name,
	    -- No AVG needed here since the price is already calculated in our primary table
	    ROUND(avg_price::numeric, 2) AS avg_price_czk,
	    package_value,
	    package_unit,
	    -- We only need to average the wages across the 19 industry branches
	    ROUND(AVG(avg_wages)::numeric, 2) AS avg_wage_czk,
	    -- The resulting affordable quantity is rounded down because you cannot buy less than a whole unit
	    FLOOR(AVG(avg_wages) / avg_price) AS affordable_quantity
	FROM t_anna_pasternakova_project_sql_primary_final
	WHERE 
	    wages_year IN (2006, 2018) 
	    AND food_code IN (111301, 114201)
	GROUP BY 
	    wages_year, 
	    food_code,
	    food_name, 
	    package_value, 
	    package_unit,
	    avg_price
	ORDER BY 
	    food_code ASC, 
	    wages_year ASC
)
-- STEP 2: Use LAG to calculate the net difference in purchasing power between 2006 and 2018
SELECT 
    wages_year,
    food_code,
    food_name,
    avg_price_czk,
    package_value,
    package_unit,
    avg_wage_czk,
    affordable_quantity,
    -- Calculates the difference: 2018 Quantity minus 2006 Quantity
    affordable_quantity - LAG(affordable_quantity) OVER (
        PARTITION BY food_code 
        ORDER BY wages_year
    ) AS quantity_difference
FROM affordable_totals
ORDER BY 
    food_code ASC, 
    wages_year ASC;
