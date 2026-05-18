package com.jackdsql.app.service;

import com.jackdsql.app.dto.BookmarkResponse;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.model.UserBookmark;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.repository.UserBookmarkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class BookmarkService {

    @Autowired
    private UserBookmarkRepository userBookmarkRepository ;
    @Autowired
    private QuestionRepository questionRepository ;

    @Transactional
    public boolean toggleBookmark(String userId , String questionId){

        Optional<UserBookmark> existing = userBookmarkRepository.findByUserIdAndQuestionId(userId ,questionId);

        if(existing.isPresent()){
            userBookmarkRepository.delete(existing.get());
            return false ;
        }else{
            Question q = questionRepository.findById(questionId)
                    .orElseThrow(() -> new RuntimeException("Question not found"));

            userBookmarkRepository.save(UserBookmark.builder()
                    .userId(userId)
                    .question(q)
                    .bookmarkedAt(LocalDateTime.now())
                    .build());
            return true;
        }

    }

    public List<BookmarkResponse> getUserBookmark(String userId) {

        List<UserBookmark> bookmarks =
                userBookmarkRepository.findAllByUserId(userId);

        return bookmarks.stream()
                .map(b -> new BookmarkResponse(
                        b.getId(),
                        b.getQuestion().getId(),
                        b.getQuestion().getQuestionTitle(),
                        b.getBookmarkedAt()
                ))
                .toList();
    }
}