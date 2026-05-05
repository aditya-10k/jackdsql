package com.jackdsql.app.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Table(name = "foundation")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Foundation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id ;

    private String chapter ;
    private String title ;

    @Column(columnDefinition = "text")
    private String theory ;

    @OneToMany(cascade = CascadeType.ALL , orphanRemoval = true , fetch = FetchType.EAGER)
    @JoinColumn(name = "topic_id")
    private List<TopicExample> examples ;

    @JsonProperty("practice_tasks")
    @ManyToMany(cascade = {CascadeType.PERSIST , CascadeType.MERGE}, fetch = FetchType.EAGER)
    @JoinTable(
            name = "foundation_question_mapping" ,
            joinColumns = @JoinColumn(name = "topic_id"),
            inverseJoinColumns = @JoinColumn(name = "question_id")
    )
    private List<Question> practiceTasks ;
}
