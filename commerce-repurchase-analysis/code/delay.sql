WITH first_order AS (
    -- 1. 첫 구매(order_seq = 1) 고객별 배송 지연 여부 산출 및 분석 기간 분류
    SELECT 
        customer_unique_id,
        -- 배송 지연 정의: 실제 고객 수령일(delivered)이 예정일(estimated)보다 늦은 경우 1로 플래그
        CASE 
            WHEN DATE(MIN(order_delivered_customer_date)) > DATE(MIN(order_estimated_delivery_date)) THEN 1 
            ELSE 0 
        END AS is_delay,
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
    -- 2. 분석 기간 내 재구매(order_seq = 2) 기록이 있는 고객 식별
    SELECT
        DISTINCT customer_unique_id
    FROM `project.analysis_table`
    WHERE order_seq = 2
)

-- 3. 기간 및 지연 여부별 유저 규모와 재구매 전환율(CVR) 산출
SELECT
    f.period,
    f.is_delay,
    COUNT(*) AS users,
    -- 재구매 전환율 계산
    ROUND(SAFE_DIVIDE(COUNT(s.customer_unique_id), COUNT(f.customer_unique_id)) * 100, 2) AS cvr
FROM first_order AS f
LEFT JOIN second_order AS s 
    ON f.customer_unique_id = s.customer_unique_id
WHERE f.period IS NOT NULL
GROUP BY f.period, f.is_delay
ORDER BY f.period, f.is_delay;