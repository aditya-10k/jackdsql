package com.jackdsql.app.model;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.persistence.*;
import lombok.*;

@Data
@Table(name = "questions")
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Entity
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id ;

    @Column(nullable = false)
    private String source ;

    @Column(nullable = false)
    private String domain ;

    @Column(nullable = false)
    private String difficulty ;

    @Column(nullable = false ,columnDefinition = "TEXT")
    private String questionTitle ;

    @Column(nullable = false,columnDefinition = "TEXT")
    private String questionText ;

    @Column(nullable = false,columnDefinition = "TEXT")
    private String schemaSql ;

    @Column(nullable = false,columnDefinition = "TEXT")
    private String solutionQuery ;


}
