WITH funnel AS (
    -- 1. 각 단계별 고유 세션 수 집계 (순차적 조인을 통한 여정 추적)
    SELECT
        -- 첫 단계: 홈페이지 방문 세션
        COUNT(DISTINCT e1.session_id) AS homepage_sessions,
        -- 두 번째 단계: 홈 방문 이후 발생한 제품 상세 페이지 조회
        COUNT(DISTINCT e2.session_id) AS item_detail_sessions,
        -- 세 번째 단계: 상세 페이지 조회 이후 발생한 장바구니 담기
        COUNT(DISTINCT e3.session_id) AS add_to_cart_sessions,
        -- 네 번째 단계: 장바구니 담기 이후 발생한 최종 결제 완료
        COUNT(DISTINCT e4.session_id) AS booking_sessions
    FROM `project.click_stream` AS e1
    -- [Step 2] 상세 페이지 조회 조인
    LEFT JOIN `project.click_stream` AS e2
        ON e1.session_id = e2.session_id
        AND e2.event_name = 'ITEM_DETAIL'
        AND e2.event_time >= e1.event_time
    -- [Step 3] 장바구니 담기 조인
    LEFT JOIN `project.click_stream` AS e3
        ON e2.session_id = e3.session_id
        AND e3.event_name = 'ADD_TO_CART'
        AND e3.event_time >= e2.event_time
    -- [Step 4] 최종 결제 조인
    LEFT JOIN `project.click_stream` AS e4
        ON e3.session_id = e4.session_id
        AND e4.event_name = 'BOOKING'
        AND e4.event_time >= e3.event_time
    -- 분석 기준점: 홈페이지 유입을 모수로 설정
    WHERE e1.event_name = 'HOMEPAGE'
)

-- 2. 단계별 전환율(Conversion Rate) 산출
SELECT
    -- 각 단계별 세션 규모
    homepage_sessions,
    item_detail_sessions,
    add_to_cart_sessions,
    booking_sessions,
    -- 이전 단계 대비 전환율 (%)
    ROUND(item_detail_sessions / homepage_sessions * 100, 2) AS conv_home_to_detail,
    ROUND(1.0 * add_to_cart_sessions / item_detail_sessions * 100, 2) AS conv_detail_to_cart,
    ROUND(1.0 * booking_sessions / add_to_cart_sessions * 100, 2) AS conv_cart_to_booking,
    -- 전체 퍼널(홈 → 결제) 최종 전환율 (%)
    ROUND(1.0 * booking_sessions / homepage_sessions * 100, 2) AS conv_home_to_booking
FROM funnel;