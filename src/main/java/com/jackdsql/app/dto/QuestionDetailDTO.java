package com.jackdsql.app.dto;

import com.jackdsql.app.model.Question;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class QuestionDetailDTO {

    private Question question ;
    private boolean isCompleted;
    private boolean isBookmarked;
}
