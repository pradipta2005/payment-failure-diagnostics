/* ----------------------------------------------------------------------------
   5. CROSS-SELL FUNNEL: UTILITY PAYERS TO FINANCIAL SERVICES
   Business Logic:
   - Tracks PhonePe's core monetization funnel: acquiring users via high-frequency
     utility payments (Recharge_Bills) and cross-selling high-margin financial 
     products (Loans, Insurance).
   - Computes overall conversion rate and average time-to-convert (in days).
   ---------------------------------------------------------------------------- */
WITH user_first_touch AS (
    SELECT 
        User_ID,
        -- Capture earliest successful transaction date per product tier
        MIN(CASE WHEN Service = 'Recharge_Bills' THEN Txn_Date END) AS First_Bill_Date,
        MIN(CASE WHEN Service IN ('Loans', 'Insurance') THEN Txn_Date END) AS First_FinServ_Date
    FROM phonepay_project_db.vw_clean_transactions
    WHERE Payment_Status = 'Successful'
    GROUP BY User_ID
)
SELECT 
    -- Top of funnel: Users acquired through utility/bill payments
    COUNT(CASE WHEN First_Bill_Date IS NOT NULL THEN 1 END) AS Total_Bill_Payers,
    
    -- Bottom of funnel: Utility users who subsequently adopted Loans or Insurance
    COUNT(CASE WHEN First_FinServ_Date > First_Bill_Date THEN 1 END) AS Cross_Sold_Users,
    
    -- Core KPI: Utility-to-FinServ Conversion Rate (%)
    ROUND(
        100.0 * COUNT(CASE WHEN First_FinServ_Date > First_Bill_Date THEN 1 END) / 
        NULLIF(COUNT(CASE WHEN First_Bill_Date IS NOT NULL THEN 1 END), 0), 
        2
    ) AS Cross_Sell_Conversion_Pct,
    
-- Velocity metric: Average days taken to cross-sell after first bill payment
	ROUND(
	AVG(CASE
	WHEN First_FinServ_Date > First_Bill_Date
	THEN DATEDIFF(First_FinServ_Date, First_Bill_Date)
	END),1) AS Avg_Days_To_Cross_Sell
FROM user_first_touch;

