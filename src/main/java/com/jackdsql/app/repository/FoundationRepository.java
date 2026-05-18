package com.jackdsql.app.repository;

import com.jackdsql.app.model.Foundation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FoundationRepository extends JpaRepository<Foundation , String> {

    @Query("SELECT f.id AS id, f.chapter AS chapter, f.title AS title, " +
            "(CASE WHEN fp.id IS NOT NULL THEN true ELSE false END) AS completed " +
            "FROM Foundation f " +
            "LEFT JOIN FoundationProgress fp ON f.id = fp.topic.id AND fp.userId = :userId")
    List<FoundationListingProjection> findAllWithStatus(@Param("userId") String userId);
}

