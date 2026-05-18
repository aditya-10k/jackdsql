package com.jackdsql.app.repository;

import org.springframework.stereotype.Repository;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class SseEmittersRepository {

    private final Map<String , SseEmitter> emmiters = new ConcurrentHashMap<>();

    public void register(String userId , SseEmitter emmiter){
        this.emmiters.put(userId , emmiter);
    }

    public void delete(String userId){
        this.emmiters.remove(userId);
    }

    public SseEmitter get (String userId){
        return this.emmiters.get(userId);
    }
}
