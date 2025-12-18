WITH first_order AS (
    -- 1. 첫 구매(order_seq = 1) 고객의 리뷰 점수 그룹화 및 기간 분류
    SELECT 
        customer_unique_id,
        -- 리뷰 점수 그룹화: 만점(5), 일반(1-4), 미작성(no review)
        CASE 
            WHEN AVG(review_score) = 5 THEN '5' 
            WHEN AVG(review_score) IS NULL THEN 'no review'
            ELSE '1-4' 
        END AS avg_review_score,
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

-- 3. 기간 및 리뷰 점수 그룹별 유저 수와 재구매 전환율(CVR) 산출
SELECT
    f.period,
    f.avg_review_score,
    COUNT(*) AS users,
    -- 재구매 전환율 계산
    ROUND(SAFE_DIVIDE(COUNT(s.customer_unique_id), COUNT(f.customer_unique_id)) * 100, 2) AS cvr
FROM first_order AS f
LEFT JOIN second_order AS s 
    ON f.customer_unique_id = s.customer_unique_id
WHERE f.period IS NOT NULL
GROUP BY f.period, f.avg_review_score
ORDER BY f.period, f.avg_review_score;