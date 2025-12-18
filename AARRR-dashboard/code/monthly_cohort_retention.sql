WITH cohort AS (
  SELECT
    customer_id,
    -- 1. 유저별 최초 구매월 산출 (Window Function 활용)
    FORMAT_DATE("%Y-%m", MIN(created_at) OVER (PARTITION BY customer_id)) AS cohort_month,
    -- 2. 첫 구매월과 현재 구매월 간의 차이(Month Index) 계산
    DATE_DIFF(DATE_TRUNC(DATE(created_at), MONTH), 
              DATE_TRUNC(DATE(MIN(created_at) 
              OVER (PARTITION BY customer_id)), MONTH), MONTH) 
              AS month_diff  
  FROM `projecct.transaction`
)
SELECT 
  cohort_month,
  month_diff,
  COUNT(DISTINCT customer_id) AS total_customer,
  -- 3. 리텐션율 산출: month_diff=0(첫 달) 유저 수 대비 잔존 비중 계산
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT customer_id),
                    MAX(CASE WHEN month_diff = 0 THEN COUNT(DISTINCT customer_id) END) 
                    OVER (PARTITION BY cohort_month)) * 100, 2) AS retention_rate
FROM cohort
GROUP BY cohort_month, month_diff
ORDER BY cohort_month, month_diff