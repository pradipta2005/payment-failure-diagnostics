/* ----------------------------------------------------------------------------
   4A. MONTHLY USER COHORT RETENTION MATRIX
   Business Logic:
   - Groups users by their acquisition month (Join_Date) and tracks repeat 
     successful transactions across subsequent months (Month_Index 0, 1, 2...).
   - Measures long-term platform stickiness post-onboarding.
   ---------------------------------------------------------------------------- */
WITH user_cohorts AS (
    SELECT 
        u.User_ID,
        -- Normalize acquisition and transaction dates to the 1st of the month
        DATE_FORMAT(u.Join_Date, '%Y-%m-01') AS Cohort_Month,
        DATE_FORMAT(t.Txn_Date, '%Y-%m-01') AS Activity_Month,
        -- Calculate elapsed months since user acquisition
        TIMESTAMPDIFF(
            MONTH, 
            DATE_FORMAT(u.Join_Date, '%Y-%m-01'), 
            DATE_FORMAT(t.Txn_Date, '%Y-%m-01')
        ) AS Month_Index
    FROM phonepay_project_db.all_users u
    INNER JOIN phonepay_project_db.vw_clean_transactions t 
        ON u.User_ID = t.User_ID
    WHERE t.Payment_Status = 'Successful' -- Count only completed transactions as active retention
),
cohort_sizes AS (
    -- Establish baseline active user count at Month 0 for each acquisition cohort
    SELECT 
        Cohort_Month, 
        COUNT(DISTINCT User_ID) AS Cohort_Users
    FROM user_cohorts
    WHERE Month_Index = 0
    GROUP BY Cohort_Month
)
SELECT 
    c.Cohort_Month,
    s.Cohort_Users,
    c.Month_Index,
    COUNT(DISTINCT c.User_ID) AS Retained_Users,
    
    -- Core KPI: Percentage of Month 0 cohort active in Month N
    ROUND(100.0 * COUNT(DISTINCT c.User_ID) / s.Cohort_Users, 2) AS Retention_Rate_Pct
FROM user_cohorts c
INNER JOIN cohort_sizes s 
    ON c.Cohort_Month = s.Cohort_Month
WHERE c.Month_Index >= 0 -- Exclude anomalous transactions dated prior to Join_Date
GROUP BY c.Cohort_Month, s.Cohort_Users, c.Month_Index
ORDER BY c.Cohort_Month ASC, c.Month_Index ASC;
