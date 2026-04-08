-- ============================================================
-- CREDIT RISK & MARKET RISK ANALYSIS — SQL QUERIES
-- Author: Jeevan Lal Mourya | Risk Analyst Portfolio Project
-- Dataset: 5,000 synthetic loan records
-- Metrics: PD, LGD, EL, VaR (95% & 99%)
-- ============================================================

-- ── 1. PORTFOLIO-LEVEL RISK KPIs ─────────────────────────────
SELECT
    COUNT(*)                                                           AS total_loans,
    ROUND(SUM(defaulted) * 100.0 / COUNT(*), 2)                       AS default_rate_pct,
    ROUND(AVG(credit_score), 0)                                        AS avg_credit_score,
    ROUND(AVG(debt_to_income_ratio), 3)                                AS avg_debt_to_income,
    ROUND(SUM(loan_amount) / 1000000, 2)                               AS portfolio_size_millions,
    ROUND(SUM(expected_loss) / 1000000, 2)                             AS total_expected_loss_millions,
    ROUND(SUM(expected_loss) / SUM(loan_amount) * 100, 2)             AS el_as_pct_of_portfolio,
    ROUND(SUM(var_95) / 1000000, 2)                                    AS total_var95_millions,
    ROUND(SUM(var_99) / 1000000, 2)                                    AS total_var99_millions
FROM loans;

-- ── 2. CREDIT RISK BY RISK RATING (Basel Framework) ──────────
SELECT
    risk_rating,
    COUNT(*)                                                           AS loan_count,
    ROUND(AVG(credit_score), 0)                                        AS avg_credit_score,
    ROUND(AVG(probability_of_default) * 100, 1)                       AS avg_pd_pct,
    ROUND(SUM(defaulted) * 100.0 / COUNT(*), 1)                       AS actual_default_rate,
    ROUND(SUM(loan_amount) / 1000000, 2)                               AS exposure_millions,
    ROUND(SUM(expected_loss) / 1000000, 3)                            AS expected_loss_millions,
    ROUND(SUM(var_99) / 1000000, 3)                                   AS var99_millions
FROM loans
GROUP BY risk_rating
ORDER BY CASE risk_rating
    WHEN 'AAA' THEN 1 WHEN 'AA' THEN 2 WHEN 'A' THEN 3
    WHEN 'BBB' THEN 4 WHEN 'BB' THEN 5 WHEN 'B' THEN 6
    WHEN 'CCC' THEN 7 END;

-- ── 3. PROBABILITY OF DEFAULT SEGMENTATION ───────────────────
SELECT
    CASE WHEN probability_of_default < 0.05  THEN '0-5% (Very Low)'
         WHEN probability_of_default < 0.15  THEN '5-15% (Low)'
         WHEN probability_of_default < 0.30  THEN '15-30% (Moderate)'
         WHEN probability_of_default < 0.50  THEN '30-50% (High)'
         ELSE '50%+ (Very High)' END                                   AS pd_bucket,
    COUNT(*)                                                           AS loan_count,
    ROUND(SUM(defaulted) * 100.0 / COUNT(*), 1)                       AS actual_default_rate,
    ROUND(AVG(loan_amount), 2)                                         AS avg_loan_amount,
    ROUND(SUM(expected_loss) / 1000000, 2)                            AS el_millions
FROM loans
GROUP BY pd_bucket
ORDER BY MIN(probability_of_default);

-- ── 4. VALUE AT RISK (VaR) — MARKET RISK ─────────────────────
SELECT
    risk_rating,
    ROUND(SUM(loan_amount) / 1000000, 2)                              AS exposure_millions,
    ROUND(SUM(var_95) / 1000000, 3)                                   AS var_95_millions,
    ROUND(SUM(var_99) / 1000000, 3)                                   AS var_99_millions,
    ROUND((SUM(var_99) - SUM(var_95)) / 1000000, 3)                   AS incremental_var_millions,
    ROUND(SUM(var_99) / SUM(loan_amount) * 100, 1)                    AS var99_as_pct_exposure
FROM loans
GROUP BY risk_rating
ORDER BY var_99_millions DESC;

-- ── 5. HIGH-RISK LOAN IDENTIFICATION ─────────────────────────
SELECT
    loan_id, risk_rating, credit_score,
    ROUND(loan_amount, 2)                                             AS loan_amount,
    ROUND(probability_of_default * 100, 1)                            AS pd_pct,
    ROUND(expected_loss, 2)                                           AS expected_loss,
    ROUND(var_99, 2)                                                  AS var_99,
    debt_to_income_ratio, delinquencies_2yr
FROM loans
WHERE risk_rating IN ('B','CCC') OR probability_of_default > 0.6
ORDER BY expected_loss DESC
LIMIT 10;

-- ── 6. ENTERPRISE RISK MANAGEMENT — RISK CONCENTRATION ───────
SELECT
    loan_purpose,
    COUNT(*)                                                          AS loan_count,
    ROUND(SUM(loan_amount) / 1000000, 2)                             AS exposure_millions,
    ROUND(SUM(defaulted) * 100.0 / COUNT(*), 1)                      AS default_rate_pct,
    ROUND(SUM(expected_loss) / 1000000, 2)                           AS el_millions,
    ROUND(SUM(expected_loss) / (SELECT SUM(expected_loss) FROM loans) * 100, 1) AS pct_of_total_el
FROM loans
GROUP BY loan_purpose
ORDER BY el_millions DESC;
