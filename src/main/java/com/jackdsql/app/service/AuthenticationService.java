package com.jackdsql.app.service;


import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.jackdsql.app.dto.AuthenticationRequest;
import com.jackdsql.app.dto.AuthenticationResponse;
import com.jackdsql.app.dto.GoogleAuthRequest;
import com.jackdsql.app.dto.RegisterRequest;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository ;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService ;
    private final AuthenticationManager authenticationManager;

    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private  String clientId;

    public AuthenticationResponse register(RegisterRequest registerRequest){

        var user = User.builder()
                .name(registerRequest.name())
                .email(registerRequest.email())
                .password(passwordEncoder.encode((registerRequest.password())))
                .build();

        userRepository.save(user);
        var jwtToken = jwtService.generateToken(user);

        return AuthenticationResponse.builder().token(jwtToken).build();

    }

    public AuthenticationResponse authenticate(AuthenticationRequest request){

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email() , request.password())
        );

        var user = userRepository.findByEmail((request.email())).orElseThrow();

        var jwtToken = jwtService.generateToken(user);

        return AuthenticationResponse.builder().token(jwtToken).build();
    }

    public AuthenticationResponse authenticateWithGoogle(GoogleAuthRequest googleAuthRequest) throws GeneralSecurityException, IOException {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                    .setAudience(Collections.singleton(clientId))
                    .build();

            GoogleIdToken idToken = verifier.verify((googleAuthRequest.idToken()));

            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                String email = payload.getEmail();
                String name = (String) payload.get("name");

                var user = userRepository.findByEmail(email).orElseGet(() -> {
                    var newUser = User.builder()
                            .name(name)
                            .email(email)
                            .password(passwordEncoder.encode((UUID.randomUUID().toString())))
                            .build();
                    return userRepository.save(newUser);
                });

                var jwtToken = jwtService.generateToken(user);
                return AuthenticationResponse.builder().token(jwtToken).build();
            } else {
                throw new RuntimeException("Invalid Google ID token");
            }
        } catch (Exception e) {
            System.err.println("Google Auth Error Type: " + e.getClass().getName());
            System.err.println("Google Auth Error Message: " + e.getMessage());
            e.printStackTrace(); // This will print the full stack trace to your IntelliJ/VS Code console
            throw new RuntimeException("Google authentication failed: " + e.getMessage() , e);
        }
    }
}
