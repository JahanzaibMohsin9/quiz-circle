import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics.dart';

class QuizAnalyticsModel extends Equatable {
  final String quizId;
  final String quizTitle;
  final int totalAttempts;
  final double averageScore;
  final double averagePercentage;
  final int totalParticipants;
  final double completionRate;
  final int averageTimeSeconds;
  final List<QuestionAnalyticsModel> questionAnalytics;
  final List<DailyAnalyticsModel> dailyAnalytics;

  const QuizAnalyticsModel({
    required this.quizId,
    required this.quizTitle,
    required this.totalAttempts,
    required this.averageScore,
    required this.averagePercentage,
    required this.totalParticipants,
    required this.completionRate,
    required this.averageTimeSeconds,
    required this.questionAnalytics,
    required this.dailyAnalytics,
  });

  factory QuizAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return QuizAnalyticsModel(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      totalAttempts: json['totalAttempts'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      averagePercentage: (json['averagePercentage'] as num).toDouble(),
      totalParticipants: json['totalParticipants'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      averageTimeSeconds: json['averageTimeSeconds'] as int,
      questionAnalytics: (json['questionAnalytics'] as List<dynamic>)
          .map(
            (e) => QuestionAnalyticsModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      dailyAnalytics: (json['dailyAnalytics'] as List<dynamic>)
          .map((e) => DailyAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalAttempts': totalAttempts,
      'averageScore': averageScore,
      'averagePercentage': averagePercentage,
      'totalParticipants': totalParticipants,
      'completionRate': completionRate,
      'averageTimeSeconds': averageTimeSeconds,
      'questionAnalytics': questionAnalytics.map((e) => e.toJson()).toList(),
      'dailyAnalytics': dailyAnalytics.map((e) => e.toJson()).toList(),
    };
  }

  QuizAnalytics toDomain() {
    return QuizAnalytics(
      quizId: quizId,
      quizTitle: quizTitle,
      totalAttempts: totalAttempts,
      averageScore: averageScore,
      averagePercentage: averagePercentage,
      totalParticipants: totalParticipants,
      completionRate: completionRate,
      averageTimeSeconds: averageTimeSeconds,
      questionAnalytics: questionAnalytics.map((e) => e.toDomain()).toList(),
      dailyAnalytics: dailyAnalytics.map((e) => e.toDomain()).toList(),
    );
  }

  factory QuizAnalyticsModel.fromDomain(QuizAnalytics quizAnalytics) {
    return QuizAnalyticsModel(
      quizId: quizAnalytics.quizId,
      quizTitle: quizAnalytics.quizTitle,
      totalAttempts: quizAnalytics.totalAttempts,
      averageScore: quizAnalytics.averageScore,
      averagePercentage: quizAnalytics.averagePercentage,
      totalParticipants: quizAnalytics.totalParticipants,
      completionRate: quizAnalytics.completionRate,
      averageTimeSeconds: quizAnalytics.averageTimeSeconds,
      questionAnalytics: quizAnalytics.questionAnalytics
          .map((e) => QuestionAnalyticsModel.fromDomain(e))
          .toList(),
      dailyAnalytics: quizAnalytics.dailyAnalytics
          .map((e) => DailyAnalyticsModel.fromDomain(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    quizId,
    quizTitle,
    totalAttempts,
    averageScore,
    averagePercentage,
    totalParticipants,
    completionRate,
    averageTimeSeconds,
    questionAnalytics,
    dailyAnalytics,
  ];
}

class QuestionAnalyticsModel extends Equatable {
  final String questionId;
  final String questionText;
  final Map<String, int> answerCounts;
  final String correctAnswer;
  final int correctAnswerCount;
  final double correctAnswerPercentage;

  const QuestionAnalyticsModel({
    required this.questionId,
    required this.questionText,
    required this.answerCounts,
    required this.correctAnswer,
    required this.correctAnswerCount,
    required this.correctAnswerPercentage,
  });

  factory QuestionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnalyticsModel(
      questionId: json['questionId'] as String,
      questionText: json['questionText'] as String,
      answerCounts: Map<String, int>.from(json['answerCounts'] as Map),
      correctAnswer: json['correctAnswer'] as String,
      correctAnswerCount: json['correctAnswerCount'] as int,
      correctAnswerPercentage: (json['correctAnswerPercentage'] as num)
          .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'answerCounts': answerCounts,
      'correctAnswer': correctAnswer,
      'correctAnswerCount': correctAnswerCount,
      'correctAnswerPercentage': correctAnswerPercentage,
    };
  }

  QuestionAnalytics toDomain() {
    return QuestionAnalytics(
      questionId: questionId,
      questionText: questionText,
      answerCounts: answerCounts,
      correctAnswer: correctAnswer,
      correctAnswerCount: correctAnswerCount,
      correctAnswerPercentage: correctAnswerPercentage,
    );
  }

  factory QuestionAnalyticsModel.fromDomain(
    QuestionAnalytics questionAnalytics,
  ) {
    return QuestionAnalyticsModel(
      questionId: questionAnalytics.questionId,
      questionText: questionAnalytics.questionText,
      answerCounts: questionAnalytics.answerCounts,
      correctAnswer: questionAnalytics.correctAnswer,
      correctAnswerCount: questionAnalytics.correctAnswerCount,
      correctAnswerPercentage: questionAnalytics.correctAnswerPercentage,
    );
  }

  @override
  List<Object?> get props => [
    questionId,
    questionText,
    answerCounts,
    correctAnswer,
    correctAnswerCount,
    correctAnswerPercentage,
  ];
}

class DailyAnalyticsModel extends Equatable {
  final DateTime date;
  final int attempts;
  final double averageScore;
  final double averagePercentage;
  final int uniqueParticipants;

  const DailyAnalyticsModel({
    required this.date,
    required this.attempts,
    required this.averageScore,
    required this.averagePercentage,
    required this.uniqueParticipants,
  });

  factory DailyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return DailyAnalyticsModel(
      date: DateTime.parse(json['date'] as String),
      attempts: json['attempts'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      averagePercentage: (json['averagePercentage'] as num).toDouble(),
      uniqueParticipants: json['uniqueParticipants'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'attempts': attempts,
      'averageScore': averageScore,
      'averagePercentage': averagePercentage,
      'uniqueParticipants': uniqueParticipants,
    };
  }

  DailyAnalytics toDomain() {
    return DailyAnalytics(
      date: date,
      attempts: attempts,
      averageScore: averageScore,
      averagePercentage: averagePercentage,
      uniqueParticipants: uniqueParticipants,
    );
  }

  factory DailyAnalyticsModel.fromDomain(DailyAnalytics dailyAnalytics) {
    return DailyAnalyticsModel(
      date: dailyAnalytics.date,
      attempts: dailyAnalytics.attempts,
      averageScore: dailyAnalytics.averageScore,
      averagePercentage: dailyAnalytics.averagePercentage,
      uniqueParticipants: dailyAnalytics.uniqueParticipants,
    );
  }

  @override
  List<Object?> get props => [
    date,
    attempts,
    averageScore,
    averagePercentage,
    uniqueParticipants,
  ];
}

class UserAnalyticsModel extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final int totalQuizzesTaken;
  final int totalScore;
  final double averagePercentage;
  final int totalTimeSpentSeconds;
  final List<QuizAttemptAnalyticsModel> quizAttempts;
  final DateTime? lastActivity;

  const UserAnalyticsModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.totalQuizzesTaken,
    required this.totalScore,
    required this.averagePercentage,
    required this.totalTimeSpentSeconds,
    required this.quizAttempts,
    this.lastActivity,
  });

  factory UserAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return UserAnalyticsModel(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      totalQuizzesTaken: json['totalQuizzesTaken'] as int,
      totalScore: json['totalScore'] as int,
      averagePercentage: (json['averagePercentage'] as num).toDouble(),
      totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int,
      quizAttempts: (json['quizAttempts'] as List<dynamic>)
          .map(
            (e) =>
                QuizAttemptAnalyticsModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalScore': totalScore,
      'averagePercentage': averagePercentage,
      'totalTimeSpentSeconds': totalTimeSpentSeconds,
      'quizAttempts': quizAttempts.map((e) => e.toJson()).toList(),
      if (lastActivity != null) 'lastActivity': lastActivity!.toIso8601String(),
    };
  }

  UserAnalytics toDomain() {
    return UserAnalytics(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      totalQuizzesTaken: totalQuizzesTaken,
      totalScore: totalScore,
      averagePercentage: averagePercentage,
      totalTimeSpentSeconds: totalTimeSpentSeconds,
      quizAttempts: quizAttempts.map((e) => e.toDomain()).toList(),
      lastActivity: lastActivity,
    );
  }

  factory UserAnalyticsModel.fromDomain(UserAnalytics userAnalytics) {
    return UserAnalyticsModel(
      userId: userAnalytics.userId,
      userName: userAnalytics.userName,
      userEmail: userAnalytics.userEmail,
      totalQuizzesTaken: userAnalytics.totalQuizzesTaken,
      totalScore: userAnalytics.totalScore,
      averagePercentage: userAnalytics.averagePercentage,
      totalTimeSpentSeconds: userAnalytics.totalTimeSpentSeconds,
      quizAttempts: userAnalytics.quizAttempts
          .map((e) => QuizAttemptAnalyticsModel.fromDomain(e))
          .toList(),
      lastActivity: userAnalytics.lastActivity,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    userEmail,
    totalQuizzesTaken,
    totalScore,
    averagePercentage,
    totalTimeSpentSeconds,
    quizAttempts,
    lastActivity,
  ];
}

class QuizAttemptAnalyticsModel extends Equatable {
  final String quizId;
  final String quizTitle;
  final int score;
  final double percentage;
  final DateTime attemptDate;
  final int timeTakenSeconds;
  final bool completed;

  const QuizAttemptAnalyticsModel({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.percentage,
    required this.attemptDate,
    required this.timeTakenSeconds,
    required this.completed,
  });

  factory QuizAttemptAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptAnalyticsModel(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      score: json['score'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      attemptDate: DateTime.parse(json['attemptDate'] as String),
      timeTakenSeconds: json['timeTakenSeconds'] as int,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'percentage': percentage,
      'attemptDate': attemptDate.toIso8601String(),
      'timeTakenSeconds': timeTakenSeconds,
      'completed': completed,
    };
  }

  QuizAttemptAnalytics toDomain() {
    return QuizAttemptAnalytics(
      quizId: quizId,
      quizTitle: quizTitle,
      score: score,
      percentage: percentage,
      attemptDate: attemptDate,
      timeTakenSeconds: timeTakenSeconds,
      completed: completed,
    );
  }

  factory QuizAttemptAnalyticsModel.fromDomain(
    QuizAttemptAnalytics quizAttemptAnalytics,
  ) {
    return QuizAttemptAnalyticsModel(
      quizId: quizAttemptAnalytics.quizId,
      quizTitle: quizAttemptAnalytics.quizTitle,
      score: quizAttemptAnalytics.score,
      percentage: quizAttemptAnalytics.percentage,
      attemptDate: quizAttemptAnalytics.attemptDate,
      timeTakenSeconds: quizAttemptAnalytics.timeTakenSeconds,
      completed: quizAttemptAnalytics.completed,
    );
  }

  @override
  List<Object?> get props => [
    quizId,
    quizTitle,
    score,
    percentage,
    attemptDate,
    timeTakenSeconds,
    completed,
  ];
}

class SystemAnalyticsModel extends Equatable {
  final int totalUsers;
  final int totalQuizzes;
  final int totalSubmissions;
  final double averageScore;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int activeUsersThisMonth;
  final List<QuizAnalyticsModel> topPerformingQuizzes;
  final List<UserAnalyticsModel> topPerformingUsers;
  final Map<String, int> userRoleDistribution;
  final List<MonthlyAnalyticsModel> monthlyAnalytics;

  const SystemAnalyticsModel({
    required this.totalUsers,
    required this.totalQuizzes,
    required this.totalSubmissions,
    required this.averageScore,
    required this.activeUsersToday,
    required this.activeUsersThisWeek,
    required this.activeUsersThisMonth,
    required this.topPerformingQuizzes,
    required this.topPerformingUsers,
    required this.userRoleDistribution,
    required this.monthlyAnalytics,
  });

  factory SystemAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SystemAnalyticsModel(
      totalUsers: json['totalUsers'] as int,
      totalQuizzes: json['totalQuizzes'] as int,
      totalSubmissions: json['totalSubmissions'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      activeUsersToday: json['activeUsersToday'] as int,
      activeUsersThisWeek: json['activeUsersThisWeek'] as int,
      activeUsersThisMonth: json['activeUsersThisMonth'] as int,
      topPerformingQuizzes: (json['topPerformingQuizzes'] as List<dynamic>)
          .map((e) => QuizAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topPerformingUsers: (json['topPerformingUsers'] as List<dynamic>)
          .map((e) => UserAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      userRoleDistribution: Map<String, int>.from(
        json['userRoleDistribution'] as Map,
      ),
      monthlyAnalytics: (json['monthlyAnalytics'] as List<dynamic>)
          .map((e) => MonthlyAnalyticsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalQuizzes': totalQuizzes,
      'totalSubmissions': totalSubmissions,
      'averageScore': averageScore,
      'activeUsersToday': activeUsersToday,
      'activeUsersThisWeek': activeUsersThisWeek,
      'activeUsersThisMonth': activeUsersThisMonth,
      'topPerformingQuizzes': topPerformingQuizzes
          .map((e) => e.toJson())
          .toList(),
      'topPerformingUsers': topPerformingUsers.map((e) => e.toJson()).toList(),
      'userRoleDistribution': userRoleDistribution,
      'monthlyAnalytics': monthlyAnalytics.map((e) => e.toJson()).toList(),
    };
  }

  SystemAnalytics toDomain() {
    return SystemAnalytics(
      totalUsers: totalUsers,
      totalQuizzes: totalQuizzes,
      totalSubmissions: totalSubmissions,
      averageScore: averageScore,
      activeUsersToday: activeUsersToday,
      activeUsersThisWeek: activeUsersThisWeek,
      activeUsersThisMonth: activeUsersThisMonth,
      topPerformingQuizzes: topPerformingQuizzes
          .map((e) => e.toDomain())
          .toList(),
      topPerformingUsers: topPerformingUsers.map((e) => e.toDomain()).toList(),
      userRoleDistribution: userRoleDistribution,
      monthlyAnalytics: monthlyAnalytics.map((e) => e.toDomain()).toList(),
    );
  }

  factory SystemAnalyticsModel.fromDomain(SystemAnalytics systemAnalytics) {
    return SystemAnalyticsModel(
      totalUsers: systemAnalytics.totalUsers,
      totalQuizzes: systemAnalytics.totalQuizzes,
      totalSubmissions: systemAnalytics.totalSubmissions,
      averageScore: systemAnalytics.averageScore,
      activeUsersToday: systemAnalytics.activeUsersToday,
      activeUsersThisWeek: systemAnalytics.activeUsersThisWeek,
      activeUsersThisMonth: systemAnalytics.activeUsersThisMonth,
      topPerformingQuizzes: systemAnalytics.topPerformingQuizzes
          .map((e) => QuizAnalyticsModel.fromDomain(e))
          .toList(),
      topPerformingUsers: systemAnalytics.topPerformingUsers
          .map((e) => UserAnalyticsModel.fromDomain(e))
          .toList(),
      userRoleDistribution: systemAnalytics.userRoleDistribution,
      monthlyAnalytics: systemAnalytics.monthlyAnalytics
          .map((e) => MonthlyAnalyticsModel.fromDomain(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    totalUsers,
    totalQuizzes,
    totalSubmissions,
    averageScore,
    activeUsersToday,
    activeUsersThisWeek,
    activeUsersThisMonth,
    topPerformingQuizzes,
    topPerformingUsers,
    userRoleDistribution,
    monthlyAnalytics,
  ];
}

class MonthlyAnalyticsModel extends Equatable {
  final DateTime month;
  final int newUsers;
  final int quizAttempts;
  final double averageScore;

  const MonthlyAnalyticsModel({
    required this.month,
    required this.newUsers,
    required this.quizAttempts,
    required this.averageScore,
  });

  factory MonthlyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyAnalyticsModel(
      month: DateTime.parse(json['month'] as String),
      newUsers: json['newUsers'] as int,
      quizAttempts: json['quizAttempts'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'newUsers': newUsers,
      'quizAttempts': quizAttempts,
      'averageScore': averageScore,
    };
  }

  MonthlyAnalytics toDomain() {
    return MonthlyAnalytics(
      month: month,
      newUsers: newUsers,
      quizAttempts: quizAttempts,
      averageScore: averageScore,
    );
  }

  factory MonthlyAnalyticsModel.fromDomain(MonthlyAnalytics monthlyAnalytics) {
    return MonthlyAnalyticsModel(
      month: monthlyAnalytics.month,
      newUsers: monthlyAnalytics.newUsers,
      quizAttempts: monthlyAnalytics.quizAttempts,
      averageScore: monthlyAnalytics.averageScore,
    );
  }

  @override
  List<Object?> get props => [month, newUsers, quizAttempts, averageScore];
}
