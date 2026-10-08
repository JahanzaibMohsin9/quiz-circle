import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/admin_quiz_provider.dart';
import '../../presentation/providers/admin_user_provider.dart';
import '../../../../shared/widgets/common/custom_text_field.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../../../../shared/widgets/admin/permission_manager_widget.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../presentation/providers/admin_usecases.dart';
import '../../domain/usecases/get_quiz_questions.dart';

class EditQuizPage extends ConsumerStatefulWidget {
  final String quizId;
  const EditQuizPage({super.key, required this.quizId});

  @override
  ConsumerState<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends ConsumerState<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  final _questionsPerAttemptController = TextEditingController();
  bool _randomizeQuestions = false;
  final List<Question> _questions = [];

  QuizPermissions _permissions = const QuizPermissions(
    quizId: '',  );
  bool _permissionsLoaded = false;
  bool _showPermissions = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_permissionsLoaded) {
      final state = ref.read(adminQuizProvider);
      try {
        final quiz = state.quizzes.firstWhere(
          (q) => q.id == widget.quizId,
          orElse: () => throw Exception('Quiz not found'),
        );

        _titleController.text = quiz.title;
        _descController.text = quiz.description;
        _timeController.text = quiz.timeLimitMinutes.toString();
        _questionsPerAttemptController.text = quiz.questionsPerAttempt.toString();
        _randomizeQuestions = quiz.randomizeQuestions;

        _permissions = quiz.permissions;

        _permissionsLoaded = true;
        _loadQuestions();
      } catch (e) {
        // Handle error if quiz not found
      }
    }
  }

  Future<void> _loadQuestions() async {
    final result = await ref
        .read(getQuizQuestionsUseCaseProvider)
        .call(GetQuizQuestionsParams(widget.quizId));
    result.fold((l) {}, (qs) {
      if (mounted) {
        setState(() {
          _questions.clear();
          _questions.addAll(qs);
        });
      }
    });
  }

  void _addQuestion() async {
    final questionTextController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    String correctAnswer = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                  controller: questionTextController,
                  labelText: 'Question Text',
                ),
                ...List.generate(
                  4,
                  (i) => CustomTextField(
                    controller: optionControllers[i],
                    labelText: 'Option ${i + 1}',
                  ),
                ),
                DropdownButtonFormField<String>(
                  items: optionControllers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.text,
                          child: Text(c.text.isEmpty ? 'Option' : c.text),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => correctAnswer = v ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CustomButton(
              text: 'Add',
              onPressed: () {
                final options = optionControllers
                    .map((c) => c.text)
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (questionTextController.text.isNotEmpty &&
                    options.length >= 2 &&
                    correctAnswer.isNotEmpty) {
                  _questions.add(
                    Question(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      questionText: questionTextController.text,
                      options: options,
                      correctAnswer: correctAnswer,
                    ),
                  );
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
            ),
            CustomButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              outlined: true,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminQuizProvider);
    final controller = ref.read(adminQuizProvider.notifier);
    final usersState = ref.watch(adminUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              CustomTextField(controller: _titleController, labelText: 'Title'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descController,
                labelText: 'Description',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _timeController,
                labelText: 'Time Limit (minutes)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Permissions Section
              ExpansionTile(
                title: const Text('Permissions & Access Control'),
                initiallyExpanded: _showPermissions,
                onExpansionChanged: (val) =>
                    setState(() => _showPermissions = val),
                children: [
                  PermissionManagerWidget(
                    permissions: _permissions,
                    onPermissionsChanged: (p) =>
                        setState(() => _permissions = p),
                    availableUsers: usersState.users,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  CustomButton(text: 'Add Question', onPressed: _addQuestion),
                  const SizedBox(width: 12),
                  Text('Questions: ${_questions.length}'),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: state.isLoading ? 'Saving...' : 'Update Quiz',
                onPressed: state.isLoading
                    ? null
                    : () {
                        final title = _titleController.text;
                        final desc = _descController.text;
                        final time = int.tryParse(_timeController.text) ?? 10;
                        final qpa = int.tryParse(_questionsPerAttemptController.text) ?? 0;
                        if (title.isNotEmpty && desc.isNotEmpty) {
                          controller.updateQuiz(
                            widget.quizId,
                            title,
                            desc,
                            time,
                            _questions,
                            questionsPerAttempt: qpa,
                            randomizeQuestions: _randomizeQuestions,
                            permissions: _permissions,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quiz updated')),
                          );
                        }
                      },
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                // Extra padding for system navigation
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
