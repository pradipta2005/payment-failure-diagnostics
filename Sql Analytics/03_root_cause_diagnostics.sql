/* ----------------------------------------------------------------------------
   3. FAILURE DROP-OFF & ROOT-CAUSE DIAGNOSTICS
   Business Logic:
   - Isolates failed transactions to rank top failure reasons within each 
     service vertical.
   - Calculates each failure reason's percentage share of vertical drop-offs 
     to separate technical declines (timeouts) from user declines (low balance).
   ---------------------------------------------------------------------------- */
WITH failure_summary AS (
    SELECT 
        Service,
        Reason AS Failure_Reason,
        COUNT(*) AS Failure_Count,
        ROUND(SUM(Amount), 2) AS Failed_Volume
    FROM phonepay_project_db.vw_clean_transactions
    WHERE Payment_Status <> 'Successful' -- Filter strictly for non-successful attempts
    GROUP BY Service, Reason
)
SELECT 
    Service,
    Failure_Reason,
    Failure_Count,
    Failed_Volume,
    
    -- Calculate relative contribution of each failure reason within its vertical
    ROUND(
        100.0 * Failure_Count / SUM(Failure_Count) OVER (PARTITION BY Service), 
        2
    ) AS Share_Of_Service_Failures_Pct,
    
    -- Rank failure bottlenecks from highest to lowest frequency per service
    DENSE_RANK() OVER (
        PARTITION BY Service 
        ORDER BY Failure_Count DESC
    ) AS Failure_Rank
FROM failure_summary
ORDER BY Service ASC, Failure_Rank ASC;