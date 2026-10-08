class AppConstants {
  // App Information
  static const String appName = 'Quiz App';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration splashDelay = Duration(seconds: 2);
  
  // Quiz Configuration
  static const int defaultQuizTimeLimit = 30; // minutes
  static const int maxQuestionsPerQuiz = 50;
  static const int maxOptionsPerQuestion = 6;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // File Upload Limits
  static const int maxImageSizeMB = 5;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  
  // Cache Keys
  static const String userCacheKey = 'user_cache';
  static const String themeCacheKey = 'theme_cache';
}