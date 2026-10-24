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

