WITH first_order AS (
    -- 1. 첫 구매(order_seq = 1) 고객별 특성 및 분석 기간 분류
    SELECT 
        customer_unique_id,
        -- 배송 지연 여부 (실제 배송일 > 예정 배송일)
        CASE 
            WHEN DATE(MIN(order_delivered_customer_date)) > DATE(MIN(order_estimated_delivery_date)) THEN 1 
            ELSE 0 
        END AS is_delay,
        -- 바우처 사용 여부
        MAX(CASE WHEN payment_type = 'voucher' THEN 1 ELSE 0 END) AS use_voucher,
        -- 첫 구매 제품 수량 2개 이상 여부
        CASE WHEN COUNT(*) > 1 THEN 1 ELSE 0 END AS product_count,
        -- 첫 구매 카테고리 2개 이상 여부
        CASE WHEN COUNT(DISTINCT product_category_name) > 1 THEN 1 ELSE 0 END AS category_count,
        -- 리뷰 점수 5점 만점 여부
        CASE WHEN AVG(review_score) = 5 THEN 1 ELSE 0 END AS avg_review_score,
        -- 분석 기간 분류
        CASE 
            WHEN FORMAT_DATE('%Y-%m', MIN(order_purchase_timestamp)) BETWEEN '2017-01' AND '2018-02' THEN 'baseline'
            WHEN FORMAT_DATE('%Y-%m', MIN(order_purchase_timestamp)) BETWEEN '2018-03' AND '2018-08' THEN 'issue'
            ELSE NULL
        END AS period
    FROM `project.analysis_table`
    WHERE order_seq = 1
    GROUP BY customer_unique_id
),

second_order AS (
    -- 2. 재구매(order_seq = 2)를 진행한 고객 식별
    SELECT
        DISTINCT customer_unique_id
    FROM `project.analysis_table`
    WHERE order_seq = 2
)

-- 3. 기간별 지표 비교
SELECT
    f.period,
    -- 재구매 전환율 (CVR)
    ROUND(SAFE_DIVIDE(COUNT(s.customer_unique_id), COUNT(f.customer_unique_id)) * 100, 2) AS cvr,
    -- 각 가설별 평균 비율 (%)
    ROUND(AVG(f.is_delay) * 100, 2) AS delay_rate,
    ROUND(AVG(f.use_voucher) * 100, 2) AS voucher_rate,
    ROUND(AVG(f.product_count) * 100, 2) AS `2+ product_rate`,
    ROUND(AVG(f.category_count) * 100, 2) AS `2+ category_rate`,
    ROUND(AVG(f.avg_review_score) * 100, 2) AS `5_score_rate`
FROM first_order AS f
LEFT JOIN second_order AS s 
    ON f.customer_unique_id = s.customer_unique_id
WHERE f.period IS NOT NULL
GROUP BY f.period;