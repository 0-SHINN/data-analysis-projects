-- 주문 금액 구간(100BRL 단위)별 리텐션율, 리뷰 점수, 배송 지연율 비교
-- 구매 금액 수준이 재구매 행동에 미치는 영향 확인
SELECT 
    FORMAT_DATE('%Y-%m', first_order_date) as cohort_month,
    CASE 
        WHEN total_price < 100 THEN '0-100'
        WHEN total_price < 200 THEN '100-200'
        WHEN total_price < 300 THEN '200-300'
        ELSE '300+' 
    END AS price_bucket,
    COUNT(*) AS total_users,
    SUM(is_reordered_90d) AS reorder_users,
    ROUND(AVG(is_reordered_90d) * 100, 2) AS retention_rate,
    ROUND(AVG(min_review_score), 2) AS avg_review_score,
    ROUND(COUNTIF(delivery_delay_days > 0) / COUNT(*) * 100, 2) AS delay_order_pct,
    ROUND(COUNTIF(shipping_delay_days > 0) / COUNT(*) * 100, 2) AS delay_shipping_pct
FROM `master_data_mart`
WHERE FORMAT_DATE('%Y-%m', first_order_date) IN ('2017-09', '2017-12')
GROUP BY cohort_month, price_bucket
ORDER BY cohort_month, price_bucket;