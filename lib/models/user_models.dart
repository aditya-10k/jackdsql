// User & Dashboard Models

class UserStats {
  final int completedFoundations;
  final int totalFoundations;
  final int completedQuestions;
  final int totalQuestions;

  UserStats({
    required this.completedFoundations,
    required this.totalFoundations,
    required this.completedQuestions,
    required this.totalQuestions,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final foundationsJson = json['foundations'] as Map<String, dynamic>? ?? {};
    final questionsJson = json['questions'] as Map<String, dynamic>? ?? {};

    return UserStats(
      completedFoundations: foundationsJson['completed'] as int? ?? 0,
      totalFoundations: foundationsJson['total'] as int? ?? 0,
      completedQuestions: questionsJson['completed'] as int? ?? 0,
      totalQuestions: questionsJson['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foundations': {
        'completed': completedFoundations,
        'total': totalFoundations,
      },
      'questions': {
        'completed': completedQuestions,
        'total': totalQuestions,
      },
    };
  }
}

class UserOverview {
  final String message;
  final UserStats stats;
  final Map<String, List<String>> activityHistory;

  UserOverview({
    required this.message,
    required this.stats,
    required this.activityHistory,
  });

  factory UserOverview.fromJson(Map<String, dynamic> json) {
    final activityMap = json['activity_history'] as Map<String, dynamic>? ?? {};

    // Convert any nested lists properly
    final correctedActivity = <String, List<String>>{};
    activityMap.forEach((key, value) {
      if (value is List) {
        correctedActivity[key] =
            List<String>.from(value.map((e) => e.toString()));
      }
    });

    return UserOverview(
      message: json['message'] as String? ?? 'success',
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      activityHistory: correctedActivity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'stats': stats.toJson(),
      'activity_history': activityHistory,
    };
  }
}

class AiKeyRequest {
  final String provider;
  final String apiKey;

  AiKeyRequest({
    required this.provider,
    required this.apiKey,
  });

  factory AiKeyRequest.fromJson(Map<String, dynamic> json) {
    return AiKeyRequest(
      provider: json['provider'] as String,
      apiKey: json['api_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'apiKey': apiKey,
    };
  }
}

class AiKeyInfo {
  final String provider;
  final String keyMask;
  final String updatedAt;

  AiKeyInfo({
    required this.provider,
    required this.keyMask,
    required this.updatedAt,
  });

  factory AiKeyInfo.fromJson(Map<String, dynamic> json) {
    return AiKeyInfo(
      provider: json['provider'] as String? ?? '',
      keyMask: (json['keyMask'] ?? json['key_mask'] ?? '') as String,
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'key_mask': keyMask,
      'updated_at': updatedAt,
    };
  }
}

class HintRequest {
  final String? sqlCode;

  HintRequest({this.sqlCode});

  factory HintRequest.fromJson(Map<String, dynamic> json) {
    return HintRequest(
      sqlCode: json['sqlCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sqlCode': sqlCode ?? '',
    };
  }
}

class HintResponse {
  final String requestId;
  final String status;

  HintResponse({
    required this.requestId,
    required this.status,
  });

  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      requestId: (json['requestId'] ?? json['request_id'] ?? '') as String,
      status: (json['status'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'status': status,
    };
  }
}

class PlaygroundRequest {
  final String userSql;

  PlaygroundRequest({required this.userSql});

  factory PlaygroundRequest.fromJson(Map<String, dynamic> json) {
    return PlaygroundRequest(
      userSql: json['userSql'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userSql': userSql,
    };
  }
}
