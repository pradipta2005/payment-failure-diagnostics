
/* ----------------------------------------------------------------------------
   2. PAYMENT SUCCESS RATE (SR) & RECOVERABLE GMV ANALYSIS
   Business Logic:
   - Evaluates transaction volume and Gross Merchandise Value (GMV) across 
     verticals (Recharge_Bills, Loans, Insurance).
   - Quantifies "Lost GMV" from failed attempts to highlight top revenue 
     recovery opportunities for product and engineering teams.
   ---------------------------------------------------------------------------- */
SELECT 
    Service,
    Service_Type,
    COUNT(*) AS Total_Attempts,
    
    -- Volume breakdown by transaction outcome
    SUM(CASE WHEN Payment_Status = 'Successful' THEN 1 ELSE 0 END) AS Successful_Txns,
    SUM(CASE WHEN Payment_Status <> 'Successful' THEN 1 ELSE 0 END) AS Failed_Txns,
    
    -- Core KPI: Transaction Count Success Rate (%)
    ROUND(
        100.0 * SUM(CASE WHEN Payment_Status = 'Successful' THEN 1 ELSE 0 END) / COUNT(*), 
        2
    ) AS Count_Success_Rate_Pct,
    
    -- Financial impact: Processed GMV vs. Drop-off GMV
    ROUND(SUM(CASE WHEN Payment_Status = 'Successful' THEN Amount ELSE 0 END), 2) AS Successful_GMV,
    ROUND(SUM(CASE WHEN Payment_Status <> 'Successful' THEN Amount ELSE 0 END), 2) AS Lost_GMV
FROM phonepay_project_db.vw_clean_transactions
GROUP BY Service, Service_Type
ORDER BY Lost_GMV DESC; -- Prioritize categories with highest uncaptured GMV