
/* ----------------------------------------------------------------------------
   1. DATA CLEANING & DEDUPLICATION LAYER
   Business Logic: 
   - Removes exact duplicate transaction records caused by ingestion retries.
   - Standardizes mixed date formats ('M/D/YYYY' strings vs. 'YYYY-MM-DD') 
     into a uniform DATE type for accurate time-series and cohort modeling.
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW phonepay_project_db.vw_clean_transactions AS
WITH deduped_transactions AS (
    SELECT 
        Transaction_ID,
        User_ID,
        Service,
        `Service Type` AS Service_Type,
        Amount,
        Payment_Status,
        Reason,
        -- Normalize string dates (e.g., '1/21/2024') into standard SQL DATE format
        CASE 
            WHEN Date LIKE '%/%' THEN STR_TO_DATE(Date, '%c/%e/%Y')
            ELSE CAST(Date AS DATE)
        END AS Txn_Date,
        -- Assign row numbers to isolate and remove duplicate Transaction_IDs
        ROW_NUMBER() OVER (
            PARTITION BY Transaction_ID 
            ORDER BY Date ASC
        ) AS row_num
    FROM phonepay_project_db.all_transactions
)
SELECT 
    Transaction_ID,
    User_ID,
    Service,
    Service_Type,
    Amount,
    Payment_Status,
    Reason,
    Txn_Date
FROM deduped_transactions
WHERE row_num = 1; -- Retain only the primary record per transaction