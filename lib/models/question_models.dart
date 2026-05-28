// Question Models

class Question {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String domain;
  final String schemaSql;
  final String solutionSql;

  Question({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.domain,
    required this.schemaSql,
    required this.solutionSql,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      title: (json['title'] ?? json['question_title'] ?? json['questionTitle']) as String? ?? '',
      description: (json['description'] ?? json['question_text'] ?? json['questionText']) as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      schemaSql: (json['schema_sql'] ?? json['schemaSql']) as String? ?? '',
      solutionSql: (json['solution_sql'] ?? json['solutionSql'] ?? json['solution_query'] ?? json['solutionQuery']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'domain': domain,
      'schema_sql': schemaSql,
      'solution_sql': solutionSql,
    };
  }
}

class QuestionDetail {
  final Question question;
  final bool isCompleted;
  final bool isBookmarked;

  QuestionDetail({
    required this.question,
    required this.isCompleted,
    required this.isBookmarked,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    return QuestionDetail(
      question: Question.fromJson(json['question'] as Map<String, dynamic>),
      isCompleted: (json['is_completed'] ?? json['isCompleted']) as bool? ?? false,
      isBookmarked: (json['is_bookmarked'] ?? json['isBookmarked']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'is_completed': isCompleted,
      'is_bookmarked': isBookmarked,
    };
  }
}

class QuestionListing {
  final String id;
  final String title;
  final String difficulty;
  final String domain;
  final bool completed;
  final bool bookmarked;

  QuestionListing({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.domain,
    required this.completed,
    required this.bookmarked,
  });

  factory QuestionListing.fromJson(Map<String, dynamic> json) {
    return QuestionListing(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      domain: json['domain'] as String,
      completed: json['completed'] as bool? ?? false,
      bookmarked: json['bookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'domain': domain,
      'completed': completed,
      'bookmarked': bookmarked,
    };
  }
}

class PreviewRequest {
  final String questionId;
  final String userSql;

  PreviewRequest({
    required this.questionId,
    required this.userSql,
  });

  factory PreviewRequest.fromJson(Map<String, dynamic> json) {
    return PreviewRequest(
      questionId: json['question_id'] as String,
      userSql: json['user_sql'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'user_sql': userSql,
    };
  }
}

class PreviewResponse {
  final List<String>? columns;
  final List<Map<String, dynamic>>? rows;
  final String? error;

  PreviewResponse({
    this.columns,
    this.rows,
    this.error,
  });

  bool get isSuccess => error == null && columns != null && rows != null;

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    return PreviewResponse(
      columns: List<String>.from((json['columns'] as List?)?.cast<String>() ?? []),
      rows: List<Map<String, dynamic>>.from(
        (json['rows'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      ),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columns': columns,
      'rows': rows,
      'error': error,
    };
  }
}

class SubmitResponse {
  final bool isCorrect;

  SubmitResponse({required this.isCorrect});

  factory SubmitResponse.fromJson(Map<String, dynamic> json) {
    return SubmitResponse(
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'is_correct': isCorrect};
  }
}

class BookmarkResponse {
  final bool isBookmarked;

  BookmarkResponse({required this.isBookmarked});

  factory BookmarkResponse.fromJson(Map<String, dynamic> json) {
    return BookmarkResponse(
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'is_bookmarked': isBookmarked};
  }
}

class BookmarkItem {
  final String id;
  final String questionId;
  final String questionTitle;
  final String bookmarkedAt;

  BookmarkItem({
    required this.id,
    required this.questionId,
    required this.questionTitle,
    required this.bookmarkedAt,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      questionTitle: json['question_title'] as String,
      bookmarkedAt: json['bookmarked_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'question_title': questionTitle,
      'bookmarked_at': bookmarkedAt,
    };
  }
}
