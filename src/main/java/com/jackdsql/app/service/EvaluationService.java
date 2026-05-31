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

    private void validateQuery(String userSql) {
        if (userSql == null) return;
        String upper = userSql.toUpperCase();
        if (upper.contains("ALTER ROLE") ||
            upper.contains("ALTER DATABASE") ||
            upper.contains("ALTER SYSTEM") ||
            upper.contains("DROP DATABASE") ||
            upper.contains("DROP ROLE") ||
            upper.contains("CREATE ROLE") ||
            upper.contains("GRANT ") ||
            upper.contains("REVOKE ") ||
            upper.contains("SET SEARCH_PATH") ||
            upper.contains("DROP SCHEMA")) {
            throw new IllegalArgumentException("Unauthorized query: Schema/role altering commands are rejected.");
        }
    }

    public PreviewResponse getOpenPlaygroundPreview(String userSql){
        validateQuery(userSql);
        String executionId = "play_" + UUID.randomUUID().toString().replace("-","");

        try(Connection connection = sandboxJdbcTemplate.getDataSource().getConnection();
            Statement statement = connection.createStatement()) {

            statement.execute("CREATE SCHEMA " + executionId);
            statement.execute("SET search_path TO " + executionId);

            PreviewResponse result;
            try {
                String [] queries = userSql.split(";");
                ResultSet resultSet = null ;

                for(String query : queries){
                    String cleanQuery = query.trim();
                    if(cleanQuery.isEmpty()) continue;

                    if(cleanQuery.toUpperCase().startsWith("SELECT")){
                        String sheildedSql = "SELECT * FROM (" + cleanQuery + ") AS playground_query LIMIT 50";
                        resultSet = statement.executeQuery(sheildedSql);
                    }
                    else{
                        statement.execute(cleanQuery);
                    }
                }

                if(resultSet != null){
                    PreviewResponse response = extractPreviewData(resultSet);

                    List<Map<String, Object>> rawRows = response.rows();
                    List<Map<String, Object>> extractedResults = new ArrayList<>();
                    for (Map<String, Object> row : rawRows) {
                        extractedResults.add(new LinkedHashMap<>(row));
                    }

                    List<Map<String, String>> normalizedStringRows = normalize(extractedResults);

                    List<Map<String, Object>> finalRows = new ArrayList<>();
                    for (Map<String, String> normalizedRow : normalizedStringRows) {
                        finalRows.add(new LinkedHashMap<>(normalizedRow));
                    }

                    result = new PreviewResponse(response.columns(), finalRows, null);
                } else {
                    result = new PreviewResponse(new ArrayList<>(), new ArrayList<>(), "Queries executed successfully , but no data was returned");
                }
            } catch (Exception userEx) {
                result = new PreviewResponse(null, null, userEx.getMessage());
            } finally {
                // CRITICAL: Always reset search_path on this connection before it's returned
                // to PgBouncer's pool. If omitted, the next borrower (e.g. register/login)
                // gets a connection whose search_path points at the already-dropped sandbox
                // schema, causing 'relation "users" does not exist'.
                try { statement.execute("SET search_path TO \"$user\", public"); } catch (Exception ignored) {}
            }
            return result;
        }
        catch (Exception e){
            return new PreviewResponse(null,null,e.getMessage());
        }
        finally {
            cleanupSchema(executionId);
        }
    }

    public EvaluationService(@Qualifier("sandboxJdbcTemplate") JdbcTemplate sandboxJdbcTemplate) {
        this.sandboxJdbcTemplate = sandboxJdbcTemplate;
    }

    public PreviewResponse getPreview(Question question, String userSql) {
        validateQuery(userSql);
        String executionId = "exec_" + UUID.randomUUID().toString().replace("-", "");

        try (Connection connection = sandboxJdbcTemplate.getDataSource().getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute("CREATE SCHEMA " + executionId);
            statement.execute("SET search_path TO " + executionId);

            PreviewResponse result;
            try {
                if (question.getSchemaSql() != null && !question.getSchemaSql().trim().isEmpty()) {
                    statement.execute(question.getSchemaSql());
                }

                String [] queries = userSql.split(";");
                ResultSet resultSet = null;

                for (String query : queries) {
                    String cleanQuery = query.trim();
                    if (cleanQuery.isEmpty()) continue;

                    if (cleanQuery.toUpperCase().startsWith("SELECT")) {
                        String shieldedSql = "SELECT * FROM (" + cleanQuery + ") AS user_query LIMIT 10";
                        resultSet = statement.executeQuery(shieldedSql);
                    } else {
                        statement.execute(cleanQuery);
                    }
                }

                if (resultSet != null) {
                    result = extractPreviewData(resultSet);
                } else {
                    result = new PreviewResponse(new ArrayList<>(), new ArrayList<>(), "Queries executed successfully, but no data was returned");
                }
            } catch (Exception userEx) {
                result = new PreviewResponse(null, null, userEx.getMessage());
            } finally {
                // Always reset search_path before returning connection to PgBouncer pool
                try { statement.execute("SET search_path TO \"$user\", public"); } catch (Exception ignored) {}
            }
            return result;
        } catch (Exception e) {
            return new PreviewResponse(null, null, e.getMessage());
        } finally {
            cleanupSchema(executionId);
        }
    }

    public boolean compareResults(Question question, String userSql) {
        validateQuery(userSql);
        String executionIdActual = "sud_act_" + UUID.randomUUID().toString().replace("-", "");
        String executionIdExpected = "sud_exp_" + UUID.randomUUID().toString().replace("-", "");

        try (Connection connection = sandboxJdbcTemplate.getDataSource().getConnection();
             Statement statement = connection.createStatement()) {

            boolean result;
            try {
                // Execute User Query in actual schema
                statement.execute("CREATE SCHEMA " + executionIdActual);
                statement.execute("SET search_path TO " + executionIdActual);
                if (question.getSchemaSql() != null && !question.getSchemaSql().trim().isEmpty()) {
                    statement.execute(question.getSchemaSql());
                }
                List<Map<String, String>> actual = normalize(executeSequentiallyAndGetResults(statement, userSql));

                // Execute Solution Query in expected schema
                statement.execute("CREATE SCHEMA " + executionIdExpected);
                statement.execute("SET search_path TO " + executionIdExpected);
                if (question.getSchemaSql() != null && !question.getSchemaSql().trim().isEmpty()) {
                    statement.execute(question.getSchemaSql());
                }
                List<Map<String, String>> expected = normalize(executeSequentiallyAndGetResults(statement, question.getSolutionQuery()));

                // Sort rows to make comparison order-independent
                Comparator<Map<String, String>> rowComparator = (a, b) -> a.toString().compareTo(b.toString());
                actual.sort(rowComparator);
                expected.sort(rowComparator);

                System.out.println("Expected: " + expected);
                System.out.println("Actual:   " + actual);

                result = expected.equals(actual);
            } catch (Exception evalEx) {
                System.err.println("Evaluation error: " + evalEx.getMessage());
                evalEx.printStackTrace();
                result = false;
            } finally {
                // Always reset search_path before returning connection to PgBouncer pool
                try { statement.execute("SET search_path TO \"$user\", public"); } catch (Exception ignored) {}
            }
            return result;
        } catch (Exception e) {
            System.err.println("Evaluation error: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            cleanupSchema(executionIdActual);
            cleanupSchema(executionIdExpected);
        }
    }

    private List<Map<String, Object>> executeSequentiallyAndGetResults(Statement statement, String sql) throws SQLException {
        String[] queries = sql.split(";");
        ResultSet resultSet = null;
        List<Map<String, Object>> results = new ArrayList<>();

        for (String query : queries) {
            String cleanQuery = query.trim();
            if (cleanQuery.isEmpty()) continue;

            if (cleanQuery.toUpperCase().startsWith("SELECT")) {
                resultSet = statement.executeQuery(cleanQuery);
            } else {
                statement.execute(cleanQuery);
            }
        }

        if (resultSet != null) {
            results = extractResultsToList(resultSet);
        }
        return results;
    }

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
        }).collect(java.util.stream.Collectors.toCollection(ArrayList::new));
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