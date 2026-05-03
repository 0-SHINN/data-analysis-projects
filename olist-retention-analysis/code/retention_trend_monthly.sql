-- 전체 기간 월별 리텐션율 추이
SELECT 
    FORMAT_DATE('%Y-%m', first_order_date) AS first_order_month,
    COUNT(*) AS total_users,
    SUM(is_reordered_90d) AS reorder_users,
    ROUND(AVG(is_reordered_90d) * 100, 2) as retention_rate
FROM `master_data_mart`
GROUP BY first_order_month
ORDER BY first_order_month;