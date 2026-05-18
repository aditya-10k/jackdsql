package com.jackdsql.app.dto;

import com.jackdsql.app.model.AiProvider;
import lombok.Data;

@Data
public class ApiKeyResponse {

    private AiProvider provider ;
    private String keyMask;
    private String updatedAt ;
}
