import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_circle/core/validators/schema_validators.dart';
import 'package:quiz_circle/features/authentication/domain/entities/user.dart';
import 'package:quiz_circle/features/quiz/domain/entities/submission.dart';

void main() {
  group('SchemaValidators', () {
    group('validateUser()', () {
      test('should accept valid user', () {
        final user = const User(
          id: 'user123',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.student,
          totalScore: 100,
          averagePercentage: 85.5,
        );

        expect(() => SchemaValidators.validateUser(user), returnsNormally);
      });

      test('should throw on empty user ID', () {
        final user = const User(
          id: '',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.student,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('User ID cannot be empty'),
            ),
          ),
        );
      });

      test('should throw on empty name', () {
        final user = const User(
          id: 'user123',
          name: '',
          email: 'john@example.com',
          role: UserRole.student,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('User name must be 1-100 characters'),
            ),
          ),
        );
      });

      test('should throw on name longer than 100 characters', () {
        final user = User(
          id: 'user123',
          name: 'A' * 101,
          email: 'john@example.com',
          role: UserRole.student,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('User name must be 1-100 characters'),
            ),
          ),
        );
      });

      test('should throw on invalid email format', () {
        final user = const User(
          id: 'user123',
          name: 'John Doe',
          email: 'invalid-email',
          role: UserRole.student,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid email format'),
            ),
          ),
        );
      });

      test('should throw on negative totalScore', () {
        final user = const User(
          id: 'user123',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.student,
          totalScore: -10,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Total score cannot be negative'),
            ),
          ),
        );
      });

      test('should throw on averagePercentage less than 0', () {
        final user = const User(
          id: 'user123',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.student,
          averagePercentage: -5.0,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Average percentage must be between 0-100'),
            ),
          ),
        );
      });

      test('should throw on averagePercentage greater than 100', () {
        final user = const User(
          id: 'user123',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.student,
          averagePercentage: 105.0,
        );

        expect(
          () => SchemaValidators.validateUser(user),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Average percentage must be between 0-100'),
            ),
          ),
        );
      });
    });

    group('validateSubmission()', () {
      test('should accept valid submission', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: 80,
          totalQuestions: 10,
          percentage: 80.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A', 'q2': 'B'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          returnsNormally,
        );
      });

      test('should throw on empty quizId', () {
        final submission = Submission(
          id: 'sub123',
          quizId: '',
          userId: 'user123',
          score: 80,
          totalQuestions: 10,
          percentage: 80.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Quiz ID cannot be empty'),
            ),
          ),
        );
      });

      test('should throw on empty userId', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: '',
          score: 80,
          totalQuestions: 10,
          percentage: 80.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('User ID cannot be empty'),
            ),
          ),
        );
      });

      test('should throw on negative score', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: -10,
          totalQuestions: 10,
          percentage: 0.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Score cannot be negative'),
            ),
          ),
        );
      });

      test('should throw on percentage less than 0', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: 0,
          totalQuestions: 10,
          percentage: -5.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Percentage must be between 0-100'),
            ),
          ),
        );
      });

      test('should throw on percentage greater than 100', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: 100,
          totalQuestions: 10,
          percentage: 105.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Percentage must be between 0-100'),
            ),
          ),
        );
      });

      test('should throw on negative timeTakenSeconds', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: 80,
          totalQuestions: 10,
          percentage: 80.0,
          submittedAt: DateTime.now(),
          answers: const {'q1': 'A'},
          timeTakenSeconds: -100,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Time taken cannot be negative'),
            ),
          ),
        );
      });

      test('should throw on empty answers map', () {
        final submission = Submission(
          id: 'sub123',
          quizId: 'quiz123',
          userId: 'user123',
          score: 0,
          totalQuestions: 10,
          percentage: 0.0,
          submittedAt: DateTime.now(),
          answers: const {},
          timeTakenSeconds: 300,
        );

        expect(
          () => SchemaValidators.validateSubmission(submission),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Submission must have at least one answer'),
            ),
          ),
        );
      });
    });
  });
}
