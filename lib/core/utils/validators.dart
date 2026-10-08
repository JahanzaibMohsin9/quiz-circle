import '../constants/app_constants.dart';

class AppValidators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Basic email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return 'Name cannot exceed ${AppConstants.maxNameLength} characters';
    }
    
    // Check for only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }
  
  /// Validate quiz title
  static String? validateQuizTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quiz title is required';
    }
    
    if (value.length < 3) {
      return 'Quiz title must be at least 3 characters';
    }
    
    if (value.length > 100) {
      return 'Quiz title cannot exceed 100 characters';
    }
    
    return null;
  }
  
  /// Validate quiz description
  static String? validateQuizDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quiz description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    
    return null;
  }
  
  /// Validate question text
  static String? validateQuestion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Question is required';
    }
    
    if (value.length < 5) {
      return 'Question must be at least 5 characters';
    }
    
    if (value.length > 200) {
      return 'Question cannot exceed 200 characters';
    }
    
    return null;
  }
  
  /// Validate answer options
  static String? validateOptions(List<String>? options) {
    if (options == null || options.isEmpty) {
      return 'At least one option is required';
    }
    
    if (options.length < 2) {
      return 'At least 2 options are required';
    }
    
    if (options.length > AppConstants.maxOptionsPerQuestion) {
      return 'Cannot exceed ${AppConstants.maxOptionsPerQuestion} options';
    }
    
    // Check for empty options
    for (int i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        return 'Option ${i + 1} cannot be empty';
      }
    }
    
    // Check for duplicate options
    final uniqueOptions = options.map((option) => option.trim().toLowerCase()).toSet();
    if (uniqueOptions.length != options.length) {
      return 'Duplicate options are not allowed';
    }
    
    return null;
  }
  
  /// Validate correct answer index
  static String? validateCorrectAnswer(int? correctAnswer, List<String>? options) {
    if (correctAnswer == null) {
      return 'Please select the correct answer';
    }
    
    if (options == null || options.isEmpty) {
      return 'Options must be provided first';
    }
    
    if (correctAnswer < 0 || correctAnswer >= options.length) {
      return 'Invalid correct answer selection';
    }
    
    return null;
  }
  
  /// Validate quiz time limit
  static String? validateTimeLimit(int? timeLimit) {
    if (timeLimit == null) {
      return 'Time limit is required';
    }
    
    if (timeLimit <= 0) {
      return 'Time limit must be greater than 0';
    }
    
    if (timeLimit > 180) {
      return 'Time limit cannot exceed 180 minutes (3 hours)';
    }
    
    return null;
  }
  
  /// Validate quiz points
  static String? validatePoints(int? points) {
    if (points == null) {
      return 'Points are required';
    }
    
    if (points <= 0) {
      return 'Points must be greater than 0';
    }
    
    if (points > 100) {
      return 'Points cannot exceed 100';
    }
    
    return null;
  }
  
  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate numeric input
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '$fieldName must be a number';
    }
    
    return null;
  }
  
  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final number = int.tryParse(value!);
    if (number == null || number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }
}