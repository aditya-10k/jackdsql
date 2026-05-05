package com.jackdsql.app.seeder;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies; // Import this
import com.jackdsql.app.model.Foundation;
import com.jackdsql.app.repository.FoundationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.List;

@Component
@RequiredArgsConstructor
public class FoundationSeeder implements CommandLineRunner {

    private final FoundationRepository foundationRepository;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        if (foundationRepository.count() == 0) {
            objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);

            InputStream inputStream = getClass().getResourceAsStream("/postgres-curriculum.json");

            if (inputStream == null) {
                System.err.println("❌ Could not find postgres-curriculum.json in resources");
                return;
            }

            List<Foundation> foundations = objectMapper.readValue(inputStream,
                    new TypeReference<List<Foundation>>() {});

            for (Foundation foundation : foundations) {
                if (foundation.getPracticeTasks() != null) {
                    foundation.getPracticeTasks().forEach(q -> {
                        // Fill required 'source' field missing in JSON
                        if (q.getSource() == null) {
                            q.setSource("foundation_module");
                        }
                    });
                }
            }

            foundationRepository.saveAll(foundations);
            System.out.println("✅ SQL Foundation loaded and snake_case mapping applied.");
        }
    }
}