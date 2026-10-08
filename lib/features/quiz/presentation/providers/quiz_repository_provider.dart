import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/firestore_quiz_remote_datasource.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final network = ref.watch(connectivityProvider);
  final remote = FirestoreQuizRemoteDataSource();
  return QuizRepositoryImpl(networkInfo: network, remote: remote);
});

