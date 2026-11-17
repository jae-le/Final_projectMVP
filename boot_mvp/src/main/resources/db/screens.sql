-- =====================================================================
-- 상영 시간표 자동 생성 (앱이 기동할 때마다 EmbeddedMariaDbConfig 가 실행)
--
-- 예매 화면은 "지금 이후 ~ 오늘+21일" 상영만 보여주므로, 기동할 때마다 오늘부터 21일치를 채운다.
-- 이미 있는 회차는 건너뛴다 (INSERT IGNORE) -> 예매로 줄어든 잔여 좌석은 유지된다.
--
-- 규칙
-- - 극장마다 상영관 4개, 하루 6회차 (상영관마다 10분씩 엇갈림), 09시대 회차는 조조(pricetype 1)
-- - 상영작은 개봉한 영화(releaseday <= 오늘) 중에서 극장/상영관/날짜별로 돌아가며 배정
-- - 좌석은 A~M x 1~14 = 182석 (코드에 고정)
-- MariaDB 의 seq_X_to_Y 시퀀스 테이블을 사용한다.
-- =====================================================================

INSERT IGNORE INTO screentb
  (areano, theaterno, movieno, viewday, roomno, pricetype, starttime, endtime, selecseat, totalseat)
SELECT t.areano,
       t.theaterno,
       m.movieno,
       DATE(x.st),
       x.roomno,
       CASE WHEN HOUR(x.st) < 10 THEN 1 ELSE 2 END,
       x.st,
       x.st + INTERVAL IF(m.times > 0, m.times, 120) MINUTE,
       182,
       182
FROM theatertb t
JOIN (
    SELECT r.seq AS roomno,
           d.seq AS dayoff,
           TIMESTAMP(CURDATE() + INTERVAL d.seq DAY, '09:00:00') + INTERVAL (s.seq * 160 + (r.seq - 1) * 10) MINUTE AS st
      FROM seq_1_to_4 r
      CROSS JOIN seq_0_to_21 d
      CROSS JOIN seq_0_to_5 s
) x
JOIN (
    SELECT movieno, times,
           ROW_NUMBER() OVER (ORDER BY ranking IS NULL, ranking, releaseday DESC, movieno) AS rn,
           COUNT(*) OVER () AS cnt
      FROM movieinfotb_v
     WHERE releaseday <= CURDATE()
) m ON m.rn = MOD(t.areano * 7 + t.theaterno * 3 + x.roomno * 5 + x.dayoff, m.cnt) + 1;

-- 이전 실행에서 남은 임시 좌석 점유 정리 (앱의 10분 타이머는 재시작하면 사라짐)
DELETE FROM reserdtltmptb WHERE adate < NOW() - INTERVAL 10 MINUTE;
