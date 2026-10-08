import 'package:equatable/equatable.dart';

enum DateRange { today, week, month, quarter, year, all }

class QuizAnalytics extends Equatable {
  final String quizId;
  final String quizTitle;
  final int totalAttempts;
  final double averageScore;
  final double averagePercentage;
  final int totalParticipants;
  final double completionRate;
  final int averageTimeSeconds;
  final List<QuestionAnalytics> questionAnalytics;
  final List<DailyAnalytics> dailyAnalytics;

  const QuizAnalytics({
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

class QuestionAnalytics extends Equatable {
  final String questionId;
  final String questionText;
  final Map<String, int> answerCounts; // answer -> count
  final String correctAnswer;
  final int correctAnswerCount;
  final double correctAnswerPercentage;

  const QuestionAnalytics({
    required this.questionId,
    required this.questionText,
    required this.answerCounts,
    required this.correctAnswer,
    required this.correctAnswerCount,
    required this.correctAnswerPercentage,
  });

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

class DailyAnalytics extends Equatable {
  final DateTime date;
  final int attempts;
  final double averageScore;
  final double averagePercentage;
  final int uniqueParticipants;

  const DailyAnalytics({
    required this.date,
    required this.attempts,
    required this.averageScore,
    required this.averagePercentage,
    required this.uniqueParticipants,
  });

  @override
  List<Object?> get props => [
    date,
    attempts,
    averageScore,
    averagePercentage,
    uniqueParticipants,
  ];
}

class UserAnalytics extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final int totalQuizzesTaken;
  final int totalScore;
  final double averagePercentage;
  final int totalTimeSpentSeconds;
  final List<QuizAttemptAnalytics> quizAttempts;
  final DateTime? lastActivity;

  const UserAnalytics({
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

class QuizAttemptAnalytics extends Equatable {
  final String quizId;
  final String quizTitle;
  final int score;
  final double percentage;
  final DateTime attemptDate;
  final int timeTakenSeconds;
  final bool completed;

  const QuizAttemptAnalytics({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.percentage,
    required this.attemptDate,
    required this.timeTakenSeconds,
    required this.completed,
  });

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

class SystemAnalytics extends Equatable {
  final int totalUsers;
  final int totalQuizzes;
  final int totalSubmissions;
  final double averageScore;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int activeUsersThisMonth;
  final List<QuizAnalytics> topPerformingQuizzes;
  final List<UserAnalytics> topPerformingUsers;
  final Map<String, int> userRoleDistribution;
  final List<MonthlyAnalytics> monthlyAnalytics;

  const SystemAnalytics({
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

class MonthlyAnalytics extends Equatable {
  final DateTime month;
  final int newUsers;
  final int quizAttempts;
  final double averageScore;

  const MonthlyAnalytics({
    required this.month,
    required this.newUsers,
    required this.quizAttempts,
    required this.averageScore,
  });

  @override
  List<Object?> get props => [month, newUsers, quizAttempts, averageScore];
}
