package com.jackdsql.app.repository;

import com.jackdsql.app.model.UserBookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserBookmarkRepository extends JpaRepository<UserBookmark , String> {

    Optional<UserBookmark> findByUserIdAndQuestionId(String userId , String questionId);

    List<UserBookmark> findAllByUserId(String userId);
}
