SELECT 
    -- 1. 제품 마스터 카테고리 선택
    p.masterCategory,
    -- 2. 매출 계산
    SUM(t.item_price * t.quantity) AS revenue
FROM `project.transaction` AS t
-- 3. 거래 정보와 제품 마스터 정보를 매칭
LEFT JOIN `project.products` AS p 
    ON t.product_id = p.id
-- 4. 카테고리별 그룹화 및 매출 상위 순으로 정렬
GROUP BY p.masterCategory
ORDER BY revenue DESC
-- 5. 시각화 편의를 위해 상위 5개 카테고리만 추출
LIMIT 5;