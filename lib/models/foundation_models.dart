// Foundation Models

class Foundation {
  final String id;
  final String chapter;
  final String title;
  final String content;
  final List<PracticeTask>? practiceTasks;

  Foundation({
    required this.id,
    required this.chapter,
    required this.title,
    required this.content,
    this.practiceTasks,
  });

  factory Foundation.fromJson(Map<String, dynamic> json) {
    return Foundation(
      id: json['id'] as String,
      chapter: json['chapter'] as String,
      title: json['title'] as String,
      content: (json['content'] ?? json['theory'] ?? '') as String,
      practiceTasks: (json['practice_tasks'] as List?)
          ?.map((e) => PracticeTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter': chapter,
      'title': title,
      'content': content,
      'practice_tasks': practiceTasks?.map((e) => e.toJson()).toList(),
    };
  }
}

class FoundationCatalogue {
  final String id;
  final String chapter;
  final String title;
  final bool completed;

  FoundationCatalogue({
    required this.id,
    required this.chapter,
    required this.title,
    required this.completed,
  });

  factory FoundationCatalogue.fromJson(Map<String, dynamic> json) {
    return FoundationCatalogue(
      id: json['id'] as String,
      chapter: json['chapter'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter': chapter,
      'title': title,
      'completed': completed,
    };
  }
}

class PracticeTask {
  final String id;
  final String taskDescription;
  final String expectedSchemaSql;
  final String solutionSql;

  PracticeTask({
    required this.id,
    required this.taskDescription,
    required this.expectedSchemaSql,
    required this.solutionSql,
  });

  factory PracticeTask.fromJson(Map<String, dynamic> json) {
    return PracticeTask(
      id: json['id'] as String? ?? '',
      taskDescription: (json['task_description'] ?? json['taskDescription'] ?? json['question_text'] ?? json['questionText'] ?? json['question_title'] ?? json['questionTitle'] ?? '') as String,
      expectedSchemaSql: (json['expected_schema_sql'] ?? json['expectedSchemaSql'] ?? json['schema_sql'] ?? json['schemaSql'] ?? '') as String,
      solutionSql: (json['solution_sql'] ?? json['solutionSql'] ?? json['solution_query'] ?? json['solutionQuery'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_description': taskDescription,
      'expected_schema_sql': expectedSchemaSql,
      'solution_sql': solutionSql,
    };
  }
}

class FoundationPreviewRequest {
  final String topicId;
  final String userSql;

  FoundationPreviewRequest({
    required this.topicId,
    required this.userSql,
  });

  factory FoundationPreviewRequest.fromJson(Map<String, dynamic> json) {
    return FoundationPreviewRequest(
      topicId: json['topic_id'] as String,
      userSql: json['user_sql'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'user_sql': userSql,
    };
  }
}

class FoundationSubmitRequest {
  final String topicId;
  final String userSql;

  FoundationSubmitRequest({
    required this.topicId,
    required this.userSql,
  });

  factory FoundationSubmitRequest.fromJson(Map<String, dynamic> json) {
    return FoundationSubmitRequest(
      topicId: json['topic_id'] as String,
      userSql: json['user_sql'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'user_sql': userSql,
    };
  }
}
