package com.jackdsql.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
public class AppApplication {

	public static void main(String[] args) {
		SpringApplication.run(AppApplication.class, args);
	}

	@Bean
	public CommandLineRunner initSearchPath(JdbcTemplate jdbcTemplate) {
		return args -> {
			try {
				jdbcTemplate.execute("ALTER ROLE CURRENT_USER RESET search_path");
				jdbcTemplate.execute("ALTER DATABASE " + jdbcTemplate.getDataSource().getConnection().getCatalog() + " RESET search_path");
				System.out.println("Startup: Successfully reset search_path for user and database.");
			} catch (Exception e) {
				System.err.println("Startup search_path reset warning: " + e.getMessage());
			}
		};
	}
}
