package com.jackdsql.app.service;

import com.jackdsql.app.dto.AuthenticationResponse;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class OtpAndChangePasswordService {

    @Autowired
    private StringRedisTemplate stringRedisTemplate ;

    @Autowired
    private MailerService mailerService ;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    private static final long OTP_EXPIRY = 5;

    private static final SecureRandom secureRandom = new SecureRandom();

    public static String generateOtp(){

        int otp = 100000 + secureRandom.nextInt(900000);

        return String.valueOf(otp);
    }

    public AuthenticationResponse sendOtp(String email)throws Exception{

        String otp = generateOtp();

        String hashedOtp = passwordEncoder.encode(otp);

        String redisKey = "OTP:" + email ;

        stringRedisTemplate.opsForValue().set(
                redisKey,
                hashedOtp,
                OTP_EXPIRY,
                TimeUnit.MINUTES
        );

        mailerService.sendOtp(email , otp);

        return AuthenticationResponse.builder().message("OTP send successfully , check mail").build();
    }

    @Transactional
    public AuthenticationResponse verifyOtpAndChangePassword(String otp , String email , String password){

        String redisKey = "OTP:"+email ;
        String hashedOtp = stringRedisTemplate.opsForValue().get(redisKey);

        if(hashedOtp == null){
            return AuthenticationResponse.builder().message("OTP has expired").build() ;
        }

        if(passwordEncoder.matches(otp , hashedOtp)){

            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            user.setPassword(passwordEncoder.encode(password));

            userRepository.save(user);

            String jwt = jwtService.generateAccessToken(user);
            String refreshjwtToken = jwtService.generateRefreshToken(user);

            stringRedisTemplate.delete(redisKey);

            return AuthenticationResponse.builder().message("Password Change Success").accessToken(jwt).refreshToken(refreshjwtToken).build();
        }
        else {
            return AuthenticationResponse.builder().message("OTP does not match").build();
        }
    }
 }
