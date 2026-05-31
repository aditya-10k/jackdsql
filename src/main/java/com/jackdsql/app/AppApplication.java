package com.jackdsql.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.Map;

@SpringBootApplication
public class AppApplication {

	public static void main(String[] args) {
		SpringApplication.run(AppApplication.class, args);
	}

	@Bean
	public CommandLineRunner initSearchPath(JdbcTemplate jdbcTemplate) {
		return args -> {
			try {
				// 1. Set default search_path database and role wide
				String dbName = jdbcTemplate.getDataSource().getConnection().getCatalog();
				jdbcTemplate.execute("ALTER ROLE CURRENT_USER SET search_path TO \"$user\", public");
				jdbcTemplate.execute("ALTER DATABASE " + dbName + " SET search_path TO \"$user\", public");
				
				// 2. Query and print current search_path
				String currentPath = jdbcTemplate.queryForObject("SHOW search_path", String.class);
				System.out.println("Startup Diagnostics: CURRENT SESSION search_path = " + currentPath);
				
				// 3. Check what schemas/tables exist
				List<Map<String, Object>> tables = jdbcTemplate.queryForList(
					"SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema')"
				);
				System.out.println("Startup Diagnostics: Existing tables count = " + tables.size());
				for (Map<String, Object> table : tables) {
					System.out.println("  - " + table.get("table_schema") + "." + table.get("table_name"));
				}
				
				// 4. Force search_path for the current connection if it's incorrect
				jdbcTemplate.execute("SET search_path TO \"$user\", public");
				System.out.println("Startup: Done running diagnostics and setting search_path session override.");
			} catch (Exception e) {
				System.err.println("Startup diagnostics error: " + e.getMessage());
			}
		};
	}
}
