package com.jackdsql.app.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "topic_examples")
@Data
public class TopicExample {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id ;

    private String description ;

    @Column(columnDefinition = "TEXT")
    private String sql ;
}
