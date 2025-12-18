WITH first_order AS (
    -- 1. 고객별 최초 성공 주문월 산출 (신규 고객 판별의 기준점)
    SELECT
        customer_id,
        DATE_TRUNC(DATE(MIN(created_at)), MONTH) AS first_order_month
    FROM `project.transaction`
    GROUP BY customer_id
)

-- 2. 분석 기간내 결제 성공 트랜잭션 집계 및 유저 분류
SELECT
    DATE_TRUNC(DATE(t.created_at), MONTH) AS order_month,
    -- 유저 구분 로직: 현재 주문월이 최초 주문월과 같으면 '신규', 다르면 '기존'
    CASE
        WHEN DATE_TRUNC(DATE(t.created_at), MONTH) = f.first_order_month THEN 'new_users'
        ELSE 'repeat_users'
    END AS user_flag,
    -- 매출 합계 계산
    SUM(t.item_price * t.quantity) AS revenue
FROM `fashion_campus.transaction` AS t
-- 최초 주문 정보와 결합하여 유저 상태 판별
JOIN first_order AS f
    ON t.customer_id = f.customer_id
GROUP BY order_month, user_flag
ORDER BY order_month, user_flag;