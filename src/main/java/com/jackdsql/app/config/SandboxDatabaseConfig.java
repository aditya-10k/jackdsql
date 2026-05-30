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

    @Value("${spring.datasource.url}")
    private String dbUrl;

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
        dataSource.setUrl(dbUrl);
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
