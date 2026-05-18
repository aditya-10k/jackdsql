package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.AiHintMessage;
import com.jackdsql.app.model.AiProvider;
import com.jackdsql.app.model.UserApiKey;
import com.jackdsql.app.model.UserApiKeyId;
import com.jackdsql.app.repository.SseEmittersRepository;
import com.jackdsql.app.repository.UserApiRepository;
import com.jackdsql.app.service.AiHintProducerService;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import javax.swing.plaf.PanelUI;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/ai")
@NoArgsConstructor
public class AiHintController {

    @Autowired
    private UserApiRepository userApiRepository;

    @Autowired
    private  TextEncryptor textEncryptor ;

    @Autowired
    private SseEmittersRepository sseEmittersRepository ;

    @Autowired
    private  AiHintProducerService aiHintProducerService ;

    @PostMapping("/hint/{questionId}")
    public ResponseEntity<Map<String,String>> requestQuestionHint(
            @PathVariable String questionId ,
            @AuthenticationPrincipal UserDetails details ,
            @RequestBody Map<String, String> body,
            @RequestParam AiProvider provider
            ){

        String userId = details.getUsername();

        String userSql = body.getOrDefault("sqlCode" , "").trim();

        UserApiKeyId apiKeyId = new UserApiKeyId(userId , provider );
        UserApiKey apiKeyEntity = userApiRepository.findById(apiKeyId)
                .orElseThrow(() -> new IllegalArgumentException("No configured API credientials found for " +provider));

        String decryptedKey = textEncryptor.decrypt(apiKeyEntity.getEncryptedApiKey());

        String trackingId = UUID.randomUUID().toString();

        AiHintMessage aiHintMessage = new AiHintMessage(
                trackingId,
                userId,
                questionId,
                userSql,
                provider,
                decryptedKey
        );

        aiHintProducerService.sendHintRequest(aiHintMessage);

        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(Map.of("requestId" , trackingId , "status" , "PENDING"));
    }

    @GetMapping(value = "/stream" , produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamAiHints(@AuthenticationPrincipal UserDetails userDetails){

        SseEmitter emitter = new SseEmitter(300_000L);
        String userId = userDetails.getUsername();

        sseEmittersRepository.register(userId , emitter);

        emitter.onCompletion(() -> sseEmittersRepository.delete(userId));
        emitter.onTimeout(() -> sseEmittersRepository.delete(userId));
        emitter.onError((e) -> sseEmittersRepository.delete(userId));

        try {
            emitter.send(SseEmitter.event().name("INIT").data("Connection Established"));
        }catch (Exception e){
            sseEmittersRepository.delete(userId);
        }

        return emitter ;
    }


}
