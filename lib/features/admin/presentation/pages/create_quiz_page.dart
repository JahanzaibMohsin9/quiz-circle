import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/common/custom_text_field.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../../../../shared/widgets/admin/csv_upload_widget.dart';
import '../../../../shared/widgets/admin/permission_manager_widget.dart';
import '../../presentation/providers/admin_quiz_provider.dart';
import '../../presentation/providers/admin_user_provider.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';

import '../../domain/services/csv_parser_service.dart';
import '../../data/models/csv_quiz_import.dart';
import '../widgets/csv_validation_result_widget.dart';
import '../widgets/quiz_preview_widget.dart';

class CreateQuizPage extends ConsumerStatefulWidget {
  const CreateQuizPage({super.key});

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual Entry'),
            Tab(text: 'CSV Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ManualQuizForm(), CsvImportForm()],
      ),
    );
  }
}

class ManualQuizForm extends ConsumerStatefulWidget {
  const ManualQuizForm({super.key});

  @override
  ConsumerState<ManualQuizForm> createState() => _ManualQuizFormState();
}

class _ManualQuizFormState extends ConsumerState<ManualQuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController(text: '10');
  final _questionsPerAttemptController = TextEditingController(text: '0');
  bool _randomizeQuestions = false;
  final List<Question> _questions = [];

  // Permissions
  QuizPermissions _permissions = const QuizPermissions(
    quizId: '', // Will be assigned by backend
  );
  bool _showPermissions = false;

  void _addQuestion() async {
    final questionTextController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int? selectedOptionIndex;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      (i) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: CustomTextField(
                          controller: optionControllers[i],
                          labelText: 'Option ${i + 1}',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedOptionIndex,
                      items: List.generate(4, (index) {
                        final text = optionControllers[index].text;
                        return DropdownMenuItem(
                          value: index,
                          child: Text(
                            text.isEmpty ? 'Option ${index + 1}' : text,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (v) => setState(() => selectedOptionIndex = v),
                      decoration: const InputDecoration(
                        labelText: 'Correct Answer',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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

                    String correctAnswer = '';
                    if (selectedOptionIndex != null) {
                      correctAnswer =
                          optionControllers[selectedOptionIndex!].text;
                    }

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
                      // Update the parent widget to show the new question count
                      this.setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill question, at least 2 options, and select a valid correct answer',
                          ),
                        ),
                      );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminQuizProvider);
    final controller = ref.read(adminQuizProvider.notifier);
    final usersState = ref.watch(adminUserProvider);

    return SingleChildScrollView(
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
            const SizedBox(height: 8),
            CustomTextField(
              controller: _questionsPerAttemptController,
              labelText: 'Questions Per Attempt (0 = All)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Randomize Questions'),
              subtitle: const Text('Shuffle questions for each attempt'),
              value: _randomizeQuestions,
              onChanged: (val) =>
                  setState(() => _randomizeQuestions = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
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
                  onPermissionsChanged: (p) => setState(() => _permissions = p),
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
              text: state.isLoading ? 'Saving...' : 'Create Quiz',
              onPressed: state.isLoading
                  ? null
                  : () {
                      final title = _titleController.text;
                      final desc = _descController.text;
                      final time = int.tryParse(_timeController.text) ?? 10;
                      final qpa =
                          int.tryParse(_questionsPerAttemptController.text) ??
                          0;
                      if (title.isNotEmpty &&
                          desc.isNotEmpty &&
                          _questions.isNotEmpty) {
                        controller.createQuiz(
                          title,
                          desc,
                          time,
                          _questions,
                          questionsPerAttempt: qpa,
                          randomizeQuestions: _randomizeQuestions,
                          permissions: _permissions,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz created')),
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
          ],
        ),
      ),
    );
  }
}

class CsvImportForm extends ConsumerStatefulWidget {
  const CsvImportForm({super.key});

  @override
  ConsumerState<CsvImportForm> createState() => _CsvImportFormState();
}

class _CsvImportFormState extends ConsumerState<CsvImportForm> {
  final _parserService = CsvParserService();
  bool _isLoading = false;
  CsvQuizImport? _importResult;

  // Permissions for imported quiz
  QuizPermissions _permissions = const QuizPermissions(
    quizId: '',
  );
  bool _showPermissions = false;

  final _questionsPerAttemptController = TextEditingController(text: '0');
  bool _randomizeQuestions = false;

  Future<void> _handleFileSelected(File file) async {
    setState(() {
      _isLoading = true;
      _importResult = null;
    });

    final result = await _parserService.parseQuizCsv(file);

    setState(() {
      _isLoading = false;
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (importData) {
          _importResult = importData;
        },
      );
    });
  }

  void _importQuiz() {
    if (_importResult == null || !_importResult!.isValid) return;

    final metadata = _importResult!.metadata;
    final csvQuestions = _importResult!.questions;

    // Convert CsvQuestions to domain Questions
    var questions = csvQuestions
        .map(
          (q) => Question(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                q.rowNumber.toString(),
            questionText: q.questionText,
            options: q.options,
            correctAnswer: q.correctAnswer,
            imageUrl: q.imageUrl,
            points: q.points,
          ),
        )
        .toList();

    // Apply question selection logic based on user settings
    // This ensures the quiz is created with only the selected number of questions
    final questionsPerAttempt =
        int.tryParse(_questionsPerAttemptController.text) ?? 0;

    if (_randomizeQuestions) {
      questions.shuffle();
    }

    // If a specific question count is selected, limit the questions
    // Note: questionsPerAttempt is also passed to createQuiz for runtime selection,
    // but we limit here to avoid storing unnecessary questions in Firestore
    if (questionsPerAttempt > 0 && questionsPerAttempt < questions.length) {
      questions = questions.take(questionsPerAttempt).toList();
    }

    ref
        .read(adminQuizProvider.notifier)
        .createQuiz(
          metadata.title,
          metadata.description,
          metadata.timeLimitMinutes,
          questions,
          questionsPerAttempt: questionsPerAttempt,
          randomizeQuestions: _randomizeQuestions,
          permissions: _permissions,
          metadata: QuizMetadata(
            category: metadata.category,
            difficulty: metadata.difficulty,
            estimatedDuration: metadata.timeLimitMinutes,
            statistics: const QuizStatistics(),
          ),
        );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quiz imported successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminQuizProvider);
    final usersState = ref.watch(adminUserProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CsvUploadWidget(
            onFileSelected: _handleFileSelected,
            isLoading: _isLoading,
          ),

          if (_importResult != null) ...[
            const SizedBox(height: 24),
            if (!_importResult!.isValid)
              CsvValidationResultWidget(errors: _importResult!.validationErrors)
            else ...[
              QuizPreviewWidget(quizImport: _importResult!),
              const SizedBox(height: 16),

              // Permissions Section for Import
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
              CustomTextField(
                controller: _questionsPerAttemptController,
                labelText: 'Questions Per Attempt (0 = All)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Randomize Questions'),
                subtitle: const Text('Shuffle questions for each attempt'),
                value: _randomizeQuestions,
                onChanged: (val) =>
                    setState(() => _randomizeQuestions = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),
              CustomButton(
                text: state.isLoading ? 'Importing...' : 'Import Quiz',
                onPressed: state.isLoading ? null : _importQuiz,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
