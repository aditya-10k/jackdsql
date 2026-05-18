package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.UserProfileDTO;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.ActivityService;
import com.jackdsql.app.service.StatsService;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.checkerframework.checker.units.qual.N;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@RequestMapping("api/user")
public class UserDashboard {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StatsService statsService;

    @Autowired
    private ActivityService activityService ;

    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getOverview(@AuthenticationPrincipal UserDetails userDetails){

        Map<String , Object> response = new HashMap<>();

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();

        response.put("message" , "success");
        response.put("stats", statsService.getUserOverview(userId));

        response.put("activity_history" , statsService.getCompletionHistory(userId));

        return ResponseEntity.ok((response));
    }

    @GetMapping("/profile")
    public ResponseEntity<UserProfileDTO> getUserInfo(@AuthenticationPrincipal UserDetails userDetails){

        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow();

        return ResponseEntity.ok(UserProfileDTO.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .name(user.getName())
                .build());

    }
}
