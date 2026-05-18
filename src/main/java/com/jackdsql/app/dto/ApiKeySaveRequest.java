package com.jackdsql.app.dto;

import com.jackdsql.app.model.AiProvider;
import lombok.Data;

@Data
public class ApiKeySaveRequest {

    private AiProvider provider ;
    private String apiKey ;
}
