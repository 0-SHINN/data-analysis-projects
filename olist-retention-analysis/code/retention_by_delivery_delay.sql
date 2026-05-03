-- 배송 지연 여부에 따른 리텐션율 및 리뷰 점수 비교
-- 지연 배송이 재구매에 미치는 직접적인 영향 측정
SELECT 
    CASE 
        WHEN is_late_delivery = 1 THEN 'late'
        ELSE 'on_time'
    END AS group_tag,
    COUNT(*) AS total_users,
    SUM(is_reordered_90d) AS reorder_users,
    ROUND(AVG(is_reordered_90d) * 100, 2) AS retention_rate,
    ROUND(AVG(min_review_score), 2) AS avg_review_score
FROM `master_data_mart`
GROUP BY group_tag
ORDER BY group_tag;