package com.jackdsql.app.repository;

import com.jackdsql.app.model.UserApiKey;
import com.jackdsql.app.model.UserApiKeyId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserApiRepository extends JpaRepository<UserApiKey ,UserApiKeyId> {

    List<UserApiKey> findByUserApiKeyId_UserId(String userId);
}
