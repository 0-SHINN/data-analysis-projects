CREATE OR REPLACE TABLE `master_data_mart` AS
WITH first_orders AS (
    -- 고객별 첫 번째 배송완료 주문 추출
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS order_seq
    FROM `olist.orders` o
    JOIN `olist.customers` c 
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
items_agg AS (
    -- 주문별 상품 집계 (소모품 여부 포함)
    SELECT
        oi.order_id,
        MAX(oi.shipping_limit_date) AS shipping_limit_date,
        COUNT(oi.product_id) AS item_count,
        COUNT(DISTINCT p.product_category_name) AS category_count,
        SUM(oi.price) AS total_price,
        SUM(oi.freight_value) AS total_freight,
        MAX(CASE WHEN p.product_category_name IN (
            'health_beauty', 'perfumery', 'food_drink',
            'baby', 'pet_shop', 'cleaning_products'
        ) THEN 1 ELSE 0 END) AS has_consumable_item
    FROM `olist.order_items` oi
    JOIN `olist.products` p 
      ON oi.product_id = p.product_id
    GROUP BY oi.order_id
),
payments_agg AS (
    -- 주문별 결제 집계 (바우처 사용 여부 포함)
    SELECT
        order_id,
        MAX(payment_installments) AS max_installments,
        MAX(CASE WHEN payment_type = 'voucher' THEN 1 ELSE 0 END) AS used_voucher_flag
    FROM `olist.order_payments`
    GROUP BY order_id
),
reviews_agg AS (
    -- 복수 리뷰가 있을 경우 최솟값 사용
    SELECT
        order_id,
        MIN(review_score) AS min_review_score
    FROM olist.reviews`
    GROUP BY order_id
),
retention_label AS (
    -- 첫 구매일 기준 90일 내 재구매 여부
    SELECT
        f.customer_unique_id,
        f.order_id AS first_order_id,
        MAX(CASE WHEN 
                    DATE_DIFF(
                        DATE(o_next.order_purchase_timestamp), 
                        DATE(f.order_purchase_timestamp), DAY)
                    BETWEEN 1 AND 90 THEN 1
                ELSE 0
            END) AS is_reordered_90d
    FROM first_orders f
    LEFT JOIN `olist.customers` c_next 
           ON f.customer_unique_id = c_next.customer_unique_id
    LEFT JOIN `olist.orders` o_next
           ON c_next.customer_id = o_next.customer_id
          AND o_next.order_status = 'delivered'
    WHERE f.order_seq = 1
    GROUP BY f.customer_unique_id, f.order_id
)

SELECT
    f.customer_unique_id,
    f.order_id AS first_order_id,
    DATE(f.order_purchase_timestamp) AS first_order_date,

    -- 배송 품질
    DATE_DIFF(DATE(f.order_delivered_customer_date), DATE(f.order_estimated_delivery_date), DAY) AS delivery_delay_days,
    CASE WHEN DATE_DIFF(DATE(f.order_delivered_customer_date), DATE(f.order_estimated_delivery_date), DAY) > 0 THEN 1 ELSE 0 END AS is_late_delivery,
    DATE_DIFF(f.order_delivered_carrier_date, i.shipping_limit_date, DAY) AS shipping_delay_days,
    CASE WHEN DATE_DIFF(f.order_delivered_carrier_date, i.shipping_limit_date, DAY) > 0 THEN 1 ELSE 0 END AS is_late_shipping,

    -- 상품
    i.total_price,
    ROUND(SAFE_DIVIDE(i.total_freight, i.total_price), 2) AS freight_ratio,
    i.item_count,
    i.category_count,
    i.has_consumable_item,

    -- 결제
    p.max_installments,
    p.used_voucher_flag,

    -- 리뷰
    r.min_review_score,

    -- 타겟
    ret.is_reordered_90d

FROM first_orders f
LEFT JOIN items_agg i ON f.order_id = i.order_id
LEFT JOIN payments_agg p ON f.order_id = p.order_id
LEFT JOIN reviews_agg r ON f.order_id = r.order_id
     JOIN retention_label ret ON f.customer_unique_id = ret.customer_unique_id
      AND f.order_id = ret.first_order_id
WHERE f.order_seq = 1
  AND f.order_purchase_timestamp >= '2017-01-01'
  AND f.order_purchase_timestamp < '2018-06-01'