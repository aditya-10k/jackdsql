package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.ApiKeyResponse;
import com.jackdsql.app.dto.ApiKeySaveRequest;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.service.UserApiKeyService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/user/keys")
@RequiredArgsConstructor
public class UserApiKeyController {

    @Autowired
    private UserApiKeyService userApiKeyService;

    @PostMapping("/add")
    public ResponseEntity<Void> registerOrUpdatedKey(@RequestBody ApiKeySaveRequest request , @AuthenticationPrincipal UserDetails userDetails){

        String userId = userDetails.getUsername();

        userApiKeyService.saveUserKey(userId ,request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping
    public ResponseEntity<List<ApiKeyResponse>> getUserKeysMetadata(@AuthenticationPrincipal UserDetails userDetails){

        String userId = userDetails.getUsername();
        return ResponseEntity.ok(userApiKeyService.fetchUserKeysMetaData(userId));
    }

    @DeleteMapping("/delete/{provider}")
    public ResponseEntity<Void> removeUserKey(@AuthenticationPrincipal UserDetails userDetails , @PathVariable AiProvider provider){

        String userId = userDetails.getUsername();
        userApiKeyService.deleteUserKey(userId , provider);
        return ResponseEntity.noContent().build();
    }

}
