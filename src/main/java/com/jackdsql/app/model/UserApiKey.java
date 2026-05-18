package com.jackdsql.app.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.checkerframework.checker.units.qual.C;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Data
@Table(indexes = {@Index(name = "idx_user_keys_lookup" , columnList = "user_id")})
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class UserApiKey {

    @EmbeddedId
    private UserApiKeyId userApiKeyId;

    @Column(name = "encrypted_api_key" , nullable = false,columnDefinition = "TEXT")
    private String encryptedApiKey ;

    @Column(name = "key_mask" , nullable = false, length = 12)
    private String keyMask;

    @UpdateTimestamp
    @Column(name = "updatedAt" , nullable = false)
    private LocalDateTime updatedAt ;
}
