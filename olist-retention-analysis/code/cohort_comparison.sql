-- 코호트(2017-09 vs 2017-12) 간 주요 지표 전반 비교
-- 배송 품질, 상품 구성, 결제 패턴, 리뷰 점수 등을 한 번에 조회해 리텐션 차이의 원인 후보를 탐색
SELECT 
    FORMAT_DATE('%Y-%m', first_order_date) as cohort_month,
    ROUND(AVG(is_reordered_90d) * 100, 2) as retention_rate,
    ROUND(AVG(delivery_delay_days), 2) as avg_delay_days,
    ROUND(AVG(is_late_delivery) * 100, 2) as delivery_late_rate,
    ROUND(AVG(is_late_shipping) * 100, 2) as shipping_late_rate,
    ROUND(AVG(freight_ratio) * 100, 2) as avg_freight_ratio,
    ROUND(AVG(has_consumable_item) * 100, 2) as consumable_rate,
    ROUND(AVG(min_review_score), 2) as avg_review_score,
    ROUND(AVG(used_voucher_flag) * 100, 2) as voucher_use_rate,
    ROUND(AVG(max_installments), 2) as avg_installments,
    ROUND(AVG(item_count), 2) as avg_item_count,
    ROUND(AVG(category_count), 2) as avg_category_count
FROM `master_data_mart`
WHERE FORMAT_DATE('%Y-%m', first_order_date) IN ('2017-09', '2017-12')
GROUP BY cohort_month;