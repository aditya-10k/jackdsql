package com.jackdsql.app.controllers;

import com.jackdsql.app.model.Foundation;
import com.jackdsql.app.repository.FoundationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/foundations")
@RequiredArgsConstructor
public class FoundationController {

    private final FoundationRepository repository;

    @GetMapping
    public List<Foundation> getAllFoundations() {
        return repository.findAll();
    }
}