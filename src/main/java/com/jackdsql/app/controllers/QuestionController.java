package com.jackdsql.app.controllers;

import com.jackdsql.app.dto.BookmarkResponse;
import com.jackdsql.app.dto.QuestionDetailDTO;
import com.jackdsql.app.model.Question;
import com.jackdsql.app.model.User;
import com.jackdsql.app.model.UserBookmark;
import com.jackdsql.app.repository.QuestionListingProjection;
import com.jackdsql.app.repository.QuestionRepository;
import com.jackdsql.app.repository.UserRepository;
import com.jackdsql.app.service.BookmarkService;
import com.jackdsql.app.service.QuestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.* ;

@RestController
@RequestMapping("/api/questions")
@CrossOrigin(origins = "*")
public class QuestionController {

    @Autowired
    private  QuestionRepository questionRepository ;

    @Autowired
    private BookmarkService bookmarkService;

    @Autowired
    private QuestionService questionService ;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/all-questions")
    public ResponseEntity<List<Question>> getAllQuestions(){
        List<Question> questions = questionRepository.findAll();
        return ResponseEntity.ok(questions) ;
    }

    @GetMapping("/{id}")
    public ResponseEntity<QuestionDetailDTO> getQuestionDetail(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        return ResponseEntity.ok(questionService.getQuestionDetail(id, userId));
    }

    @GetMapping("/grouped")
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, List<QuestionListingProjection>>> getGroupedList(@AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        return ResponseEntity.ok(questionService.getGroupedQuestions(userId));
    }

    @PostMapping("/{id}/bookmark")
    public ResponseEntity<Map<String, Boolean>> toggleHeart(
            @PathVariable String id ,
            @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        boolean status = bookmarkService.toggleBookmark(userId, id);
        return ResponseEntity.ok(Map.of("is_bookmarked", status));
    }

    @GetMapping("/bookmarks")
    public ResponseEntity<List<BookmarkResponse>> getBookmarkedOnly(@AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername()).orElseThrow();
        String userId = user.getId();
        return ResponseEntity.ok(bookmarkService.getUserBookmark(userId));
    }

}
