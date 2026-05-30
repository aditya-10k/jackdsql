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
import jakarta.mail.MessagingException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository ;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService ;
    private final AuthenticationManager authenticationManager;

    @Autowired
    private MailerService mailerService ;

    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private  String clientId;

    public AuthenticationResponse refreshToken(
            String authHeader
    ){

        if( authHeader == null || !authHeader.startsWith("Bearer ")){
            throw  new RuntimeException("Missing Refresh Token");
        }

        String refreshToken = authHeader.substring(7);

        String tokenType = jwtService.extractTokenType(refreshToken);

        if(!"refresh".equals(tokenType)){
            throw  new RuntimeException("Token is not refresh token");
        }

        String userName = jwtService.extractUsername(refreshToken);

        User user = userRepository.findByEmail(userName)
                .orElseThrow();

        String accessToken = jwtService.generateAccessToken(user);
        String refreshTokenNew = jwtService.generateRefreshToken(user);

        return AuthenticationResponse.builder()
                .message("Tokens refreshed")
                .refreshToken(refreshTokenNew)
                .accessToken(accessToken)
                .build();
    }

    public AuthenticationResponse register(RegisterRequest registerRequest) throws MessagingException {

        var user = User.builder()
                .name(registerRequest.name())
                .email(registerRequest.email())
                .password(passwordEncoder.encode((registerRequest.password())))
                .build();

        userRepository.save(user);
        var jwtAccessToken = jwtService.generateAccessToken(user);
        var jwtRefreshToken = jwtService.generateRefreshToken(user);

        mailerService.sendWelcomeMail(registerRequest.email());

        return AuthenticationResponse.builder().accessToken(jwtAccessToken).refreshToken(jwtRefreshToken).build();

    }

    public AuthenticationResponse resetPassword(UserDetails userDetails ,String updatedPassword ){

        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("UserNotFound"));

        if(passwordEncoder.matches(updatedPassword , user.getPassword())){

            return AuthenticationResponse.builder().message("Password cannot be same as the earlier one").build();
        }
        else {
            user.setPassword(passwordEncoder.encode(updatedPassword));

            userRepository.save(user);

            var jwtAccessToken = jwtService.generateAccessToken(user);
            var jwtRefreshToken = jwtService.generateRefreshToken(user);

            return AuthenticationResponse.builder().accessToken(jwtAccessToken).refreshToken(jwtRefreshToken).build();
        }
    }

    public AuthenticationResponse authenticate(AuthenticationRequest request){

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email() , request.password())
        );

        var user = userRepository.findByEmail((request.email())).orElseThrow();

        var jwtAccessToken = jwtService.generateAccessToken(user);
        var jwtRefreshToken = jwtService.generateRefreshToken(user);

        return AuthenticationResponse.builder().accessToken(jwtAccessToken).refreshToken(jwtRefreshToken).message("success").build();
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

                var jwtAccessToken = jwtService.generateAccessToken(user);
                var jwtRefreshToken = jwtService.generateRefreshToken(user);

                return AuthenticationResponse.builder().accessToken(jwtAccessToken).refreshToken(jwtRefreshToken).build();
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
