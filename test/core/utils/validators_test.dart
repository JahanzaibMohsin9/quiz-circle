import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_circle/core/utils/validators.dart';
import 'package:quiz_circle/core/constants/app_constants.dart';

void main() {
  group('AppValidators', () {
    test('validateEmail rejects null/empty and invalid formats', () {
      expect(AppValidators.validateEmail(null), 'Email is required');
      expect(AppValidators.validateEmail(''), 'Email is required');
      expect(
        AppValidators.validateEmail('invalid'),
        'Please enter a valid email address',
      );
      expect(
        AppValidators.validateEmail('user@domain'),
        'Please enter a valid email address',
      );
      expect(AppValidators.validateEmail('user@domain.com'), isNull);
    });

    test('validatePassword enforces length and character rules', () {
      expect(AppValidators.validatePassword(null), 'Password is required');
      expect(AppValidators.validatePassword(''), 'Password is required');
      final short = 'Ab1';
      expect(
        AppValidators.validatePassword(short),
        'Password must be at least ${AppConstants.minPasswordLength} characters',
      );
      expect(
        AppValidators.validatePassword('abcdef1'),
        'Password must contain at least one uppercase letter',
      );
      expect(
        AppValidators.validatePassword('ABCDEF1'),
        'Password must contain at least one lowercase letter',
      );
      expect(
        AppValidators.validatePassword('Abcdefg'),
        'Password must contain at least one number',
      );
      expect(AppValidators.validatePassword('Abcdef1'), isNull);
    });

    test('validateConfirmPassword compares with original', () {
      expect(
        AppValidators.validateConfirmPassword('', 'pass'),
        'Please confirm your password',
      );
      expect(
        AppValidators.validateConfirmPassword('pass', 'other'),
        'Passwords do not match',
      );
      expect(AppValidators.validateConfirmPassword('pass', 'pass'), isNull);
    });

    test('validateName allows letters and spaces within length', () {
      expect(AppValidators.validateName(null), 'Name is required');
      expect(AppValidators.validateName(''), 'Name is required');
      final longName = 'A' * (AppConstants.maxNameLength + 1);
      expect(
        AppValidators.validateName(longName),
        'Name cannot exceed ${AppConstants.maxNameLength} characters',
      );
      expect(AppValidators.validateName('John Doe'), isNull);
      expect(
        AppValidators.validateName('John_Doe'),
        'Name can only contain letters and spaces',
      );
    });

    test('validateQuizTitle and description bounds', () {
      expect(AppValidators.validateQuizTitle(''), 'Quiz title is required');
      expect(
        AppValidators.validateQuizTitle('ab'),
        'Quiz title must be at least 3 characters',
      );
      expect(
        AppValidators.validateQuizTitle('a' * 101),
        'Quiz title cannot exceed 100 characters',
      );
      expect(AppValidators.validateQuizTitle('Valid Title'), isNull);

      expect(
        AppValidators.validateQuizDescription(''),
        'Quiz description is required',
      );
      expect(
        AppValidators.validateQuizDescription('short'),
        'Description must be at least 10 characters',
      );
      expect(
        AppValidators.validateQuizDescription('a' * 501),
        'Description cannot exceed 500 characters',
      );
      expect(
        AppValidators.validateQuizDescription('This is a valid description.'),
        isNull,
      );
    });

    test('validateOptions enforces count, non-empty and uniqueness', () {
      expect(
        AppValidators.validateOptions(null),
        'At least one option is required',
      );
      expect(
        AppValidators.validateOptions([]),
        'At least one option is required',
      );
      expect(
        AppValidators.validateOptions(['A']),
        'At least 2 options are required',
      );
      expect(
        AppValidators.validateOptions(
          List.filled(AppConstants.maxOptionsPerQuestion + 1, 'A'),
        ),
        'Cannot exceed ${AppConstants.maxOptionsPerQuestion} options',
      );
      expect(
        AppValidators.validateOptions(['', 'B']),
        'Option 1 cannot be empty',
      );
      expect(
        AppValidators.validateOptions(['A', 'a']),
        'Duplicate options are not allowed',
      );
      expect(AppValidators.validateOptions(['A', 'B', 'C']), isNull);
    });

    test('validateCorrectAnswer checks index bounds', () {
      expect(
        AppValidators.validateCorrectAnswer(null, ['A', 'B']),
        'Please select the correct answer',
      );
      expect(
        AppValidators.validateCorrectAnswer(0, null),
        'Options must be provided first',
      );
      expect(
        AppValidators.validateCorrectAnswer(2, ['A', 'B']),
        'Invalid correct answer selection',
      );
      expect(AppValidators.validateCorrectAnswer(1, ['A', 'B']), isNull);
    });

    test('validateTimeLimit and points bounds', () {
      expect(AppValidators.validateTimeLimit(null), 'Time limit is required');
      expect(
        AppValidators.validateTimeLimit(0),
        'Time limit must be greater than 0',
      );
      expect(
        AppValidators.validateTimeLimit(181),
        'Time limit cannot exceed 180 minutes (3 hours)',
      );
      expect(AppValidators.validateTimeLimit(60), isNull);

      expect(AppValidators.validatePoints(null), 'Points are required');
      expect(AppValidators.validatePoints(0), 'Points must be greater than 0');
      expect(AppValidators.validatePoints(101), 'Points cannot exceed 100');
      expect(AppValidators.validatePoints(10), isNull);
    });

    test('validate required and numeric inputs', () {
      expect(AppValidators.validateRequired(' ', 'Field'), 'Field is required');
      expect(AppValidators.validateRequired('ok', 'Field'), isNull);
      expect(AppValidators.validateNumeric('', 'Age'), 'Age is required');
      expect(
        AppValidators.validateNumeric('abc', 'Age'),
        'Age must be a number',
      );
      expect(AppValidators.validateNumeric('12', 'Age'), isNull);
      expect(
        AppValidators.validatePositiveNumber('0', 'Age'),
        'Age must be greater than 0',
      );
      expect(AppValidators.validatePositiveNumber('5', 'Age'), isNull);
    });
  });
}
