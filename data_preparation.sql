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
    
    COUNT(MONTHS_BALANCE) AS cc_total_months_history,
    COUNT(DISTINCT SK_ID_PREV) AS cc_total_cards,
    
    MAX(AMT_BALANCE) AS cc_max_balance,
    AVG(AMT_BALANCE) AS cc_avg_balance,
    
    ROUND(MAX(AMT_BALANCE / (AMT_CREDIT_LIMIT_ACTUAL + 1.0)), 4) AS cc_max_utilization_ratio,
    ROUND(AVG(AMT_BALANCE / (AMT_CREDIT_LIMIT_ACTUAL + 1.0)), 4) AS cc_avg_utilization_ratio,
    
    SUM(AMT_DRAWINGS_ATM_CURRENT) AS cc_total_atm_drawings,
    SUM(CNT_DRAWINGS_ATM_CURRENT) AS cc_total_atm_drawing_count,
    
    SUM(CASE 
        WHEN AMT_PAYMENT_CURRENT <= AMT_INST_MIN_REGULARITY 
        AND AMT_INST_MIN_REGULARITY > 0 
        THEN 1 ELSE 0 
    END) AS cc_months_min_payment_only,
    
    MAX(SK_DPD) AS cc_max_days_past_due,
    SUM(CASE WHEN SK_DPD > 0 THEN 1 ELSE 0 END) AS cc_months_with_delinquency

FROM credit_card_balance
GROUP BY applicant_id;

## Aggregating previous_application dataset by grouping applicant_id

CREATE TABLE previous_application_aggregated AS
SELECT 
     applicant_id,
    
    COUNT(SK_ID_PREV) AS prev_total_applications,
    SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END) AS prev_approved_count,
    SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Refused' THEN 1 ELSE 0 END) AS prev_refused_count,
    SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Canceled' THEN 1 ELSE 0 END) AS prev_canceled_count,
    
    ROUND(SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Refused' THEN 1.0 ELSE 0.0 END) / COUNT(SK_ID_PREV), 4) AS prev_rejection_ratio,
    
    AVG(AMT_APPLICATION) AS prev_avg_amt_applied,
    AVG(AMT_CREDIT) AS prev_avg_amt_approved,
    AVG(AMT_ANNUITY) AS prev_avg_annuity,
    
    ROUND(AVG(AMT_CREDIT / NULLIF(AMT_APPLICATION, 0)), 4) AS prev_credit_to_application_ratio,
    
    MAX(DAYS_DECISION) AS prev_days_since_last_app,
    MIN(DAYS_DECISION) AS prev_days_since_first_app,
    
    SUM(CASE WHEN NAME_YIELD_GROUP = 'high' THEN 1 ELSE 0 END) AS prev_high_yield_count,
    SUM(CASE WHEN NAME_YIELD_GROUP = 'low_normal' OR NAME_YIELD_GROUP = 'low_action' THEN 1 ELSE 0 END) AS prev_low_yield_count,
    
    ROUND(AVG(NFLAG_INSURED_ON_APPROVAL), 4) AS prev_insurance_uptake_ratio

FROM previous_applications
GROUP BY applicant_id;

## Aggregating installment_payments dataset by grouping applicant_id

CREATE TABLE installments_aggregated AS
SELECT 
	applicant_id,
    
    COUNT(NUM_INSTALMENT_NUMBER) AS total_installments_paid,
    
    SUM(AMT_INSTALMENT) AS total_installment_owed,
    SUM(AMT_PAYMENT) AS total_installment_paid,
    
    ROUND(SUM(AMT_PAYMENT) / (SUM(AMT_INSTALMENT) + 1.0), 4) AS installment_payment_ratio,
    
    SUM(CASE WHEN AMT_PAYMENT < AMT_INSTALMENT THEN 1 ELSE 0 END) AS count_underpayments,
    
    
    SUM(CASE WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT THEN 1 ELSE 0 END) AS count_late_payments,
    MAX(CASE WHEN DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT THEN DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT ELSE 0 END) AS max_days_late,
    
    MAX(CASE WHEN DAYS_INSTALMENT > DAYS_ENTRY_PAYMENT THEN DAYS_INSTALMENT - DAYS_ENTRY_PAYMENT ELSE 0 END) AS max_days_early

FROM installment_payments
GROUP BY applicant_id;

## Left joining the applicant dataset on all aggregated datasets to prepare final dataset for analysis

CREATE TABLE Home_credit_default_risk_final AS
SELECT 
    app.*, 
    
    COALESCE(bur.total_bureau_loans, 0) AS total_bureau_loans,
    COALESCE(bur.active_loan_ratio, 0.0) AS active_loan_ratio,
    COALESCE(bur.current_active_debt, 0) AS current_active_debt,
    COALESCE(bur.total_bureau_monthly_payment, 0) AS total_bureau_monthly_payment,
    COALESCE(bur.total_days_overdue_bureau, 0) AS total_days_overdue_bureau,
    COALESCE(bur.days_since_last_active_loan, -9999) AS days_since_last_active_loan, 
    
    COALESCE(cc.cc_total_cards, 0) AS cc_total_cards,
    COALESCE(cc.cc_max_utilization_ratio, 0.0) AS cc_max_utilization_ratio,
    COALESCE(cc.cc_total_atm_drawings, 0) AS cc_total_atm_drawings,
    COALESCE(cc.cc_months_min_payment_only, 0) AS cc_months_min_payment_only,
    COALESCE(cc.cc_max_days_past_due, 0) AS cc_max_cc_days_past_due,
    
    COALESCE(prev.prev_total_applications, 0) AS prev_total_applications,
    COALESCE(prev.prev_rejection_ratio, 0.0) AS prev_rejection_ratio,
    COALESCE(prev.prev_avg_amt_applied, 0) AS prev_avg_amt_applied,
    COALESCE(prev.prev_credit_to_application_ratio, 0.0) AS prev_credit_to_application_ratio,
    COALESCE(prev.prev_high_yield_count, 0) AS prev_high_yield_count,
    COALESCE(prev.prev_insurance_uptake_ratio, 0.0) AS prev_insurance_uptake_ratio,
    COALESCE(prev.prev_days_since_last_app, -9999) AS prev_days_since_last_app,
    
    COALESCE(inst.total_installments_paid, 0) AS total_installments_paid,
    COALESCE(inst.installment_payment_ratio, 0.0) AS installment_payment_ratio,
    COALESCE(inst.count_underpayments, 0) AS count_underpayments,
    COALESCE(inst.count_late_payments, 0) AS count_late_payments,
    COALESCE(inst.max_days_late, 0) AS max_days_late

FROM application_train app

LEFT JOIN bureau_aggregated bur 
    ON app.applicant_id = bur.applicant_id
    
LEFT JOIN credit_card_aggregated cc 
    ON app.applicant_id = cc.applicant_id
    
LEFT JOIN previous_application_aggregated prev 
    ON app.applicant_id = prev.applicant_id
    
LEFT JOIN installments_aggregated inst 
    ON app.applicant_id = inst.applicant_id;
