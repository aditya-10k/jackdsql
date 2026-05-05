package com.jackdsql.app.service;

import com.jackdsql.app.dto.PreviewResponse;
import com.jackdsql.app.model.Question;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.*;

@Service
public class EvaluationService {

    private final JdbcTemplate sandboxJdbcTemplate;

    public EvaluationService(@Qualifier("sandboxJdbcTemplate") JdbcTemplate sandboxJdbcTemplate) {
        this.sandboxJdbcTemplate = sandboxJdbcTemplate;
    }

    public PreviewResponse getPreview(Question question, String userSql) {
        String executionId = "exec_" + UUID.randomUUID().toString().replace("-", "");

        try (Connection connection = sandboxJdbcTemplate.getDataSource().getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute("CREATE SCHEMA " + executionId);
            statement.execute("SET search_path TO " + executionId);

            statement.execute(question.getSchemaSql());
            String shieldedSql = "SELECT * FROM (" + userSql.replace(";", "") + ") AS user_query LIMIT 10";
            ResultSet resultSet = statement.executeQuery(shieldedSql);

            return extractPreviewData(resultSet);
        } catch (Exception e) {
            return new PreviewResponse(null, null, e.getMessage());
        } finally {
            cleanupSchema(executionId);
        }
    }

    public boolean compareResults(Question question, String userSql) {
        String executionId = "sud_" + UUID.randomUUID().toString().replace("-", "");

        try (Connection connection = sandboxJdbcTemplate.getDataSource().getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute("CREATE SCHEMA " + executionId);
            statement.execute("SET search_path TO " + executionId);
            statement.execute(question.getSchemaSql());

            ResultSet rs = statement.executeQuery(userSql);
            List<Map<String, String>> actual = normalize(extractResultsToList(rs));

            ResultSet solutionRs = statement.executeQuery(question.getSolutionQuery());
            List<Map<String, String>> expected = normalize(extractResultsToList(solutionRs));

            System.out.println("Expected: " + expected);
            System.out.println("Actual:   " + actual);

            return expected.equals(actual);
        } catch (Exception e) {
            System.err.println("Evaluation error: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            cleanupSchema(executionId);
        }
    }

    /**
     * Safely drops the temporary schema, ignoring any errors
     * (e.g. if the schema was never created due to an earlier failure).
     */
    private void cleanupSchema(String executionId) {
        try {
            sandboxJdbcTemplate.execute("DROP SCHEMA IF EXISTS " + executionId + " CASCADE");
        } catch (Exception e) {
            System.err.println("Schema cleanup warning (safe to ignore): " + e.getMessage());
        }
    }

    private List<Map<String, Object>> extractResultsToList(ResultSet rs) throws SQLException {
        List<Map<String, Object>> results = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        int cols = meta.getColumnCount();
        while (rs.next()) {
            Map<String, Object> row = new HashMap<>();
            for (int i = 1; i <= cols; i++) {
                row.put(meta.getColumnName(i), rs.getObject(i));
            }
            results.add(row);
        }
        return results;
    }

    private List<Map<String, String>> normalize(List<Map<String, Object>> list) {
        return list.stream().map(row -> {
            Map<String, String> normalizedRow = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
            row.forEach((key, value) -> {
                normalizedRow.put(key.toLowerCase().trim(), String.valueOf(value).trim());
            });
            return normalizedRow;
        }).toList();
    }

    private PreviewResponse extractPreviewData(ResultSet rs) throws SQLException {
        List<String> columns = new ArrayList<>();
        List<Map<String, Object>> rows = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        for (int i = 1; i <= meta.getColumnCount(); i++) columns.add(meta.getColumnName(i));
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (String col : columns) row.put(col, rs.getObject(col));
            rows.add(row);
        }
        return new PreviewResponse(columns, rows, null);
    }
}
