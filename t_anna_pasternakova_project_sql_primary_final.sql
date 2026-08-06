--------------------------------------------------------------------------------
-- PROJECT: Engeto – Project SQL
-- AUTHOR:  Anna Pasternakova
-- PURPOSE: Creation of the primary table directly on the source server.
--          Joins wages and food prices in Czechia for the comparable period (2006-2018).
--------------------------------------------------------------------------------

-- Table Creation and Population
CREATE TABLE t_anna_pasternakova_project_sql_primary_final AS

WITH wages_aggregated AS (
    -- SUBQUERY A: Clean and aggregate payroll data by year and industry branch
    SELECT 
        cp.payroll_year AS wages_year,
        cp.industry_branch_code AS industry_code,
        cpib.name AS industry_name,
        AVG(cp.value) AS avg_wages -- Calculates the annual average from quarterly records
    FROM czechia_payroll cp
    LEFT JOIN czechia_payroll_industry_branch cpib 
        ON cp.industry_branch_code = cpib.code
    WHERE 
        -- CRITICAL METADATA FILTERS:
        cp.value_type_code = 5958     -- 5958 = Average gross wages in CZK (excludes employee counts)
        AND cp.calculation_code = 200  -- 200 = Full-Time Equivalent (excludes raw headcount anomalies)
        AND cp.industry_branch_code IS NOT NULL -- Filters out rows that are not assigned to any specific industry branch
        AND cp.payroll_year BETWEEN 2006 AND 2018 -- Restricts data to the food price intersection period
    GROUP BY 
        cp.payroll_year, 
        cp.industry_branch_code, 
        cpib.name
),

prices_aggregated AS (
    -- SUBQUERY B: Clean and aggregate food prices by year and food category
    SELECT 
        EXTRACT(YEAR FROM cp.date_from) AS price_year, -- Extracts calendar year from timestamp to match wages
        cpc.code AS food_code,
        cpc.name AS food_name,
        cpc.price_value AS package_value,  -- Numerical volume of the packaging (e.g., 1)
        cpc.price_unit AS package_unit,    -- Measurement unit of the packaging (e.g., kg, l)
        AVG(cp.value) AS avg_price -- Averages weekly/regional prices into a national annual value
    FROM czechia_price cp
    LEFT JOIN czechia_price_category cpc 
        ON cp.category_code = cpc.code
    WHERE 
        EXTRACT(YEAR FROM cp.date_from) BETWEEN 2006 AND 2018 -- Restricts data to the wage intersection period
    GROUP BY 
        EXTRACT(YEAR FROM cp.date_from), 
        cpc.code, 
        cpc.name, 
        cpc.price_value, 
        cpc.price_unit
)

-- FINAL STEP: Combine wages and food prices into a comprehensive matrix
SELECT 
    w.wages_year,
    w.industry_code,
    w.industry_name,
    -- Standardizes data types into 4-byte floating point (REAL) to optimize 
    -- local storage efficiency and accelerate future analytical query performance.
    w.avg_wages::real AS avg_wages,
    p.food_code,
    p.food_name,
    p.package_value::real AS package_value,
    p.package_unit,
    p.avg_price::real AS avg_price
FROM wages_aggregated w
JOIN prices_aggregated p 
    ON w.wages_year = p.price_year -- Inner Join automatically isolates the 2006-2018 intersection
ORDER BY 
    w.wages_year, 
    w.industry_code, 
    p.food_code;
