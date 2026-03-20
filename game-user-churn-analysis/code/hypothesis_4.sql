-- =========================================
-- 가설 4: 도달 스테이지 구간별 1주차 리텐션 및 평균 활동일 비교
-- =========================================

-- 1. 유저별 도달 스테이지 구간, 활동일, 첫 이벤트 날짜 추출
WITH stage_seg AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_event_date
        CASE
            WHEN MAX(CAST(stage AS INT64)) <= 10 THEN '1-10'
            WHEN MAX(CAST(stage AS INT64)) <= 20 THEN '11-20'
            WHEN MAX(CAST(stage AS INT64)) <= 30 THEN '21-30'
            WHEN MAX(CAST(stage AS INT64)) <= 40 THEN '31-40'
            ELSE '41-50'
        END AS max_stage,
        DATE_DIFF(MAX(DATE(event_time)), MIN(DATE(event_time)), DAY) AS active_date        
    FROM `game_log`
    WHERE event_name LIKE 'stage_%'
    GROUP BY user_id
),

-- 2. 1주차 리텐션 여부 계산
retained_flag AS (
    SELECT
        s.user_id,
        max_stage,
        active_date,
        MAX(
            CASE
                WHEN DATE_DIFF(DATE(event_time), first_event_date, DAY) BETWEEN 7 AND 13 THEN 1
                ELSE 0
            END
        ) AS retained
    FROM stage_seg s
    LEFT JOIN `game_log` l
        ON s.user_id = l.user_id
    WHERE first_event_date >= '2023-06-18'
    GROUP BY user_id, max_stage, active_date
)

-- 3. 스테이지 구간별 리텐션율 및 평균 활동일 집계
SELECT
    max_stage,
    COUNT(*) AS user_count,
    SUM(retained) AS retained_count,
    ROUND(SUM(retained) / COUNT(*), 4) AS retention_rate,
    ROUND(AVG(active_date), 1) AS avg_active_date
FROM retained_flag
GROUP BY max_stage;
