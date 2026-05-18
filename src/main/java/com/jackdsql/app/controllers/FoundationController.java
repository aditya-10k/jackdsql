package com.jackdsql.app.controllers;

import com.jackdsql.app.model.Foundation;
import com.jackdsql.app.model.User;
import com.jackdsql.app.repository.FoundationListingProjection;
import com.jackdsql.app.repository.FoundationRepository;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.FoundationService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/foundations")
@RequiredArgsConstructor
public class FoundationController {

    private final FoundationRepository repository;

    @Autowired
    private UserRepository userRepository ;

    @Autowired
    private FoundationService foundationService;

    @GetMapping("/all")
    public List<Foundation> getAllFoundations() {
        return repository.findAll();
    }

    @GetMapping("/catalogue")
    public ResponseEntity<List<FoundationListingProjection>> getCatalogue(@AuthenticationPrincipal UserDetails userDetails){

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        return ResponseEntity.ok(foundationService.getFoundationCatalogue(userId));
    }

    @GetMapping("{id}")
    public ResponseEntity<Foundation> getTopicDetail(@PathVariable String id){
        return ResponseEntity.ok((foundationService.getTopicDetail(id)));
    }
}