# Data Analytics Project: Wages and Food Prices Relationship in the Czech Republic

SQL Academy Project by Engeto.

## Project Introduction & Purpose

This project compares the development of average national wages and essential food prices in the Czech Republic between 2006 and 2018. The primary objective is to evaluate the real affordability of selected food commodities relative to household incomes across various industry branches. The project is implemented using SQL scripts that filter and aggregate data from raw source tables provided within the Engeto courses.

## Datasets Used

#### Primary Tables:
*   `czechia_payroll` – Information on wages in various industries over a multi-year period. The dataset originates from the Czech Republic Open Data Portal.
*   `czechia_payroll_calculation` – Codelist for calculation types in the wage table.
*   `czechia_payroll_industry_branch` – Codelist for industry branches in the wage table.
*   `czechia_payroll_unit` – Codelist for value units in the wage table.
*   `czechia_payroll_value_type` – Codelist for value types in the wage table.
*   `czechia_price` – Information on the prices of selected food items over a multi-year period. The dataset originates from the Czech Republic Open Data Portal.
*   `czechia_price_category` – Codelist for food categories appearing in our overview.

#### Additional Tables:
*   `countries` – Various global country-level information, such as capitals, currencies, national dishes, or average population heights.
*   `economies` – GDP, GINI index, tax burden, etc., per country and year.

## Final Data Structures

From the source data described above, initialization scripts build two consolidated tables that serve as a robust foundation for all subsequent analyses:

*   **`t_anna_pasternakova_project_sql_primary_final`**
    Contains unified and cleaned data on average wages and food prices for the Czech Republic, aligned to an identical comparable timeframe (overlapping years 2006–2018).
*   **`t_anna_pasternakova_project_sql_secondary_final`**
    Contains supplementary macroeconomic data (GDP, GINI coefficient, and population) for European countries, including the Czech Republic, within the same time horizon, providing a broader economic context.

Separate SQL scripts run on top of these two final structures to independently answer specific research questions focused exclusively on the Czech Republic.

# Executive Summary of Results

## Question 1: Do wages increase in all industries over the years, or do they decrease in some?

#### Analytical Development & Versions (Interim Results)
*   **Version 1 (Basic Overview):** I joined the data using `industry_code` and calculated the average wages and their year-over-year changes for individual sectors. Subsequently, I filtered for cases where a year-over-year decrease in average wages occurred. This initial output answered the question directly and revealed a total of 25 wage drop instances across different years and sectors.
*   **Version 2 (Deeper Dive):** While examining the interim results, I decided to expand the analysis to find out which industry suffered the largest historical drop, where wage drops are most frequent, and which calendar year was the most critical for Czech sectors.
*   **Version 3 (Final Synthesis):** Although the deeper dive provided great analytical value, it did not form a complete answer on its own. In the final version, I combined both approaches. The resulting script generates two separate output data views simultaneously (the full list of drops and a summary table of extremes).

#### Results
*   **Absolute Extreme:** The highest year-over-year drop in average wages was recorded in the *Financial and insurance activities* sector in 2013, when salaries plunged by a staggering **`-8.83 %`**.
*   **Most Frequently Affected Field:** The *Mining and quarrying* sector was hit by economic downturns most often – a total of 4 times out of the 12 tracked years, experiencing its sharpest drop also in 2013.
*   **Critical Year:** The most challenging period for the Czech labor market was unambiguously **2013**, during which the average wage decreased year-over-year in 11 out of the 19 monitored industry sectors.

#### Output Data Notes
Since the year-over-year change calculation relies on the `LAG()` analytical window function, the percentage shift for the baseline year 2006 is logically `NULL`. The database lacks data for 2005, which would otherwise serve as the comparative baseline.

---

## Question 2: How many liters of milk and kilograms of bread can be bought for the first and last comparable periods in the available data?

#### Analytical Development & Versions (Interim Results)
The phrasing of the research question contains a logical ambiguity that can be interpreted in two ways: either as an isolated purchase of a single commodity using the entire salary, or as a combined bundle of both food items purchased simultaneously. Therefore, the analysis was split into two approaches:
*   **Version 1 (Isolated Commodities):** Calculates the maximum quantity of food that can theoretically be bought with the average wage in 2006 and 2018 for each item independently. The resulting volumes are rounded down to whole units, as it is impossible to purchase a partial loaf of bread or liter of milk for a proportional price at retail checkouts.
*   **Version 2 (Combined Shopping Basket):** Responds to the interim results of the first version and introduces a more realistic perspective. It defines a fictional unified unit – a "breakfast basket" containing exactly 1 kg of bread and 1 liter of milk together in a 1:1 ratio, and examines how many of these full bundles a citizen could afford.

#### Results
Despite rising nominal food prices, the average national wage grew at a faster pace, leading to a net increase in the real purchasing power of the population:

*   **Bread (1 kg):**
    *   Year 2006: **`1,312 kg`**
    *   Year 2018: **`1,365 kg`** *(an increase of 53 kg)*
*   **Semi-skimmed Milk (1 l):**
    *   Year 2006: **`1,465 liters`**
    *   Year 2018: **`1,669 liters`** *(an increase of 204 liters)*
*   **Combined Breakfast Basket (1 kg of bread + 1 l of milk):**
    *   Year 2006: **`692 pcs`**
    *   Year 2018: **`751 pcs`** *(an increase of 59 full baskets)*

---

## Question 3: Which food category increases in price the slowest (has the lowest percentage year-over-year increase)?

#### Analytical Development & Versions (Interim Results)
*   **Version 1 (Basic Average):** I calculated the average of year-over-year price changes for each food category independently and sorted them in ascending order. Using the `STDDEV()` statistical function, I added the standard deviation (volatility) to outline how stable this development was over time. While granulated sugar emerged as the absolute winner, white wine appeared at the top of the stability rankings.
*   **Version 2 (Detailed Timeline):** To inspect these interim results further, I created a second auxiliary output panel that laid out the historical price development of sugar and wine row by row. This step revealed a significant data anomaly (*data bias*): white wine only had 4 records in the database (years 2015–2018), which artificially suppressed its standard deviation, whereas other foods had full timelines.
*   **Version 3 (Data Cleaning & Median):** In the final version, I modified the script to compare only those food items that have a complete time series (enforced by the `HAVING COUNT(yoy_change_pct) = 12` condition). I also complemented the analysis with the median of year-over-year changes, which is immune to extreme anomalies and thus better captures the typical long-term trend of a product's price development without being skewed by shocks.

#### Results
*   **Absolute Winner:** **Granulated Sugar (Cukr krystalový)** exhibits the slowest year-over-year price growth. Its long-term trend is actually deflationary, with its price declining by an average of **`-1.92 %`** annually (featuring an even deeper median of **`-2.47 %`**). However, a standard deviation of **`12.55 %`** revealed that its historical path was full of wild price swings and market shocks.

#### Output Data Notes
The output dataset in the primary section was strictly restricted by a condition requiring at least 12 year-over-year comparisons. This filter successfully excluded only *Quality White Wine (Jakostní víno bílé)*, for which data collection started late in 2015. All other commodities possess a fully intact 13-year dataset.

---

## Question 4: Is there a year where the year-over-year increase in food prices was significantly higher than wage growth (greater than a 10 % difference)?

#### Analytical Development & Versions (Interim Results)
*   **Version 1 (Global Comparison):** The objective of this version was to create a unified overview that directly compares aggregated national year-over-year food price changes against average wage changes for the entire Czech Republic. The script mathematically subtracts these values for each calendar year and, using an automated flag (`CASE WHEN`), verifies whether a critical moment occurred historically where food prices outpaced wages by more than 10 percentage points.
*   **Sorting Optimization:** To maximize clarity and ensure the immediate detection of extremes, I chose not to sort the resulting overview chronologically. Instead, it is sorted in descending order based on the magnitude of financial pressure on citizens, using the **`difference_pct DESC`** column. This places the historically most challenging years on the very first rows.

#### Results
The analysis demonstrated that **there is no year** in which the year-over-year increase in food prices outpaced wage growth by more than 10 %. From a long-term macroeconomic perspective, the purchasing power of the population remained protected because wage dynamics were strong enough to absorb the pace of food inflation. Over the tracked period, the data split **exactly half and half** – food prices grew faster in 6 of the years, while wages grew faster in the other 6. However, two contrasting historical extremes stand out clearly in the data:

*   **The Most Challenging Year, 2013 (A difference of `+6.79 %` in favor of food):** This year came closest to the monitored 10 % threshold. Average wages decreased in real terms for the first time in history (**`-0.78 %`**), while food prices surged sharply by **`+6.01 %`**. For citizens' wallets, this was demonstrably the worst year.
*   **The Most Favorable Year, 2009 (A difference of `-9.42 %` in favor of wages):** The exact polar opposite of 2013. Food prices in stores to plunge across the board at **`-6.58 %`**. Wages, however, maintained a modest inertia-driven growth of **`+2.84 %`**. In this year, people had more financial resources on average, and food was significantly cheaper than the typical trend.

#### Output Data Notes
The output dataset covers the complete time series and exhibits no missing values for the tracked years (with the exception of the baseline year 2006, where a year-over-year change logically cannot be calculated). All computations are standardized to compare the aggregated average of 27 complete food categories against 19 industry branches.

---

## Question 5: Does the level of GDP affect changes in wages and food prices? In other words, if GDP increases more significantly in one year, does it translate into a more significant growth in food prices or wages in the same or the following year?

#### Analytical Development & Versions (Interim Results)
*   **Version 1 (Chronological Matrix):** I created a foundational macroeconomic overview that juxtaposed the year-over-year percentage changes of the Czech Republic's GDP (converted to millions of CZK for better readability) against average wage changes and food price changes. While it was possible to discern at first glance that salaries experienced a massive leap in 2016, 2017, and 2018 following the successful economic expansion of 2015, descriptive numbers alone could not determine whether this was a structural rule or a historical coincidence.
*   **Version 2 (Directional Identifiers):** To visually streamline the data, I replaced the complex numerical comparisons with punchy directional indicators: **`UP`** and **`DOWN`**. Using the `LEAD()` analytical window function, I had the database perform automated pairing: it took the current year's GDP direction and compared it directly with the direction of wages and food in the subsequent year. This generated clear textual verdicts (such as `GDP UP = NY UP`) that exposed market inertia.
*   **Version 3 (Statistical Evaluation via Pearson Correlation):** Although the visual trend flags helped, I realized that a permanent economic law cannot be derived from just two historical growth spurts (the years 2007 and 2015). In the final version, I implemented the built-in statistical function **`CORR()`** into the script. This independently generated a second, standalone output panel that exactly computed the strength and direction of the linear trend (Pearson's $r$) for both time horizons: the current year ($t$ ) and the next year ($t+1$).

#### Results
The statistical analysis delivered a pivotal macroeconomic conclusion regarding the behavior of the Czech market:

| comparison_type | wage_correlation_r | food_correlation_r | economic_interpretation |
| :--- | :---: | :---: | :--- |
| **Same Year (t)** | 0.50 | 0.43 | **Moderate positive correlation** for both variables. The market responds to GDP growth gently and immediately within the same calendar year. |
| **Next Year (t+1)** | 0.67 | 0.05 | **Strong correlation for wages** (a significant delayed effect) vs. a **completely zero relationship for food prices**. |

*   **Impact on Wages (Strong Time Lag):** There is a demonstrable delayed inertia between GDP growth and salary developments. While the relationship is moderate ($0.50$) within the same year, the strength of the linear trend shoots up to **`0.67`** in the following year. This proves that corporate profits generated during an economic boom (such as the prosperous year 2015) translate into systemic, widespread wage increases for employees with a one-year delay (manifesting in 2016 and 2017).
*   **Impact on Food Prices (Absolute Independence):** Food prices respond moderately only within the current year ($0.43$). In the following year, however, the linear relationship with past GDP completely collapses to a pure zero (**`0.05`**). Food price movements with a one-year delay are entirely detached from how much national wealth expanded the year before.

#### Output Data Notes and Statistical Limits
*   **Cleaning the Baseline:** For the baseline year **2006**, all textual direction indicators and comparisons were deliberately wrapped in an `IS NOT NULL` condition and cleared to an empty `NULL` value. This prevented an anomaly where the `LEAD()` function would nonsensically drag future trends into a baseline row that lacks an initial percentage change.
*   **Ending the Series:** The columns tracking the subsequent year (`next_year_...`) display a `NULL` value for the final monitored year 2018, because the database logically has no data for 2019 from which to read a future direction.
*   **Warning on Statistical Significance:** Although the correlation coefficients reveal moderate or strong trends, **the code only measures historical alignment of data lines, not statistical significance**. Due to the very short time series (only 12 year-over-year comparisons), these results cannot be used to declare a permanent, mathematically definitive macroeconomic law.
