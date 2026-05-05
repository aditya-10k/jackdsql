package com.jackdsql.app.dto;

import java.util.List;
import java.util.Map;

public record PreviewResponse(
        List<String> columns,
        List<Map<String, Object>> rows,
        String error
) {}
