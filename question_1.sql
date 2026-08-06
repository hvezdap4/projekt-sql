--------------------------------------------------------------------------------
-- QUESTION 1: Do wages increase in all industries over the years, 
--             or do they decrease in some?
-- AUTHOR:     Anna Pasternakova
-- PURPOSE:    This script calculates year-over-year changes in average wages 
--             for each industry branch to identify any annual wage drops.
--------------------------------------------------------------------------------

WITH wage_trends AS (
    -- STEP 1: Prepare a clean dataset of unique year-industry wage pairs
    SELECT 
        wages_year,
        industry_code,
        industry_name,
        avg_wages,
        -- Accesses the average wage from the previous year for the same industry branch
        LAG(avg_wages) OVER (
            PARTITION BY industry_code 
            ORDER BY wages_year
        ) AS previous_year_wages
    FROM (
        -- DISTINCT is required to remove duplicate rows caused by the food product matrix
        SELECT DISTINCT 
            wages_year, 
            industry_code, 
            industry_name, 
            avg_wages
        FROM t_anna_pasternakova_project_sql_primary_final
    ) AS unique_wages
)
-- STEP 2: Calculate financial and percentage differences, filtering only the drops
SELECT 
    wages_year,
    industry_code,
    industry_name,
    ROUND(avg_wages::numeric, 2) AS current_wage_czk,
    ROUND(previous_year_wages::numeric, 2) AS previous_wage_czk,
    ROUND((avg_wages - previous_year_wages)::numeric, 2) AS difference_czk,
    ROUND(((avg_wages - previous_year_wages) / previous_year_wages * 100)::numeric, 2) AS change_percentage
FROM wage_trends
WHERE previous_year_wages IS NOT NULL -- Excludes the baseline year (2006)
  AND avg_wages < previous_year_wages -- CRITICAL FILTER: Isolates only the years where wages decreased
ORDER BY change_percentage, industry_code;
