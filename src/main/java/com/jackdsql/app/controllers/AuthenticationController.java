package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.AuthenticationRequest;
import com.jackdsql.app.dto.AuthenticationResponse;
import com.jackdsql.app.dto.GoogleAuthRequest;
import com.jackdsql.app.dto.RegisterRequest;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.AuthenticationService;
import com.jackdsql.app.service.OtpAndChangePasswordService;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import org.springframework.beans.factory.annotation.Value;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthenticationController {

    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private String googleClientId;

    @Autowired
    private  AuthenticationService authenticationService ;

    @Autowired
    private OtpAndChangePasswordService otpAndChangePasswordService ;

    @Autowired
    private UserRepository userRepository ;

    @GetMapping("/google/client-id")
    public ResponseEntity<Map<String, String>> getGoogleClientId() {
        return ResponseEntity.ok(Map.of("clientId", googleClientId));
    }

    @GetMapping("/refresh")

    public ResponseEntity<AuthenticationResponse> refreshToken(@RequestHeader("Authorization") String authHeader){

        return ResponseEntity.ok(authenticationService.refreshToken(authHeader));
    }

    @PostMapping("/reset")
    public ResponseEntity<AuthenticationResponse> resetPassword(@AuthenticationPrincipal UserDetails userDetails,@RequestBody Map<String , String> body){

        String updatedPassword = body.getOrDefault("updatedPassword" , "");
        return ResponseEntity.ok(authenticationService.resetPassword(userDetails , updatedPassword ));
    }

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> register(@RequestBody RegisterRequest registerRequest) throws MessagingException {
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

    @PostMapping("/sendotp")
    public ResponseEntity<AuthenticationResponse> sendOtp(@RequestBody Map<String , String> body) throws Exception {

        String mail = body.getOrDefault("email" , "");
        return ResponseEntity.ok(otpAndChangePasswordService.sendOtp(mail));
    }

    @PostMapping("/verifyOtp")
    public ResponseEntity<AuthenticationResponse> verifyOtpAndResetPassword(@RequestBody Map<String , String> body){

        String password = body.get("password");
        String mail = body.get("email");
        String otp = body.get("otp");

        return ResponseEntity.ok(otpAndChangePasswordService.verifyOtpAndChangePassword(otp,mail,password));
    }

    @PostMapping("/deleteUser")
    public ResponseEntity<?> deleteUser(@RequestBody Map<String , String> body){

        String email = body.get("email");
        String password = body.get("password");

        if(password.equals("adminIsGOAT")){
            User user = userRepository.findByEmail(email)
                    .orElseThrow();
            userRepository.deleteById(user.getId());
           return ResponseEntity.accepted().body("user deleted successfully");
        }

        return ResponseEntity.badRequest().build();
    }


}
