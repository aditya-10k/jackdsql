package com.jackdsql.app.service;

import com.jackdsql.app.dto.ApiKeyResponse;
import com.jackdsql.app.dto.ApiKeySaveRequest;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.UserApiKey;
import com.jackdsql.app.model.UserApiKeyId;
import com.jackdsql.app.repository.UserApiRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.stream.Collectors;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserApiKeyService {

    @Autowired
    private UserApiRepository repository;

    @Autowired
    private TextEncryptor textEncryptor ;


    @Transactional
    public void saveUserKey(String userId , ApiKeySaveRequest request){

        String cleanKey = request.getApiKey().trim();

        String encryptedKey = textEncryptor.encrypt(cleanKey);
        String mask = generateKeyMask(cleanKey);

        UserApiKeyId compositeKey = new UserApiKeyId(userId , request.getProvider());

        UserApiKey userApiKey = new UserApiKey(compositeKey, encryptedKey , mask , LocalDateTime.now());

        repository.save(userApiKey);
    }

    public String generateKeyMask(String key){
        if(key.length() <= 8) return "********";

        return key.substring(0,4) + "..." + key.substring(key.length()-4);
    }

    @Transactional(readOnly = true)
    public List<ApiKeyResponse> fetchUserKeysMetaData(String userId){

        return repository.findByUserApiKeyId_UserId(userId).stream()
                .map(this::mapToResponse) // First convert entity to DTO
                .collect(Collectors.toList()); // Then collect into a List
    }

    @Transactional
    public void deleteUserKey(String userId , AiProvider provider){
        UserApiKeyId compositeId = new UserApiKeyId(userId ,provider);
        repository.deleteById(compositeId);
    }

    private ApiKeyResponse mapToResponse(UserApiKey entity) {
        ApiKeyResponse dto = new ApiKeyResponse();
        dto.setProvider(entity.getUserApiKeyId().getProvider());
        dto.setKeyMask(entity.getKeyMask());
        dto.setUpdatedAt(entity.getUpdatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        return dto;
    }
}
