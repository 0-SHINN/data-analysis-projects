WITH first_order AS (
    -- 1. 첫 구매(order_seq = 1) 고객의 구매 수량 그룹화 및 분석 기간 분류
    SELECT 
        customer_unique_id,
        -- 제품 수량 그룹화: 단일 구매('1')와 다중 구매('2+')로 분류
        CASE 
            WHEN COUNT(*) > 1 THEN '2+' 
            ELSE '1' 
        END AS product_count,
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

-- 3. 기간 및 구매 수량 그룹별 유저 수와 재구매 전환율(CVR) 산출
SELECT
    f.period,
    f.product_count,
    COUNT(*) AS users,
    -- 재구매 전환율 계산
    ROUND(SAFE_DIVIDE(COUNT(s.customer_unique_id), COUNT(f.customer_unique_id)) * 100, 2) AS cvr
FROM first_order AS f
LEFT JOIN second_order AS s 
    ON f.customer_unique_id = s.customer_unique_id
WHERE f.period IS NOT NULL
GROUP BY f.period, f.product_count
ORDER BY f.period, f.product_count;