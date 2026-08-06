--------------------------------------------------------------------------------
-- QUESTION 1: Do wages increase in all industries over the years, 
--             or do they decrease in some?
-- AUTHOR:     Anna Pasternaková
-- PURPOSE:    This script calculates year-over-year changes in average wages 
--             and aggregates the drops to find the most affected industries and years.
--------------------------------------------------------------------------------

WITH wage_drops AS (
    -- STEP 1: Calculate year-over-year changes and filter ONLY the actual drops
    SELECT 
        wages_year AS current_year,
        industry_name,
        avg_wages - previous_year_wages AS diff_czk,
        ((avg_wages - previous_year_wages) / previous_year_wages * 100) AS diff_percentage
    FROM 
    (
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
	    FROM 
        (
        	-- DISTINCT is required to remove duplicate rows caused by the food product matrix
	        SELECT DISTINCT 
	            wages_year, 
	            industry_code, 
	            industry_name, 
	            avg_wages
	        FROM t_anna_pasternakova_project_sql_primary_final
	    ) AS unique_wages
    ) AS trends
    WHERE previous_year_wages IS NOT NULL 
      AND avg_wages < previous_year_wages -- Filters out positive trends, capturing only economic drops
),

industry_summary AS (
    -- STEP 2: Identify the industry with the highest frequency of wage drops
    SELECT 
        industry_name,
        COUNT(*) AS total_drops_count
    FROM wage_drops
    GROUP BY industry_name
),

most_affected_industry_details AS (
    -- STEP 2B: Get the precise year and stats for the sharpest drop of that specific most affected industry
    SELECT 
        wd.industry_name,
        wd.current_year,
        wd.diff_percentage,
        wd.diff_czk
    FROM wage_drops wd
    WHERE wd.industry_name = (
    	SELECT industry_name 
    	FROM industry_summary 
    	WHERE total_drops_count = (
    		SELECT MAX(total_drops_count) 
    		FROM industry_summary
        )
    )
    ORDER BY wd.diff_percentage ASC
    LIMIT 1 
),

year_summary AS (
    -- STEP 3: Aggregate by year to find when the highest number of industries faced a wage decrease.
    SELECT 
        current_year,
        COUNT(*) AS affected_industries_count
    FROM wage_drops
    GROUP BY current_year
),

final_union AS (
    -- STEP 4: Consolidate different perspectives into a unified matrix.
    
    -- Row 1: Determine the industry with the absolute largest historical year-over-year wage decrease.
    SELECT 
        1 AS sorting_order, 
        'Absolute Sharpest Percentage Drop' AS metric_type,
        industry_name AS details,
        current_year AS drop_year, 
        1 AS occurrences_count,
        diff_percentage AS change_percentage,
        diff_czk AS drop_czk
    FROM wage_drops
    WHERE diff_percentage = (SELECT MIN(diff_percentage) FROM wage_drops)

    UNION ALL

    -- Row 2: Determine which industry sector faced the most frequent wage decreases.
    SELECT 
        2 AS sorting_order, 
        'Most Affected Industry' AS metric_type,
        industry_name AS details,
        current_year AS drop_year, 
        (SELECT MAX(total_drops_count) FROM industry_summary) AS occurrences_count,
        diff_percentage AS change_percentage,
        diff_czk AS drop_czk
    FROM most_affected_industry_details

    UNION ALL

    -- Row 3: Identify which year experienced the highest number of year-over-year wage drops 
    -- and exactly how many industries were affected.
    SELECT 
        3 AS sorting_order, 
        'Year with Most Industry Drops' AS metric_type,
        NULL AS details, 
        current_year AS drop_year, 
        affected_industries_count AS occurrences_count,
        NULL AS change_percentage,
        NULL AS drop_czk
    FROM year_summary
    WHERE affected_industries_count = (SELECT MAX(affected_industries_count) FROM year_summary)
)

-- STEP 5: Final Presentation ordered chronologically by the custom sorting layer.
SELECT 
    metric_type,
    details,
    drop_year,
    occurrences_count,
    change_percentage::numeric(10,2) AS change_percentage,
    drop_czk AS drop_czk
FROM final_union
;
