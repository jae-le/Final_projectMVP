package com.boot.Config;

import java.io.File;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.util.FileSystemUtils;

import ch.vorburger.exec.ManagedProcessException;
import ch.vorburger.mariadb4j.DB;
import ch.vorburger.mariadb4j.DBConfigurationBuilder;

/**
 * 내장 MariaDB 설정.
 *
 * 앱을 실행하면 MariaDB가 함께 기동되므로 별도의 DB 설치 없이 실행할 수 있다.
 * - 데이터는 {@code mvp.embedded-db.data-dir}(기본: ./db-data)에 저장되어 재시작해도 유지된다.
 * - 최초 기동 시(데이터 폴더에 DB가 없을 때)만 classpath의 db/schema.sql, db/data-movies.sql, db/data.sql 을 실행한다.
 * - 기동할 때마다 db/screens.sql 을 실행해 오늘부터 21일치 상영 시간표를 채운다
 *   (예매 화면은 "지금 이후 ~ 21일 이내" 상영만 보여주므로 고정 날짜 데이터는 금방 사라지기 때문).
 * - DB를 초기화하려면 앱을 끄고 db-data 폴더를 삭제한 뒤 다시 실행하면 된다.
 *   (강제 종료로 mysqld 프로세스가 남아 있으면 먼저 종료해야 폴더가 지워진다)
 *
 * 외부 MySQL(예: 팀 공용 DB)을 쓰려면 mvp.embedded-db.enabled=false 로 두고
 * spring.datasource.url 을 해당 DB로 바꾸면 된다.
 */
@Configuration
@ConditionalOnProperty(name = "mvp.embedded-db.enabled", havingValue = "true", matchIfMissing = true)
public class EmbeddedMariaDbConfig {

	private static final Logger log = LoggerFactory.getLogger(EmbeddedMariaDbConfig.class);

	@Value("${mvp.embedded-db.port:13307}")
	private int port;

	@Value("${mvp.embedded-db.data-dir:./db-data}")
	private String dataDir;

	@Value("${mvp.embedded-db.name:mvpdb}")
	private String dbName;

	@Bean(destroyMethod = "stop")
	public EmbeddedDb embeddedMariaDb() throws ManagedProcessException {
		File root = new File(dataDir).getAbsoluteFile();
		File data = new File(root, "data");
		boolean fresh = !new File(data, dbName).isDirectory();

		if (isPortInUse(port)) {
			if (!fresh) {
				// IDE 의 강제 종료(Eclipse 빨간 정지 버튼 등)로 이전 실행의 DB 프로세스가 남아 있는 경우 그대로 재사용한다.
				log.warn("Port {} is already in use - reusing the embedded MariaDB left over from a previous run.", port);
				return new EmbeddedDb(null);
			}
			throw new IllegalStateException("내장 DB 포트 " + port + " 를 다른 프로그램이 사용 중입니다. "
					+ "application.properties 의 mvp.embedded-db.port 와 spring.datasource.url 의 포트를 함께 바꿔주세요.");
		}

		DBConfigurationBuilder config = DBConfigurationBuilder.newBuilder();
		// 함께 포함된 바이너리 버전 (build.gradle 의 mariaDB4j-db-* 와 일치해야 함)
		config.setDatabaseVersion(config.isWindows() ? "mariadb-10.11.5-fix1"
				: config.isMacOS() ? "mariadb-10.2.11" : "mariadb-10.11.5");
		config.setPort(port);
		config.setBaseDir(new File(root, "base"));
		config.setDataDir(data);
		config.setTmpDir(new File(root, "tmp").getPath());
		config.setDeletingTemporaryBaseAndDataDirsOnShutdown(false);
		config.setDefaultCharacterSet("utf8mb4");
		config.addArg("--character-set-server=utf8mb4");
		config.addArg("--collation-server=utf8mb4_general_ci");
		// 매퍼의 테이블명 대소문자가 OS와 무관하게 동일하게 동작하도록 함
		config.addArg("--lower_case_table_names=1");
		// 인증 없이 동작하므로 외부 접속은 막는다
		config.addArg("--bind-address=127.0.0.1");
		// 역설계한 스키마라 NOT NULL/기본값이 원본과 다를 수 있어 엄격 모드는 끈다
		config.addArg("--sql-mode=NO_ENGINE_SUBSTITUTION");
		config.addArg("--default-time-zone=+09:00");

		log.info("Starting embedded MariaDB on port {} (data: {})", port, data);
		DB db = DB.newEmbeddedDB(config.build());
		db.start();

		if (fresh) {
			log.info("Initializing database '{}' from db/schema.sql, db/data-movies.sql, db/data.sql", dbName);
			try {
				db.createDB(dbName);
				db.source("db/schema.sql", "root", null, dbName);
				db.source("db/data-movies.sql", "root", null, dbName);
				db.source("db/data.sql", "root", null, dbName);
			} catch (ManagedProcessException | RuntimeException e) {
				// 초기화가 중간에 실패하면 다음 실행 때 다시 초기화되도록 데이터 폴더를 지운다
				db.stop();
				FileSystemUtils.deleteRecursively(data);
				throw e;
			}
		}
		return new EmbeddedDb(db);
	}

	/** 기동할 때마다 상영 시간표를 오늘 기준으로 채우고, 이전 실행에서 남은 임시 좌석 점유를 지운다. */
	@Bean
	public ApplicationRunner refreshScreenSchedule(DataSource dataSource) {
		return args -> {
			ResourceDatabasePopulator populator = new ResourceDatabasePopulator(new ClassPathResource("db/screens.sql"));
			populator.setSqlScriptEncoding("UTF-8");
			populator.execute(dataSource);
			log.info("Screen schedule refreshed for the next 21 days (db/screens.sql)");
		};
	}

	private static boolean isPortInUse(int port) {
		try (Socket socket = new Socket()) {
			socket.connect(new InetSocketAddress("127.0.0.1", port), 500);
			return true;
		} catch (IOException e) {
			return false;
		}
	}

	/** 직접 띄운 DB만 종료하기 위한 래퍼 (재사용한 DB는 건드리지 않음). */
	public static class EmbeddedDb {
		private final DB db;

		EmbeddedDb(DB db) {
			this.db = db;
		}

		public void stop() throws ManagedProcessException {
			if (db != null) {
				db.stop();
			}
		}
	}

	/** 내장 DB가 완전히 뜬 뒤에 커넥션 풀이 만들어지도록 DB 빈에 의존시킨다. */
	@Bean
	@Primary
	public DataSource dataSource(EmbeddedDb embeddedMariaDb, DataSourceProperties properties) {
		return properties.initializeDataSourceBuilder().build();
	}
}
