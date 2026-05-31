package com.jackdsql.app.repository;

import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory store for completed AI hint results.
 * Web clients poll GET /api/ai/hint/result/{requestId} instead of using SSE.
 * Results are kept for TTL_SECONDS and then expire automatically on next access.
 */
@Repository
public class AiHintResultRepository {

    private static final long TTL_SECONDS = 300; // 5 minutes

    private record Entry(String hint, Instant expiresAt) {}

    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    public void store(String requestId, String hint) {
        store.put(requestId, new Entry(hint, Instant.now().plusSeconds(TTL_SECONDS)));
    }

    /**
     * Returns the hint if present and not expired, then removes it (one-shot).
     */
    public Optional<String> pollResult(String requestId) {
        Entry entry = store.get(requestId);
        if (entry == null) return Optional.empty();

        if (Instant.now().isAfter(entry.expiresAt())) {
            store.remove(requestId);
            return Optional.empty();
        }

        store.remove(requestId); // consume it
        return Optional.of(entry.hint());
    }

    public boolean isPending(String requestId) {
        Entry entry = store.get(requestId);
        if (entry == null) return true; // not finished yet
        return false;
    }
}
