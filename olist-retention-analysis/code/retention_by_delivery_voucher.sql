-- 배송 지연 여부 × 바우처 사용 여부 4개 그룹 간 리텐션율 비교
-- 배송 지연 시 바우처 사용이 리텐션 하락을 완화하는지 확인
SELECT 
    CASE 
        WHEN is_late_delivery = 0 AND used_voucher_flag = 0 THEN 'on_time & no_voucher'
        WHEN is_late_delivery = 0 AND used_voucher_flag = 1 THEN 'on_time & voucher'
        WHEN is_late_delivery = 1 AND used_voucher_flag = 0 THEN 'late & no_voucher'
        WHEN is_late_delivery = 1 AND used_voucher_flag = 1 THEN 'late & voucher'
    END AS user_segment,
    COUNT(*) AS total_users,
    ROUND(AVG(is_reordered_90d) * 100, 2) AS retention_rate,
    ROUND(AVG(min_review_score), 2) AS avg_review_score
FROM `master_data_mart`
GROUP BY user_segment
ORDER BY user_segment;