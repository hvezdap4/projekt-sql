--------------------------------------------------------------------------------
-- PROJECT: Engeto – Project SQL
-- AUTHOR:  Anna Pasternakova
-- PURPOSE: Creation of the secondary table directly on the source server.
--          Filters macroeconomic data for European countries for the comparable period (2006-2018).
--------------------------------------------------------------------------------

-- Table Creation and Population
CREATE TABLE t_anna_pasternakova_project_sql_secondary_final AS
SELECT 
    e.country,
    e.year,
    e.gdp,
    e.gini,
    e.taxes,
    e.population
FROM economies e
JOIN countries c 
    ON e.country = c.country -- Joins datasets via country name matching
WHERE 
    -- BUSINESS LOGIC FILTERS:
    c.continent = 'Europe' -- Restricts data exclusively to European nations as per project requirements
    AND e.year BETWEEN 2006 AND 2018 -- Aligns the timeline with the primary Czech market dataset
ORDER BY 
    e.country, 
    e.year;
