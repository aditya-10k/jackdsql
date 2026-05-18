package com.jackdsql.app.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.security.crypto.encrypt.TextEncryptor;

@Configuration
public class CryptoConfig {

    @Value("${jackdsql.security.master-secret}")
    private String masterSecret ;

    @Value("${jackdsql.security.master-salt}")
    private String hexSalt;

    @Bean
    public TextEncryptor textEncryptor(){
        return Encryptors.delux(masterSecret,hexSalt);
    }

}
