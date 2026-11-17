/* ----------------------------------------------------------------------------
   4B. SERVICE CATEGORY STICKINESS & CHURN RISK IDENTIFICATION
   Business Logic:
   - Evaluates repeat usage across recurring biller categories (e.g., DTH, 
     Electricity, FASTag) to identify high-retention hooks.
   - Flags users inactive for >60 days (relative to dataset max date) as 
     churn-risk targets for re-engagement campaigns.
   ---------------------------------------------------------------------------- */
WITH dataset_boundary AS (
    -- Anchor recency calculations to the latest transaction date in the database
    SELECT MAX(Txn_Date) AS Latest_Date 
    FROM phonepay_project_db.vw_clean_transactions
),
user_service_stats AS (
    SELECT 
        Service_Type,
        User_ID,
        COUNT(*) AS Successful_Payments,
        MIN(Txn_Date) AS First_Payment_Date,
        MAX(Txn_Date) AS Last_Payment_Date,
        DATEDIFF((SELECT Latest_Date FROM dataset_boundary), MAX(Txn_Date)) AS Days_Since_Last_Txn
    FROM phonepay_project_db.vw_clean_transactions
    WHERE Payment_Status = 'Successful'
    GROUP BY Service_Type, User_ID
)
SELECT 
    Service_Type,
    COUNT(DISTINCT User_ID) AS Total_Active_Users,
    
    -- Users with 2+ successful payments in the same category
    SUM(CASE WHEN Successful_Payments > 1 THEN 1 ELSE 0 END) AS Repeat_Users,
    ROUND(
        100.0 * SUM(CASE WHEN Successful_Payments > 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT User_ID), 
        2
    ) AS Repeat_Retention_Pct,
    
    -- Dormancy flag: Users exceeding the 60-day inactivity threshold
    SUM(CASE WHEN Days_Since_Last_Txn > 60 THEN 1 ELSE 0 END) AS At_Risk_Churned_Users
FROM user_service_stats
GROUP BY Service_Type
ORDER BY Repeat_Retention_Pct DESC;