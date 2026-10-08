import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_circle/features/quiz/data/datasources/firestore_quiz_remote_datasource.dart';

void main() {
  group('FirestoreQuizRemoteDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreQuizRemoteDataSource ds;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      ds = FirestoreQuizRemoteDataSource(firestore: firestore);

      await firestore.collection('quizzes').doc('quiz1').set({
        'title': 'Public Quiz',
        'description': 'Desc',
        'timeLimitMinutes': 30,
        'isActive': true,
        'permissions': {
          'type': 'public',
          'isPublic': true,
          'allowedRoles': ['student'],
        },
        'metadata': {
          'category': 'general',
          'difficulty': 'intermediate',
          'estimatedDuration': 30,
        },
        'createdBy': 'admin1',
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });

      await firestore.collection('quizzes').doc('quiz2').set({
        'title': 'Private Quiz',
        'description': 'Desc',
        'timeLimitMinutes': 15,
        'isActive': true,
        'permissions': {
          'type': 'private',
          'isPublic': false,
          'allowedRoles': ['admin'],
        },
        'metadata': {
          'category': 'general',
          'difficulty': 'intermediate',
          'estimatedDuration': 15,
        },
        'createdBy': 'admin1',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      await firestore
          .collection('quizzes')
          .doc('quiz1')
          .collection('questions')
          .doc('q1')
          .set({
            'id': 'q1',
            'questionText': '2+2=?',
            'options': ['3', '4'],
            'correctAnswer': '4',
            'points': 2,
            'order': 1,
          });
      await firestore
          .collection('quizzes')
          .doc('quiz1')
          .collection('questions')
          .doc('q2')
          .set({
            'id': 'q2',
            'questionText': 'Capital of France?',
            'options': ['Paris', 'Rome'],
            'correctAnswer': 'Paris',
            'points': 1,
            'order': 2,
          });

      // Add dummy questions to meet leaderboard threshold (5)
      for (var i = 3; i <= 5; i++) {
        await firestore
            .collection('quizzes')
            .doc('quiz1')
            .collection('questions')
            .doc('q$i')
            .set({
              'id': 'q$i',
              'questionText': 'Q$i',
              'options': ['A', 'B'],
              'correctAnswer': 'A',
              'points': 1,
              'order': i,
            });
      }

      await firestore.collection('users').doc('u1').set({'name': 'Alice'});
      await firestore.collection('users').doc('u2').set({'name': 'Bob'});
    });

    test('getQuizzes returns only active public quizzes', () async {
      final quizzes = await ds.getQuizzes();
      expect(quizzes.length, 1);
      expect(quizzes.first.id, 'quiz1');
      expect(quizzes.first.permissions.allowedRoles.contains('student'), true);
    });

    test('getQuestions returns ordered list', () async {
      final questions = await ds.getQuestions('quiz1');
      expect(questions.length, 5);
      expect(questions.first.id, 'q1');
      expect(questions.last.id, 'q5');
    });

    test('submitQuiz computes score and writes submission', () async {
      final submission = await ds.submitQuiz(
        quizId: 'quiz1',
        quizTitle: 'Public Quiz',
        userId: 'u1',
        answers: {'q1': 'B', 'q2': 'A', 'q3': 'A', 'q4': 'A', 'q5': 'A'},
        timeTakenSeconds: 75,
      );

      expect(submission.quizId, 'quiz1');
      expect(submission.userId, 'u1');
      expect(submission.score, 6); // 2 + 1 + 1 + 1 + 1
      expect(submission.totalQuestions, 5);
      expect(submission.percentage, closeTo(100.0, 0.0001));

      final saved = await firestore
          .collection('submissions')
          .doc(submission.id)
          .get();
      expect(saved.exists, true);
      expect(saved.data()?['completed'], true);
    });

    test(
      'getSubmissions reads user submissions and leaderboard enriches names',
      () async {
        final sub1 = await ds.submitQuiz(
          quizId: 'quiz1',
          quizTitle: 'Public Quiz',
          userId: 'u1',
          answers: {'q1': 'B', 'q2': 'A', 'q3': 'A', 'q4': 'A', 'q5': 'A'},
          timeTakenSeconds: 75,
        );
        final sub2 = await ds.submitQuiz(
          quizId: 'quiz1',
          quizTitle: 'Public Quiz',
          userId: 'u2',
          answers: {'q1': 'A', 'q2': 'A', 'q3': 'A', 'q4': 'A', 'q5': 'A'},
          timeTakenSeconds: 60,
        );

        final mySubs = await ds.getSubmissions('u1');
        expect(mySubs.length, greaterThanOrEqualTo(1));
        expect(mySubs.first.userId, 'u1');

        final leaderboard = await ds.getLeaderboard('quiz1');
        expect(leaderboard.length, 2);
        expect(leaderboard.first['name'], isNotEmpty);
        expect(
          [sub1.userId, sub2.userId].contains(leaderboard.first['userId']),
          true,
        );
      },
    );
  });
}
