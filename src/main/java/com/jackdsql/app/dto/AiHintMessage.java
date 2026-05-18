package com.jackdsql.app.dto;

import com.jackdsql.app.model.AiProvider;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AiHintMessage implements Serializable {

    private String requestId ;
    private String userId ;
    private String questionId ;
    private String userSqlCode ;
    private AiProvider provider ;
    private String decryptedApiKey ;
}
