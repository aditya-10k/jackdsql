package com.jackdsql.app.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;

@Configuration
public class SandboxDatabaseConfig {

    // Primary pooled URL (PgBouncer, port 6543) — used by Hibernate/JPA
    @Value("${spring.datasource.url}")
    private String primaryDbUrl;

    // Sandbox uses a DIRECT (non-pooled) Neon URL (port 5432) if provided.
    // This prevents session-level SET search_path from leaking back into the
    // PgBouncer pool and corrupting the next connection's search_path.
    // In HuggingFace Secrets set: SANDBOX_DATASOURCE_URL = <direct connection string>
    // Falls back to the primary URL if not configured.
    @Value("${sandbox.datasource.url:${spring.datasource.url}}")
    private String sandboxDbUrl;

    @Value("${sandbox.datasource.username:jackdsql_reader}")
    private String sandboxUsername;

    @Value("${sandbox.datasource.password:readonly_password123}")
    private String sandboxPassword;

    // Mark the default Spring datasource as @Primary so JPA/Hibernate always uses it
    @Primary
    @Bean(name = "dataSource")
    @ConfigurationProperties("spring.datasource")
    public DataSource primaryDataSource(DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder().build();
    }

    @Primary
    @Bean(name = "jdbcTemplate")
    public JdbcTemplate jdbcTemplate(@Qualifier("dataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

    @Bean(name = "sandboxDataSource")
    public DataSource sandboxDataSource() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setUrl(sandboxDbUrl);   // direct URL, not pooled
        dataSource.setUsername(sandboxUsername);
        dataSource.setPassword(sandboxPassword);
        return dataSource;
    }

    @Bean(name = "sandboxJdbcTemplate")
    public JdbcTemplate sandboxJdbcTemplate(@Qualifier("sandboxDataSource") DataSource dataSource) {
        JdbcTemplate template = new JdbcTemplate(dataSource);
        template.setQueryTimeout(3);
        return template;
    }
}
