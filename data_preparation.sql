## Creating and using database
CREATE DATABASE home_credit_default_risk
USE home_credit_default_risk

## Aggregating the bureau dataset by grouping applicant_id's
    
CREATE TABLE bureau_aggregated AS
SELECT 
    applicant_id,
    COUNT(CREDIT_ACTIVE) AS total_bureau_loans,
    SUM(CASE WHEN CREDIT_ACTIVE = 'Active' THEN 1 ELSE 0 END) AS active_loans_count,
    SUM(CASE WHEN CREDIT_ACTIVE = 'Closed' THEN 1 ELSE 0 END) AS closed_loans_count,
    SUM(CASE WHEN CREDIT_ACTIVE = 'Active' THEN 1.0 ELSE 0.0 END) / COUNT(CREDIT_ACTIVE) AS active_loan_ratio,
    SUM(CASE WHEN CREDIT_ACTIVE = 'Active' THEN AMT_CREDIT_SUM_DEBT ELSE 0 END) AS current_active_debt,
    SUM(CASE WHEN CREDIT_ACTIVE = 'Closed' THEN AMT_CREDIT_SUM ELSE 0 END) AS total_amount_paid_off,
    AVG(AMT_CREDIT_SUM) AS avg_loan_amount,
    MAX(CASE WHEN CREDIT_ACTIVE = 'Active' THEN DAYS_CREDIT ELSE NULL END) AS days_since_last_active_loan,
    MAX(CASE WHEN CREDIT_ACTIVE = 'Closed' THEN DAYS_ENDDATE_FACT ELSE NULL END) AS days_since_last_payoff,
    SUM(CREDIT_DAY_OVERDUE) AS total_days_overdue_bureau,
    MAX(AMT_CREDIT_MAX_OVERDUE) AS max_overdue_amount,
    SUM(CNT_CREDIT_PROLONG) AS total_loan_prolongations,
    SUM(AMT_CREDIT_SUM_OVERDUE) AS current_amount_overdue,
    SUM(AMT_ANNUITY) AS total_bureau_monthly_payment,
    SUM(CASE WHEN CREDIT_TYPE = 'Credit card' THEN 1 ELSE 0 END) AS bureau_credit_card_count,
    SUM(CASE WHEN CREDIT_TYPE = 'Mortgage' THEN 1 ELSE 0 END) AS bureau_mortgage_count
FROM bureau
GROUP BY applicant_id;

## Aggregating the credit_card_balance dataset by grouping applicant id's

CREATE TABLE credit_card_aggregated AS
SELECT 
    applicant_id,
    
    -- 1. History & Volume
    COUNT(MONTHS_BALANCE) AS cc_total_months_history,
    COUNT(DISTINCT SK_ID_PREV) AS cc_total_cards,
    
    -- 2. Balance & Credit Utilization
    MAX(AMT_BALANCE) AS cc_max_balance,
    AVG(AMT_BALANCE) AS cc_avg_balance,
    
    -- Ratios safely rounded to 4 decimal places
    ROUND(MAX(AMT_BALANCE / (AMT_CREDIT_LIMIT_ACTUAL + 1.0)), 4) AS cc_max_utilization_ratio,
    ROUND(AVG(AMT_BALANCE / (AMT_CREDIT_LIMIT_ACTUAL + 1.0)), 4) AS cc_avg_utilization_ratio,
    
    -- 3. Cash Desperation (ATM Withdrawals)
    SUM(AMT_DRAWINGS_ATM_CURRENT) AS cc_total_atm_drawings,
    SUM(CNT_DRAWINGS_ATM_CURRENT) AS cc_total_atm_drawing_count,
    
    -- 4. Minimum Payment Stress
    SUM(CASE 
        WHEN AMT_PAYMENT_CURRENT <= AMT_INST_MIN_REGULARITY 
        AND AMT_INST_MIN_REGULARITY > 0 
        THEN 1 ELSE 0 
    END) AS cc_months_min_payment_only,
    
    -- 5. Delinquency (Days Past Due)
    MAX(SK_DPD) AS cc_max_days_past_due,
    SUM(CASE WHEN SK_DPD > 0 THEN 1 ELSE 0 END) AS cc_months_with_delinquency

FROM credit_card_balance
GROUP BY applicant_id;
