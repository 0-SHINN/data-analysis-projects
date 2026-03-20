-- =========================================
-- 가설 1: 튜토리얼 진행 여부에 따른 1주차 리텐션 및 스테이지 진입율 비교
-- =========================================

-- 1. 유저별 튜토리얼 진행 여부, 스테이지 진입 여부, 첫 이벤트 날짜 추출
WITH tutorial_flag AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_event_date,
        MAX(CASE WHEN tutorial = '10' THEN 1 ELSE 0 END) > 0 AS clear_tutorial,
        MAX(CASE WHEN stage IS NOT NULL THEN 1 ELSE 0 END) AS enter_stage
    FROM `game_log`
    GROUP BY user_id
),

-- 2. 1주차(1~7일) 리텐션 여부 플래그 생성
retained_flag AS (
    SELECT
        t.user_id,
        t.clear_tutorial,
        t.enter_stage,
        MAX(
            CASE
                WHEN DATE_DIFF(DATE(event_time), t.first_event_date, DAY) BETWEEN 7 AND 13 THEN 1
                ELSE 0
            END
        ) AS retained
    FROM tutorial_flag t
    LEFT JOIN `game_log` g
        ON t.user_id = g.user_id
    WHERE t.first_event_date >= '2023-06-18'
    GROUP BY t.user_id, clear_tutorial, enter_stage
)

-- 3. 튜토리얼 진행 여부별 리텐션율, 스테이지 진입율 계산
SELECT
    clear_tutorial,
    COUNT(*) AS user_count,
    SUM(retained) AS retained_count,
    ROUND(SUM(retained) / COUNT(*), 4) AS retention_rate,
    SUM(enter_stage) AS enter_stage_count,
    ROUND(SUM(enter_stage) / COUNT(*), 4) AS enter_stage_rate
FROM retained_flag
GROUP BY clear_tutorial
