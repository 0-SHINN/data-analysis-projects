-- =========================================
-- 가설 3: 가챠 사용 여부에 따른 1주차 리텐션 및 평균 최대 스테이지 비교
-- =========================================

-- 1. 유저별 첫 이벤트일, 최대 스테이지, 3일 이내 가챠 사용 여부 추출
WITH gacha_flag AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_event_date,
        MAX(CAST(stage AS INT64)) AS max_stage,
        MAX(
            CASE
                WHEN event_name = 'gacha'
                     AND DATE_DIFF(DATE(event_time), DATE(install_time), DAY) <= 3
                THEN 1
                ELSE 0
            END
        ) > 0 AS did_gacha
    FROM `game_log`
    GROUP BY user_id
),

-- 2. 1주차 리텐션 여부 계산
retained_flag AS (
    SELECT
        g.user_id,
        max_stage,
        did_gacha,
        MAX(
            CASE
                WHEN DATE_DIFF(DATE(event_time), first_event_date, DAY) BETWEEN 7 AND 13 THEN 1
                ELSE 0
            END
        ) AS retained
    FROM gacha_flag g
    LEFT JOIN `game_log` l
        ON g.user_id = l.user_id
    WHERE first_event_date >= '2023-06-18'
    GROUP BY g.user_id, did_gacha, max_stage
)

-- 3. 가챠 사용 여부별 리텐션율 및 평균 최대 스테이지 집계
SELECT
    did_gacha,
    COUNT(*) AS user_count,
    SUM(retained) AS retained_count,
    ROUND(SUM(retained) / COUNT(*), 4) AS retention_rate,
    ROUND(AVG(max_stage), 1) AS avg_max_stage
FROM retained_flag
GROUP BY did_gacha
