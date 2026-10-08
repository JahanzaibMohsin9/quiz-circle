class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String quizzesCollection = 'quizzes';
  static const String quizQuestionsCollection = 'quiz_questions';
  static const String submissionsCollection = 'submissions';
  static const String leaderboardCollection = 'leaderboard';
  static const String announcementsCollection = 'announcements';
  
  // User Fields
  static const String userIdField = 'id';
  static const String nameField = 'name';
  static const String emailField = 'email';
  static const String roleField = 'role';
  static const String allowedQuizzesField = 'allowedQuizzes';
  static const String totalScoreField = 'totalScore';
  static const String averagePercentageField = 'averagePercentage';
  static const String createdAtField = 'createdAt';
  static const String lastLoginAtField = 'lastLoginAt';
  static const String isActiveField = 'isActive';
  
  // Quiz Fields
  static const String quizIdField = 'id';
  static const String titleField = 'title';
  static const String descriptionField = 'description';
  static const String createdByField = 'createdBy';
  static const String timeLimitField = 'timeLimit';
  static const String shuffleQuestionsField = 'shuffleQuestions';
  static const String shuffleOptionsField = 'shuffleOptions';
  static const String showCorrectAnswersField = 'showCorrectAnswers';
  static const String allowMultipleAttemptsField = 'allowMultipleAttempts';
  static const String maxAttemptsField = 'maxAttempts';
  
  // Question Fields
  static const String questionField = 'question';
  static const String optionsField = 'options';
  static const String correctAnswerField = 'correctAnswer';
  static const String imageUrlField = 'imageUrl';
  static const String pointsField = 'points';
  
  // Submission Fields
  static const String submissionIdField = 'id';
  static const String submissionQuizIdField = 'quizId';
  static const String submissionUserIdField = 'userId';
  static const String scoreField = 'score';
  static const String totalField = 'total';
  static const String percentageField = 'percentage';
  static const String submittedAtField = 'submittedAt';
  static const String answersField = 'answers';
  static const String timeTakenField = 'timeTaken';
  
  // Leaderboard Fields
  static const String rankField = 'rank';
  static const String leaderboardUserNameField = 'userName';
  
  // Announcement Fields
  static const String announcementIdField = 'id';
  static const String announcementTitleField = 'title';
  static const String messageField = 'message';
  static const String timestampField = 'timestamp';
  static const String authorIdField = 'authorId';
  static const String authorNameField = 'authorName';
  
  // Storage Paths
  static const String quizImagesPath = 'quiz_images';
  static const String profileImagesPath = 'profile_images';
  
  // User Roles
  static const String studentRole = 'student';
  static const String adminRole = 'admin';
}