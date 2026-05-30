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
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
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
            String token = googleAuthRequest.idToken();
            String email;
            String name;

            // Detect token type: a JWT has exactly 3 base64url parts separated by dots.
            // An access token (opaque) does not follow this format.
            boolean isJwt = token != null && token.split("\\.").length == 3;

            if (isJwt) {
                // --- ID Token path: verify with GoogleIdTokenVerifier ---
                GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                        .setAudience(Collections.singleton(clientId))
                        .build();

                GoogleIdToken idToken = verifier.verify(token);
                if (idToken == null) {
                    throw new RuntimeException("Invalid Google ID token");
                }

                GoogleIdToken.Payload payload = idToken.getPayload();
                email = payload.getEmail();
                name = (String) payload.get("name");

            } else {
                // --- Access Token path: call Google userinfo endpoint ---
                NetHttpTransport transport = new NetHttpTransport();
                String userInfoUrl = "https://www.googleapis.com/oauth2/v3/userinfo";
                com.google.api.client.http.HttpRequest request = transport
                        .createRequestFactory()
                        .buildGetRequest(new com.google.api.client.http.GenericUrl(userInfoUrl));
                request.getHeaders().setAuthorization("Bearer " + token);

                com.google.api.client.http.HttpResponse response = request.execute();
                String responseBody = response.parseAsString();

                com.google.gson.JsonObject userInfo = new com.google.gson.JsonParser()
                        .parse(responseBody)
                        .getAsJsonObject();

                email = userInfo.get("email").getAsString();
                name = userInfo.has("name") ? userInfo.get("name").getAsString() : email;
            }

            var user = userRepository.findByEmail(email).orElseGet(() -> {
                var newUser = User.builder()
                        .name(name)
                        .email(email)
                        .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                        .build();
                User savedUser = userRepository.save(newUser);
                try {
                    mailerService.sendWelcomeMail(email);
                } catch (Exception e) {
                    System.err.println("Failed to send welcome email for OAuth user: " + e.getMessage());
                }
                return savedUser;
            });

            var jwtAccessToken = jwtService.generateAccessToken(user);
            var jwtRefreshToken = jwtService.generateRefreshToken(user);

            return AuthenticationResponse.builder()
                    .accessToken(jwtAccessToken)
                    .refreshToken(jwtRefreshToken)
                    .build();

        } catch (Exception e) {
            System.err.println("Google Auth Error Type: " + e.getClass().getName());
            System.err.println("Google Auth Error Message: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Google authentication failed: " + e.getMessage(), e);
        }
    }
}
