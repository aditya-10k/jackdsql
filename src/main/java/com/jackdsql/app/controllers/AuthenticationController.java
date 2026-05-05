package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.AuthenticationRequest;
import com.jackdsql.app.dto.AuthenticationResponse;
import com.jackdsql.app.dto.GoogleAuthRequest;
import com.jackdsql.app.dto.RegisterRequest;
import com.jackdsql.app.service.AuthenticationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.security.GeneralSecurityException;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthenticationController {

    private final AuthenticationService authenticationService ;

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> register(@RequestBody RegisterRequest registerRequest){
        return ResponseEntity.ok((authenticationService.register(registerRequest)));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthenticationResponse> login(@RequestBody AuthenticationRequest registerRequest){
        return ResponseEntity.ok((authenticationService.authenticate(registerRequest)));
    }

    @PostMapping("/googleauth")
    public ResponseEntity<AuthenticationResponse> googleauth(@RequestBody GoogleAuthRequest request) throws GeneralSecurityException, IOException {
        return ResponseEntity.ok(authenticationService.authenticateWithGoogle(request));
    }
}
