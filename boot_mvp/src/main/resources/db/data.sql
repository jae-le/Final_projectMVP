-- =====================================================================
-- mvpdb 초기 데이터
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 기준 데이터
-- ---------------------------------------------------------------------

-- TMDB 한국어 장르명 (movietb.genre 와 같은 표기여야 장르 탭 필터가 동작)
INSERT INTO genre (genreno, genrenm) VALUES
 (28,'액션'),(12,'모험'),(16,'애니메이션'),(35,'코미디'),(80,'범죄'),(99,'다큐멘터리'),(18,'드라마'),
 (10751,'가족'),(14,'판타지'),(36,'역사'),(27,'공포'),(10402,'음악'),(9648,'미스터리'),(10749,'로맨스'),
 (878,'SF'),(10770,'TV 영화'),(53,'스릴러'),(10752,'전쟁'),(37,'서부');

-- 쿠폰 정의: refno 1 = 생일 쿠폰, refno 4 = 출석 만근 쿠폰 (코드에 고정). 할인율은 결제 화면 JS(pay_fn.js) 기준
INSERT INTO couponreftb (refno, type, name, benefit, period) VALUES
 (1,'C','주중관람권','주중 상영 영화 1회 관람',30),
 (2,'C','주말관람권','주말 상영 영화 1회 관람',30),
 (3,'D','10% 할인권','결제 금액의 10% 할인',30),
 (4,'D','5% 할인권','결제 금액의 5% 할인',30);

INSERT INTO areatb (areano, areanm) VALUES
 (1,'서울'),(2,'경기/인천'),(3,'충청/대전'),(4,'전라/광주'),(5,'경북/대구'),(6,'경남/부산/울산'),(7,'강원'),(8,'제주');

INSERT INTO theatertb (areano, theaterno, theaternm) VALUES
 (1,1,'강남'),(1,2,'건대입구'),(1,3,'홍대입구'),(1,4,'영등포'),
 (2,1,'수원'),(2,2,'인천터미널'),(2,3,'판교'),
 (3,1,'대전둔산'),(3,2,'청주'),
 (4,1,'광주상무'),(4,2,'전주'),
 (5,1,'대구동성로'),
 (6,1,'부산서면'),(6,2,'해운대'),(6,3,'울산'),
 (7,1,'춘천'),
 (8,1,'제주');

-- 가격: 유형별 정확히 4행 (성인/청소년/경로/장애인 순서). 1x = 조조, 2x = 일반
INSERT INTO pricetb (pricetype, typenm, pricenm, nowprice) VALUES
 (11,'조조','성인',11000),(12,'조조','청소년',9000),(13,'조조','경로',7000),(14,'조조','장애인',5000),
 (21,'일반','성인',15000),(22,'일반','청소년',12000),(23,'일반','경로',8000),(24,'일반','장애인',5000);

-- ---------------------------------------------------------------------
-- 테스트 회원 (아이디 user01 ~ user05, 비밀번호는 모두 1234 / BCrypt 해시)
-- uuid 는 다른 테이블에서 참조하기 쉽게 고정값 사용
-- ---------------------------------------------------------------------

INSERT INTO usertb (userid, uuid, ppass, pname, email, phone, birth, gender, certno, account) VALUES
 ('user01','a0000000-0000-4000-8000-000000000001','$2a$10$/yf/AOh7uH4C.TZNNzuziuaioqjXCyiy8jWlP3RAzuceR646JViD.','김민준','user01@example.com','010-1111-0001','1995-03-14',1,0,'국민 123456-01-000001'),
 ('user02','a0000000-0000-4000-8000-000000000002','$2a$10$/yf/AOh7uH4C.TZNNzuziuaioqjXCyiy8jWlP3RAzuceR646JViD.','이서연','user02@example.com','010-1111-0002','1998-07-22',2,0,NULL),
 ('user03','a0000000-0000-4000-8000-000000000003','$2a$10$/yf/AOh7uH4C.TZNNzuziuaioqjXCyiy8jWlP3RAzuceR646JViD.','박지호','user03@example.com','010-1111-0003','2001-11-05',1,0,NULL),
 ('user04','a0000000-0000-4000-8000-000000000004','$2a$10$/yf/AOh7uH4C.TZNNzuziuaioqjXCyiy8jWlP3RAzuceR646JViD.','최유나','user04@example.com','010-1111-0004','1990-01-30',2,0,'신한 110-000-000004'),
 ('user05','a0000000-0000-4000-8000-000000000005','$2a$10$/yf/AOh7uH4C.TZNNzuziuaioqjXCyiy8jWlP3RAzuceR646JViD.','정하준','user05@example.com','010-1111-0005','2003-06-18',1,0,NULL);

INSERT INTO selecgenretb (uuid, genrenm, origin_table) VALUES
 ('a0000000-0000-4000-8000-000000000001','액션','user'),('a0000000-0000-4000-8000-000000000001','SF','user'),('a0000000-0000-4000-8000-000000000001','스릴러','user'),
 ('a0000000-0000-4000-8000-000000000002','로맨스','user'),('a0000000-0000-4000-8000-000000000002','드라마','user'),('a0000000-0000-4000-8000-000000000002','애니메이션','user'),
 ('a0000000-0000-4000-8000-000000000003','공포','user'),('a0000000-0000-4000-8000-000000000003','미스터리','user'),
 ('a0000000-0000-4000-8000-000000000004','드라마','user'),('a0000000-0000-4000-8000-000000000004','다큐멘터리','user'),('a0000000-0000-4000-8000-000000000004','음악','user'),
 ('a0000000-0000-4000-8000-000000000005','애니메이션','user'),('a0000000-0000-4000-8000-000000000005','코미디','user');

-- ---------------------------------------------------------------------
-- 포인트 이력 -> 포인트 / 마일리지 / 등급 (앱의 가입/적립 로직과 같은 방식으로 집계)
-- pthistno = pt{yymmdd}-{NNNN} (해당 날짜 기준), 날짜는 초기화 시점 기준 상대값
-- ---------------------------------------------------------------------

INSERT INTO pthisttb (pthistno, uuid, kind, description, recqt, issqt, trndt)
SELECT CONCAT('pt', DATE_FORMAT(d, '%y%m%d'), '-',
              LPAD(ROW_NUMBER() OVER (PARTITION BY DATE(d) ORDER BY uuid, kind, n), 4, '0')),  -- 날짜별 일련번호
       uuid, kind, description, recqt, issqt, d
FROM (
  SELECT 'a0000000-0000-4000-8000-000000000001' uuid, 1 n, '적립' kind, '가입축하포인트 적립' description, 1000 recqt, 0 issqt, NOW() - INTERVAL 200 DAY d UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000001', 1, '적립', '관람권구매 포인트적립', 4500, 0, NOW() - INTERVAL 120 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000001', 1, '적립', '관람권구매 포인트적립', 4200, 0, NOW() - INTERVAL 40 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000001', 2, '사용', '관람권구매 포인트사용', 0, 3000, NOW() - INTERVAL 40 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000001', 1, '적립', '출석이벤트 포인트적립', 100, 0, NOW() - INTERVAL 10 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000002', 2, '적립', '가입축하포인트 적립', 1000, 0, NOW() - INTERVAL 200 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000002', 2, '적립', '관람권구매 포인트적립', 7000, 0, NOW() - INTERVAL 60 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000002', 2, '적립', '출석이벤트 포인트적립', 50, 0, NOW() - INTERVAL 10 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000003', 3, '적립', '가입축하포인트 적립', 1000, 0, NOW() - INTERVAL 120 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000003', 2, '적립', '관람권구매 포인트적립', 450, 0, NOW() - INTERVAL 15 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000004', 4, '적립', '가입축하포인트 적립', 1000, 0, NOW() - INTERVAL 200 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000004', 3, '적립', '관람권구매 포인트적립', 6500, 0, NOW() - INTERVAL 120 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000004', 4, '적립', '관람권구매 포인트적립', 5200, 0, NOW() - INTERVAL 40 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000004', 1, '사용', '관람권구매 포인트사용', 0, 5000, NOW() - INTERVAL 15 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000004', 1, '적립', '관람권구매 포인트적립', 900, 0, NOW() - INTERVAL 3 DAY UNION ALL
  SELECT 'a0000000-0000-4000-8000-000000000005', 1, '적립', '가입축하포인트 적립', 1000, 0, NOW() - INTERVAL 2 DAY
) t;

INSERT INTO point (uuid, onhqt, recqt, issqt)
SELECT uuid, SUM(recqt) - SUM(issqt), SUM(recqt), SUM(issqt) FROM pthisttb GROUP BY uuid;

INSERT INTO mileage (uuid, recqt, onhqt)
SELECT uuid,
       SUM(CASE WHEN YEAR(trndt) = YEAR(CURDATE()) AND MONTH(trndt) = MONTH(CURDATE()) THEN recqt ELSE 0 END),
       SUM(recqt)
FROM pthisttb GROUP BY uuid;

-- 등급 기준 (mileage.onhqt): Friend 7800 / VIP 9600 / MVP 12000
INSERT INTO gradetb (uuid, grade, current_year)
SELECT uuid,
       CASE WHEN onhqt >= 12000 THEN 'MVP' WHEN onhqt >= 9600 THEN 'VIP' WHEN onhqt >= 7800 THEN 'Friend' ELSE 'Welcome' END,
       YEAR(CURDATE())
FROM mileage;

-- 출석 (최근 며칠)
INSERT INTO attendance (uuid, adate, points)
SELECT u.uuid, CURDATE() - INTERVAL s.seq DAY, 10
FROM (SELECT 'a0000000-0000-4000-8000-000000000001' uuid UNION ALL SELECT 'a0000000-0000-4000-8000-000000000002'
      UNION ALL SELECT 'a0000000-0000-4000-8000-000000000004') u
CROSS JOIN seq_1_to_6 s;

-- ---------------------------------------------------------------------
-- 쿠폰 (couponno = {C|D}{yymmdd}-{NNNN}, acrec A=사용가능 / N=미등록 / D=사용완료)
-- ---------------------------------------------------------------------

INSERT INTO coupontb (couponno, refno, uuid, acrec, endDate, reason, adate)
SELECT CONCAT(r.type, DATE_FORMAT(c.d, '%y%m%d'), '-', LPAD(c.n, 4, '0')), c.refno, c.uuid, c.acrec,
       c.d + INTERVAL r.period DAY, c.reason, c.d
FROM (
  SELECT 1 refno, 'a0000000-0000-4000-8000-000000000001' uuid, 'A' acrec, '생일 축하 쿠폰' reason, NOW() - INTERVAL 20 DAY d, 1 n UNION ALL
  SELECT 3, 'a0000000-0000-4000-8000-000000000001', 'A', '신규 회원 웰컴 쿠폰', NOW() - INTERVAL 30 DAY, 1 UNION ALL
  SELECT 4, 'a0000000-0000-4000-8000-000000000001', 'N', '출석이벤트 만근 축하', NOW() - INTERVAL 5 DAY, 1 UNION ALL
  SELECT 2, 'a0000000-0000-4000-8000-000000000002', 'A', 'VIP 감사 쿠폰', NOW() - INTERVAL 12 DAY, 1 UNION ALL
  SELECT 3, 'a0000000-0000-4000-8000-000000000002', 'D', '신규 회원 웰컴 쿠폰', NOW() - INTERVAL 60 DAY, 1 UNION ALL
  SELECT 3, 'a0000000-0000-4000-8000-000000000004', 'A', '등급 승급 축하 쿠폰', NOW() - INTERVAL 8 DAY, 1 UNION ALL
  SELECT 1, 'a0000000-0000-4000-8000-000000000005', 'A', '신규 회원 웰컴 쿠폰', NOW() - INTERVAL 2 DAY, 1
) c JOIN couponreftb r ON r.refno = c.refno;

-- ---------------------------------------------------------------------
-- 리뷰 / 좋아요 (박스오피스 영화 기준, data-movies.sql 의 movieno)
-- ---------------------------------------------------------------------

INSERT INTO reviewtb (uuid, movieno, star, review) VALUES
 ('a0000000-0000-4000-8000-000000000001','b20210087',5,'IMAX로 다시 봐도 압도적이네요. 사운드가 정말 대단합니다.'),
 ('a0000000-0000-4000-8000-000000000002','b20210087',4,'영상미는 최고! 원작을 몰라도 충분히 즐길 수 있어요.'),
 ('a0000000-0000-4000-8000-000000000004','b20210087',5,'몇 번을 봐도 좋은 영화. 극장에서 꼭 보세요.'),
 ('a0000000-0000-4000-8000-000000000002','b20167904',5,'재개봉 기다렸어요. 마지막 장면에서 또 울었습니다.'),
 ('a0000000-0000-4000-8000-000000000004','b20167904',4,'음악이 계속 귀에 맴돌아요.'),
 ('a0000000-0000-4000-8000-000000000001','b20264957',4,'보는 내내 손에 땀을 쥐었어요. 고소공포증 있으면 주의!'),
 ('a0000000-0000-4000-8000-000000000003','b20264957',3,'긴장감은 좋은데 전개가 조금 뻔했어요.'),
 ('a0000000-0000-4000-8000-000000000005','b20261807',5,'치이카와 너무 귀여워요ㅠㅠ 가족이랑 보기 좋아요.'),
 ('a0000000-0000-4000-8000-000000000003','b20259894',4,'반전이 인상적이었습니다. 배우들 연기 좋아요.'),
 ('a0000000-0000-4000-8000-000000000001','b20267697',4,'코난 팬이라면 무조건 봐야 할 극장판!');

INSERT INTO liketb (uuid, movieno) VALUES
 ('a0000000-0000-4000-8000-000000000001','b20210087'),('a0000000-0000-4000-8000-000000000001','b20264957'),('a0000000-0000-4000-8000-000000000001','b20267697'),
 ('a0000000-0000-4000-8000-000000000002','b20167904'),('a0000000-0000-4000-8000-000000000002','b20261807'),('a0000000-0000-4000-8000-000000000002','b20210087'),
 ('a0000000-0000-4000-8000-000000000003','b20259894'),('a0000000-0000-4000-8000-000000000003','b20264957'),
 ('a0000000-0000-4000-8000-000000000004','b20167904'),('a0000000-0000-4000-8000-000000000004','b20210087'),
 ('a0000000-0000-4000-8000-000000000005','b20261807');

-- ---------------------------------------------------------------------
-- 예매 내역 (지난 관람 / 다가오는 예매 / 취소)
-- 다가오는 예매의 회차(screentb)는 여기서 직접 넣는다. db/screens.sql 은 같은 슬롯을 건너뛰므로 잔여 좌석이 맞게 유지됨
-- reservenum 은 앱 형식 MMdd-HHmm-NNNN-NNN 을 따름
-- ---------------------------------------------------------------------

-- 시간은 screens.sql 슬롯 규칙(09:00 + 160분 간격 + 관별 10분)과 같게 맞춤
INSERT INTO screentb (areano, theaterno, movieno, viewday, roomno, pricetype, starttime, endtime, selecseat, totalseat) VALUES
 (1,1,'b20210087', CURDATE() + INTERVAL 2 DAY, 1, 2, TIMESTAMP(CURDATE() + INTERVAL 2 DAY, '17:00:00'), TIMESTAMP(CURDATE() + INTERVAL 2 DAY, '17:00:00') + INTERVAL 155 MINUTE, 180, 182),
 (1,3,'b20261807', CURDATE() + INTERVAL 4 DAY, 2, 2, TIMESTAMP(CURDATE() + INTERVAL 4 DAY, '11:50:00'), TIMESTAMP(CURDATE() + INTERVAL 4 DAY, '11:50:00') + INTERVAL 98 MINUTE, 179, 182);

INSERT INTO reservetb (uuid, reservenum, areano, theaterno, movieno, viewday, roomno, starttime, tmember, tprice, adate, status, mdate) VALUES
 ('a0000000-0000-4000-8000-000000000001', CONCAT(DATE_FORMAT(CURDATE() - INTERVAL 12 DAY,'%m%d'),'-1830-0001-001'), 1,1,'b20210087', CURDATE() - INTERVAL 10 DAY, 1, TIMESTAMP(CURDATE() - INTERVAL 10 DAY,'17:00:00'), 2, 30000, NOW() - INTERVAL 12 DAY, '예매', NULL),
 ('a0000000-0000-4000-8000-000000000001', CONCAT(DATE_FORMAT(CURDATE() - INTERVAL 6 DAY,'%m%d'),'-2110-0002-001'), 1,2,'b20264957', CURDATE() - INTERVAL 5 DAY, 3, TIMESTAMP(CURDATE() - INTERVAL 5 DAY,'14:40:00'), 1, 15000, NOW() - INTERVAL 6 DAY, '예매', NULL),
 ('a0000000-0000-4000-8000-000000000001', CONCAT(DATE_FORMAT(CURDATE(),'%m%d'),'-0910-0003-001'), 1,1,'b20210087', CURDATE() + INTERVAL 2 DAY, 1, TIMESTAMP(CURDATE() + INTERVAL 2 DAY,'17:00:00'), 2, 30000, NOW() - INTERVAL 1 HOUR, '예매', NULL),
 ('a0000000-0000-4000-8000-000000000001', CONCAT(DATE_FORMAT(CURDATE() - INTERVAL 3 DAY,'%m%d'),'-1520-0004-001'), 1,4,'b20259894', CURDATE() + INTERVAL 1 DAY, 2, TIMESTAMP(CURDATE() + INTERVAL 1 DAY,'17:10:00'), 1, 15000, NOW() - INTERVAL 3 DAY, '취소', NOW() - INTERVAL 2 DAY),
 ('a0000000-0000-4000-8000-000000000002', CONCAT(DATE_FORMAT(CURDATE() - INTERVAL 9 DAY,'%m%d'),'-1300-0005-001'), 2,3,'b20167904', CURDATE() - INTERVAL 8 DAY, 1, TIMESTAMP(CURDATE() - INTERVAL 8 DAY,'17:00:00'), 2, 27000, NOW() - INTERVAL 9 DAY, '예매', NULL),
 ('a0000000-0000-4000-8000-000000000002', CONCAT(DATE_FORMAT(CURDATE(),'%m%d'),'-1015-0006-001'), 1,3,'b20261807', CURDATE() + INTERVAL 4 DAY, 2, TIMESTAMP(CURDATE() + INTERVAL 4 DAY,'11:50:00'), 3, 39000, NOW() - INTERVAL 2 HOUR, '예매', NULL),
 ('a0000000-0000-4000-8000-000000000004', CONCAT(DATE_FORMAT(CURDATE() - INTERVAL 4 DAY,'%m%d'),'-2240-0007-001'), 6,1,'b20167904', CURDATE() - INTERVAL 3 DAY, 4, TIMESTAMP(CURDATE() - INTERVAL 3 DAY,'09:30:00'), 1, 11000, NOW() - INTERVAL 4 DAY, '예매', NULL);

-- 좌석 (취소된 예매는 deleteTicket 프로시저처럼 좌석 행이 없음)
INSERT INTO reserdtltb (uuid, reservenum, reserveno, areano, theaterno, movieno, roomno, viewday, starttime, priceno, price, seat, adate)
SELECT r.uuid, r.reservenum, s.no, r.areano, r.theaterno, r.movieno, r.roomno, r.viewday, r.starttime, s.priceno, s.price, s.seat, r.adate
FROM reservetb r
JOIN (
  SELECT '-0001-001' k, 1 no, 2 priceno, 15000 price, 'F7' seat UNION ALL SELECT '-0001-001', 2, 2, 15000, 'F8' UNION ALL
  SELECT '-0002-001', 1, 2, 15000, 'H10' UNION ALL
  SELECT '-0003-001', 1, 2, 15000, 'G7' UNION ALL SELECT '-0003-001', 2, 2, 15000, 'G8' UNION ALL
  SELECT '-0005-001', 1, 2, 15000, 'E5' UNION ALL SELECT '-0005-001', 2, 2, 12000, 'E6' UNION ALL
  SELECT '-0006-001', 1, 2, 15000, 'J4' UNION ALL SELECT '-0006-001', 2, 2, 12000, 'J5' UNION ALL SELECT '-0006-001', 3, 2, 12000, 'J6' UNION ALL
  SELECT '-0007-001', 1, 1, 11000, 'C9'
) s ON r.reservenum LIKE CONCAT('%', s.k)
WHERE r.status = '예매';
