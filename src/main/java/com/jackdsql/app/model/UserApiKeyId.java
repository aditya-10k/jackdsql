package com.jackdsql.app.model;

import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
// this is a composite key
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserApiKeyId implements Serializable {

    private String userId ;

    @Enumerated(EnumType.STRING)
    private AiProvider provider ;
}
