-- =====================================================================
-- mvpdb 스키마 (MyBatis 매퍼/DTO 기반 역설계본)
--
-- 원본 DB 덤프가 없어 src/main/resources/mybatis/mappers/*.xml, DTO, 서비스 코드를 보고 재구성했다.
-- 컬럼 타입/길이/기본값, 뷰/프로시저 본문은 추정치이므로 원본과 다를 수 있다.
-- 내장 MariaDB 최초 기동 시 Config/EmbeddedMariaDbConfig 가 이 파일을 실행한다.
-- Spring Batch 메타 테이블(BATCH_*)은 spring.batch.jdbc.initialize-schema=always 로 Spring 이 만든다.
--
-- 참고
-- - "uuid" 가 모든 회원 관련 테이블의 키다 (usertb 또는 oauthtb 에 있음). FK 는 걸지 않았다.
-- - 대부분 DTO 에 있는 adate/mdate/fld* (예비 컬럼)은 실제로 쓰이는 테이블에만 넣었다.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 회원
-- ---------------------------------------------------------------------

-- 일반 회원 (폼 로그인: userid / ppass(BCrypt))
CREATE TABLE usertb (
  userid  VARCHAR(50)  NOT NULL,
  uuid    VARCHAR(36)  NOT NULL,
  ppass   VARCHAR(100) NOT NULL,
  pname   VARCHAR(50)  NOT NULL,
  email   VARCHAR(100) NOT NULL,
  phone   VARCHAR(20)  NULL,             -- 010-1234-5678
  birth   DATE         NULL,
  gender  INT          NOT NULL DEFAULT 0, -- 1 남 / 2 여
  certno  INT          NULL DEFAULT 0,
  account VARCHAR(100) NULL,             -- 환불 계좌
  adate   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (userid),
  UNIQUE KEY uk_usertb_uuid (uuid),
  UNIQUE KEY uk_usertb_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 네이버 OAuth 회원
CREATE TABLE oauthtb (
  oauthid   BIGINT       NOT NULL AUTO_INCREMENT,
  oauthdiff VARCHAR(20)  NOT NULL,          -- naver
  oauthuniq VARCHAR(100) NOT NULL,          -- 네이버 response.id
  userid    VARCHAR(50)  NOT NULL,
  uuid      VARCHAR(36)  NOT NULL,
  pname     VARCHAR(50)  NULL,
  email     VARCHAR(100) NULL,
  phone     VARCHAR(20)  NULL,
  birth     DATE         NULL,
  gender    INT          NOT NULL DEFAULT 0,
  account   VARCHAR(100) NULL,
  adate     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (oauthid),
  UNIQUE KEY uk_oauth_uniq (oauthuniq),
  UNIQUE KEY uk_oauth_userid (userid),
  UNIQUE KEY uk_oauth_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 멤버십: 등급 / 포인트 / 마일리지 / 포인트 이력 / 출석
-- ---------------------------------------------------------------------

CREATE TABLE gradetb (
  uuid         VARCHAR(36) NOT NULL,
  grade        VARCHAR(10) NOT NULL DEFAULT 'Welcome',  -- Welcome / Friend / VIP / MVP
  current_year INT         NULL,
  PRIMARY KEY (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE point (
  uuid  VARCHAR(36) NOT NULL,
  onhqt INT         NOT NULL DEFAULT 0,   -- 보유
  recqt INT         NOT NULL DEFAULT 0,   -- 누적 적립
  issqt INT         NOT NULL DEFAULT 0,   -- 누적 사용
  adate DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE mileage (
  uuid  VARCHAR(36) NOT NULL,
  recqt INT         NOT NULL DEFAULT 0,   -- 이번 달 적립
  onhqt INT         NOT NULL DEFAULT 0,   -- 전체 누적 (등급 산정 기준)
  adate DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- pthistno 는 앱이 pt{yymmdd}-{NNNN} 형식으로 채번
CREATE TABLE pthisttb (
  pthistno    VARCHAR(20)  NOT NULL,
  uuid        VARCHAR(36)  NOT NULL,
  kind        VARCHAR(10)  NOT NULL,          -- 적립 / 사용 / 소멸
  description VARCHAR(100) NULL,
  recqt       INT          NOT NULL DEFAULT 0,
  issqt       INT          NOT NULL DEFAULT 0,
  trndt       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pthistno),
  KEY idx_pthist_uuid (uuid),
  KEY idx_pthist_trndt (trndt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE attendance (
  id     INT         NOT NULL AUTO_INCREMENT,
  uuid   VARCHAR(36) NOT NULL,
  adate  DATE        NOT NULL,
  points INT         NULL DEFAULT 10,
  PRIMARY KEY (id),
  UNIQUE KEY uk_attendance_day (uuid, adate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 쿠폰
-- ---------------------------------------------------------------------

-- 쿠폰 정의 (기준 데이터). type C=관람권, D=할인권. refno 1(생일), 4(출석 만근)는 코드에 고정
CREATE TABLE couponreftb (
  refno   INT          NOT NULL,
  type    CHAR(1)      NOT NULL,
  name    VARCHAR(50)  NOT NULL,
  benefit VARCHAR(100) NULL,
  period  INT          NOT NULL DEFAULT 30,   -- 유효기간(일)
  PRIMARY KEY (refno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- couponno 는 앱이 {type}{yymmdd}-{NNNN} 형식으로 채번. acrec N=미등록 / A=사용가능 / D=사용완료
CREATE TABLE coupontb (
  couponno VARCHAR(20)  NOT NULL,
  refno    INT          NOT NULL,
  uuid     VARCHAR(36)  NOT NULL,
  acrec    CHAR(1)      NOT NULL DEFAULT 'N',
  endDate  DATETIME     NULL,
  reason   VARCHAR(100) NULL,
  adate    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate    DATETIME     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (couponno),
  KEY idx_coupon_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 장르 / 선호 장르
-- ---------------------------------------------------------------------

-- genrenm 은 TMDB 한국어 장르명과 같아야 함 (movietb.genre 를 FIND_IN_SET 으로 필터)
CREATE TABLE genre (
  genreno INT         NOT NULL,
  genrenm VARCHAR(30) NOT NULL,
  PRIMARY KEY (genreno),
  UNIQUE KEY uk_genre_nm (genrenm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 선호 장르 원본 테이블 (마이페이지에서 읽고 수정)
CREATE TABLE selecgenretb (
  id           INT         NOT NULL AUTO_INCREMENT,
  uuid         VARCHAR(36) NOT NULL,
  genrenm      VARCHAR(30) NOT NULL,
  origin_table VARCHAR(10) NULL,      -- user / oauth
  PRIMARY KEY (id),
  KEY idx_selecgenre_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 회원가입 시에는 아래 두 이름으로 INSERT 한다 -> 같은 테이블에 쌓이도록 단일 테이블 뷰로 만든다
CREATE VIEW userselecgenretb  AS SELECT uuid, genrenm FROM selecgenretb;
CREATE VIEW oauthselecgenretb AS SELECT uuid, genrenm FROM selecgenretb;

-- ---------------------------------------------------------------------
-- 영화
-- ---------------------------------------------------------------------

-- TMDB 기반 영화 (배치가 채움). movieno = TMDB id
CREATE TABLE movietb (
  movieno      VARCHAR(20)  NOT NULL,
  movienm      VARCHAR(200) NOT NULL,
  movieen      VARCHAR(200) NULL,
  moviebackimg VARCHAR(255) NULL,
  moviepostimg VARCHAR(255) NULL,
  movieyoutube VARCHAR(255) NULL,
  steelcut     TEXT         NULL,          -- 콤마 구분 이미지 URL
  releaseday   DATE         NULL,
  intro        TEXT         NULL,
  ratingno     VARCHAR(50)  NULL,          -- 전체관람가 / 12세이상관람가 / 15세이상관람가 / 청소년관람불가
  directornm   VARCHAR(500) NULL,
  actor        TEXT         NULL,
  genre        VARCHAR(255) NULL,          -- 콤마 구분, 공백 없음 (FIND_IN_SET)
  times        INT          NOT NULL DEFAULT 0,
  endday       DATE         NULL,
  moviestatus  INT          NOT NULL DEFAULT 1,   -- 1 이어야 화면에 노출
  adate        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate        DATETIME     NULL,
  PRIMARY KEY (movieno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- KOBIS 일별 박스오피스 + TMDB 보강 (배치가 채움). movieno = 'b' + KOBIS movieCd
CREATE TABLE boxofficetb (
  movieno      VARCHAR(20)  NOT NULL,
  movienm      VARCHAR(200) NOT NULL,
  directornm   VARCHAR(500) NULL,
  releaseday   DATE         NULL,
  ratingno     VARCHAR(100) NULL,
  times        INT          NOT NULL DEFAULT 0,
  intro        TEXT         NULL,
  moviebackimg VARCHAR(255) NULL,
  moviepostimg VARCHAR(255) NULL,
  movieyoutube VARCHAR(255) NULL,
  steelcut     TEXT         NULL,
  genre        VARCHAR(255) NULL,
  actor        TEXT         NULL,
  salesAcc     VARCHAR(30)  NULL,
  audiAcc      INT          NULL,
  ranking      INT          NULL,
  status       VARCHAR(20)  NULL,          -- 개봉 / 개봉예정
  typeNm       VARCHAR(20)  NULL,
  showType     VARCHAR(255) NULL,
  PRIMARY KEY (movieno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 박스오피스 + TMDB 영화를 제목 기준으로 합친 목록 (매퍼 4곳에 인라인된 UNION 과 같은 규칙)
CREATE VIEW movieinfotb_v AS
SELECT MAX(movieno)      AS movieno,
       movienm,
       MAX(movieen)      AS movieen,
       MAX(ranking)      AS ranking,
       MAX(directornm)   AS directornm,
       MIN(releaseday)   AS releaseday,
       MAX(endday)       AS endday,
       MAX(salesAcc)     AS salesAcc,
       MAX(audiAcc)      AS audiAcc,
       MAX(times)        AS times,
       MAX(intro)        AS intro,
       MAX(status)       AS status,
       MAX(typeNm)       AS typeNm,
       MAX(genre)        AS genre,
       MAX(actor)        AS actor,
       MAX(showType)     AS showType,
       moviestatus,
       MAX(ratingno)     AS ratingno,
       MAX(moviebackimg) AS moviebackimg,
       MAX(moviepostimg) AS moviepostimg,
       MAX(movieyoutube) AS movieyoutube,
       MAX(steelcut)     AS steelcut
FROM (
    SELECT movieno, movienm, NULL AS movieen, ranking, directornm, releaseday,
           CAST('9999-12-31' AS DATE) AS endday, salesAcc, audiAcc, times, intro, status, typeNm,
           genre, actor, showType, 1 AS moviestatus, ratingno, moviebackimg, moviepostimg, movieyoutube, steelcut
    FROM boxofficetb
    UNION ALL
    SELECT movieno, movienm, movieen, NULL, directornm, releaseday,
           endday, NULL, NULL, times, intro, NULL, NULL,
           genre, actor, NULL, moviestatus, ratingno, moviebackimg, moviepostimg, movieyoutube, steelcut
    FROM movietb WHERE moviestatus = 1
) a
GROUP BY movienm, moviestatus;

-- screentb_2.xml 의 사용되지 않는 쿼리(selecthdr)가 참조하는 이름
CREATE VIEW movietb2 AS SELECT * FROM movieinfotb_v;

CREATE TABLE liketb (
  uuid    VARCHAR(36) NOT NULL,
  movieno VARCHAR(20) NOT NULL,
  PRIMARY KEY (uuid, movieno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reviewtb (
  uuid    VARCHAR(36)   NOT NULL,
  movieno VARCHAR(20)   NOT NULL,
  star    INT           NOT NULL,
  review  VARCHAR(1000) NULL,
  PRIMARY KEY (uuid, movieno),
  KEY idx_review_movie (movieno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 극장 / 상영
-- ---------------------------------------------------------------------

CREATE TABLE areatb (
  areano INT         NOT NULL,
  areanm VARCHAR(50) NOT NULL,
  adate  DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
  mdate  DATETIME    NULL,
  PRIMARY KEY (areano)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE theatertb (
  areano    INT         NOT NULL,
  theaterno INT         NOT NULL,
  theaternm VARCHAR(50) NOT NULL,
  adate     DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
  mdate     DATETIME    NULL,
  PRIMARY KEY (areano, theaterno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 상영 시간표. starttime 은 소수초 없는 DATETIME 이어야 함 (앱이 문자열로 파싱)
-- pricetype 1=조조, 2=일반. 좌석은 A~M x 1~14 = 182석 (코드에 고정)
CREATE TABLE screentb (
  areano    INT         NOT NULL,
  theaterno INT         NOT NULL,
  movieno   VARCHAR(20) NOT NULL,
  viewday   DATE        NOT NULL,
  roomno    INT         NOT NULL,
  pricetype INT         NOT NULL,
  starttime DATETIME    NOT NULL,
  endtime   DATETIME    NOT NULL,
  selecseat INT         NOT NULL,   -- 잔여 좌석
  totalseat INT         NOT NULL,
  adate     DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
  mdate     DATETIME    NULL,
  PRIMARY KEY (areano, theaterno, movieno, viewday, roomno, starttime),
  UNIQUE KEY uk_screen_slot (areano, theaterno, roomno, starttime),
  KEY idx_screen_day (areano, theaterno, viewday)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 가격: pricetype 두 자리 = (screentb.pricetype)(관객유형 1성인 2청소년 3경로 4장애인)
-- 앱이 유형별로 정확히 4행을 이 순서로 읽는다
CREATE TABLE pricetb (
  pricetype INT         NOT NULL,
  typenm    VARCHAR(20) NULL,
  pricenm   VARCHAR(20) NULL,
  nowprice  INT         NOT NULL,
  adate     DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
  mdate     DATETIME    NULL,
  PRIMARY KEY (pricetype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 예매
-- ---------------------------------------------------------------------

-- 예매 헤더. reservenum 은 브라우저가 MMdd-HHmm-NNNN-NNN 형식으로 생성
CREATE TABLE reservetb (
  uuid       VARCHAR(36)  NOT NULL,
  reservenum VARCHAR(20)  NOT NULL,
  areano     INT          NOT NULL,
  theaterno  INT          NOT NULL,
  movieno    VARCHAR(20)  NOT NULL,
  viewday    DATE         NOT NULL,
  roomno     INT          NOT NULL,
  starttime  DATETIME     NOT NULL,
  tmember    INT          NOT NULL,
  tprice     INT          NOT NULL,
  adate      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate      DATETIME     NULL,
  status     VARCHAR(10)  NOT NULL DEFAULT '예매',   -- 예매 / 취소
  fldaa      VARCHAR(100) NULL,
  fldab      VARCHAR(100) NULL,
  fldac      VARCHAR(100) NULL,
  fldad      VARCHAR(100) NULL,
  fldna      INT          NULL,
  fldnb      INT          NULL,
  fldnc      INT          NULL,
  fldnd      INT          NULL,
  PRIMARY KEY (reservenum),
  KEY idx_reserve_user (uuid, status, viewday)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 예매 좌석 (좌석당 1행). reserveno 는 예매 안에서 max+1
CREATE TABLE reserdtltb (
  uuid       VARCHAR(36) NOT NULL,
  reservenum VARCHAR(20) NOT NULL,
  reserveno  INT         NOT NULL,
  areano     INT         NOT NULL,
  theaterno  INT         NOT NULL,
  movieno    VARCHAR(20) NOT NULL,
  roomno     INT         NOT NULL,
  viewday    DATE        NOT NULL,
  starttime  DATETIME    NOT NULL,
  priceno    INT         NOT NULL,
  price      INT         NOT NULL,
  seat       VARCHAR(4)  NOT NULL,      -- A1 ~ M14
  adate      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mdate      DATETIME    NULL,
  status     VARCHAR(10) NOT NULL DEFAULT '예매',
  PRIMARY KEY (uuid, reservenum, reserveno),
  KEY idx_reserdtl_screen (areano, theaterno, movieno, viewday, roomno, starttime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 좌석 선택 후 결제 전 임시 점유 (10분 뒤 앱이 삭제)
CREATE TABLE reserdtltmptb (
  uuid      VARCHAR(36) NOT NULL,
  idno      INT         NOT NULL,
  reserveno INT         NOT NULL,
  areano    INT         NOT NULL,
  theaterno INT         NOT NULL,
  movieno   VARCHAR(20) NOT NULL,
  viewday   DATE        NOT NULL,
  roomno    INT         NOT NULL,
  starttime DATETIME    NOT NULL,
  seat      VARCHAR(4)  NOT NULL,
  adate     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (uuid, idno, reserveno),
  KEY idx_reserdtltmp_screen (areano, theaterno, movieno, viewday, roomno, starttime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 저장 프로시저 (원본 본문이 저장소에 없어 동작을 추정해 재구성)
-- ---------------------------------------------------------------------

DELIMITER //

-- 결제 시 포인트 사용/적립 + 마일리지/등급 갱신. 적립률은 등급별 3/5/7/10% (membership.jsp 안내 기준)
CREATE PROCEDURE movie_payment_points(IN p_uuid VARCHAR(36), IN p_t_point INT, IN p_t_calc INT)
BEGIN
  DECLARE v_grade VARCHAR(10);
  DECLARE v_rate DECIMAL(4,2);
  DECLARE v_seq INT;

  SELECT grade INTO v_grade FROM gradetb WHERE uuid = p_uuid;
  SET v_rate = CASE v_grade WHEN 'MVP' THEN 0.10 WHEN 'VIP' THEN 0.07 WHEN 'Friend' THEN 0.05 ELSE 0.03 END;

  IF IFNULL(p_t_point, 0) > 0 THEN
    SELECT COUNT(*) + 1 INTO v_seq FROM pthisttb WHERE DATE(trndt) = CURDATE();
    INSERT INTO pthisttb (pthistno, description, kind, recqt, issqt, uuid)
    VALUES (CONCAT('pt', DATE_FORMAT(NOW(), '%y%m%d'), '-', LPAD(v_seq, 4, '0')), '관람권구매 포인트사용', '사용', 0, p_t_point, p_uuid);
  END IF;

  IF FLOOR(IFNULL(p_t_calc, 0) * v_rate) > 0 THEN
    SELECT COUNT(*) + 1 INTO v_seq FROM pthisttb WHERE DATE(trndt) = CURDATE();
    INSERT INTO pthisttb (pthistno, description, kind, recqt, issqt, uuid)
    VALUES (CONCAT('pt', DATE_FORMAT(NOW(), '%y%m%d'), '-', LPAD(v_seq, 4, '0')), '관람권구매 포인트적립', '적립', FLOOR(p_t_calc * v_rate), 0, p_uuid);
  END IF;

  UPDATE point p
    JOIN (SELECT uuid, SUM(recqt) r, SUM(issqt) i FROM pthisttb WHERE uuid = p_uuid GROUP BY uuid) h ON p.uuid = h.uuid
     SET p.recqt = h.r, p.issqt = h.i, p.onhqt = h.r - h.i, p.mdate = NOW();

  UPDATE mileage m
    JOIN (SELECT uuid,
                 SUM(CASE WHEN YEAR(trndt) = YEAR(CURDATE()) AND MONTH(trndt) = MONTH(CURDATE()) THEN recqt ELSE 0 END) mr,
                 SUM(recqt) mo
            FROM pthisttb WHERE uuid = p_uuid GROUP BY uuid) h ON m.uuid = h.uuid
     SET m.recqt = h.mr, m.onhqt = h.mo, m.mdate = NOW();

  UPDATE gradetb g JOIN mileage m ON g.uuid = m.uuid AND m.uuid = p_uuid
     SET g.grade = CASE WHEN m.onhqt >= 12000 THEN 'MVP' WHEN m.onhqt >= 9600 THEN 'VIP'
                        WHEN m.onhqt >= 7800 THEN 'Friend' ELSE g.grade END;
END //

-- 예매 취소: 좌석 수 반환 + 상태 변경 + 좌석 행 삭제(다시 선택 가능하도록)
-- (원본의 포인트 환급 규칙은 알 수 없어 포함하지 않음)
CREATE PROCEDURE deleteTicket(IN v_uuid VARCHAR(36), IN v_reservenum VARCHAR(20))
BEGIN
  UPDATE screentb s
    JOIN reservetb r ON s.areano = r.areano AND s.theaterno = r.theaterno AND s.movieno = r.movieno
                    AND s.viewday = r.viewday AND s.roomno = r.roomno AND s.starttime = r.starttime
     SET s.selecseat = LEAST(s.totalseat, s.selecseat + r.tmember)
   WHERE r.uuid = v_uuid AND r.reservenum = v_reservenum AND r.status = '예매';

  UPDATE reservetb SET status = '취소', mdate = NOW() WHERE uuid = v_uuid AND reservenum = v_reservenum;
  DELETE FROM reserdtltb WHERE uuid = v_uuid AND reservenum = v_reservenum;
END //

DELIMITER ;
