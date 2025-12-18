WITH first_order AS (
    -- 1. 고객별 최초 구매월(order_seq = 1) 정의 및 코호트 그룹화
    SELECT 
        customer_unique_id,
        -- 최초 구매 발생 시점을 월 단위로 추출하여 코호트 그룹 생성
        FORMAT_DATE("%Y-%m", MIN(order_purchase_timestamp)) AS order_month
    FROM `project.analysis_table`
    WHERE order_seq = 1
    GROUP BY customer_unique_id
),

second_order AS (
    -- 2. 재구매(order_seq = 2) 이력이 있는 고객 식별
    SELECT
        DISTINCT customer_unique_id
    FROM `project.analysis_table`
    WHERE order_seq = 2
)

-- 3. 첫 구매 코호트별 재구매 유저 수 및 전환율(CVR) 집계
SELECT
    f.order_month,
    -- 해당 월에 첫 구매를 진행한 전체 유저 수
    COUNT(DISTINCT f.customer_unique_id) AS first_buyers,
    -- 그중 실제 재구매(2차 구매)로 이어진 유저 수
    COUNT(DISTINCT s.customer_unique_id) AS re_buyers,
    -- 재구매 전환율 산출
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT s.customer_unique_id), 
                      COUNT(DISTINCT f.customer_unique_id)) * 100, 2) AS cvr
FROM first_order AS f
LEFT JOIN second_order AS s 
    ON f.customer_unique_id = s.customer_unique_id
GROUP BY order_month
ORDER BY order_month;