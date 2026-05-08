import 'package:flutter/material.dart';
import 'package:elimupepe/features/quiz/learner_dashboard_api_service.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/core/utils/error_feedback.dart';

class QuizSessionScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> quizItem;

  const QuizSessionScreen({
    super.key,
    required this.title,
    required this.quizItem,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final TextEditingController _textAnswerController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _resultData;
  List<_QuizQuestion> _questions = const [];
  int _currentIndex = 0;
  String? _selectedOptionValue;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  @override
  void dispose() {
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _resultData = null;
      _currentIndex = 0;
      _selectedOptionValue = null;
      _textAnswerController.clear();
    });

    try {
      final response = await LearnerDashboardApiService.instance.startQuiz(
        _buildStartPayload(),
      );

      final questions = _extractQuestions(response);
      if (questions.isEmpty) {
        throw Exception('This quiz did not return any questions.');
      }

      if (!mounted) return;
      setState(() {
        _sessionData = response;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ErrorFeedback.userMessage(e);
      });
    }
  }

  Map<String, dynamic> _buildStartPayload() {
    final quizId =
        widget.quizItem['quiz_id']?.toString() ??
        widget.quizItem['id']?.toString();
    final courseId = widget.quizItem['course_id']?.toString();

    return {
      if (quizId != null) 'quiz_id': quizId,
      if (quizId != null) 'id': quizId,
      if (courseId != null) 'course_id': courseId,
      if (widget.quizItem['slug'] != null) 'slug': widget.quizItem['slug'],
      if (widget.quizItem['title'] != null) 'title': widget.quizItem['title'],
    };
  }

  List<_QuizQuestion> _extractQuestions(Map<String, dynamic>? response) {
    if (response == null) {
      return const [];
    }

    final candidates = [
      response['questions'],
      response['quiz_questions'],
      response['items'],
      response['data'],
      response['quiz'],
      response['session'],
    ];

    for (final candidate in candidates) {
      final rawQuestions = _extractQuestionList(candidate);
      if (rawQuestions.isNotEmpty) {
        return rawQuestions;
      }
    }

    return const [];
  }

  List<_QuizQuestion> _extractQuestionList(dynamic source) {
    if (source is List) {
      return source
          .whereType<Map>()
          .map((item) => _QuizQuestion.fromMap(Map<String, dynamic>.from(item)))
          .where((question) => question.text.isNotEmpty)
          .toList();
    }

    if (source is Map<String, dynamic>) {
      for (final key in const [
        'questions',
        'quiz_questions',
        'items',
        'data',
        'question_list',
      ]) {
        final nested = source[key];
        final nestedQuestions = _extractQuestionList(nested);
        if (nestedQuestions.isNotEmpty) {
          return nestedQuestions;
        }
      }

      if (_looksLikeQuestion(source)) {
        return [_QuizQuestion.fromMap(source)];
      }
    }

    return const [];
  }

  bool _looksLikeQuestion(Map<String, dynamic> source) {
    return source.containsKey('question') ||
        source.containsKey('question_text') ||
        source.containsKey('title') ||
        source.containsKey('options') ||
        source.containsKey('answers');
  }

  Future<void> _submitCurrentAnswer() async {
    final question = _questions[_currentIndex];
    final answerValue = question.options.isNotEmpty
        ? _selectedOptionValue
        : _textAnswerController.text.trim();

    if (answerValue == null || answerValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or enter an answer first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await LearnerDashboardApiService.instance.submitSingleQuestion(
        _buildQuestionSubmitPayload(question, answerValue),
      );

      if (_currentIndex == _questions.length - 1) {
        await _finishQuiz();
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentIndex += 1;
        _selectedOptionValue = null;
        _textAnswerController.clear();
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      if (!mounted) return;
      if (ErrorFeedback.shouldShowDialog(e)) {
        await ErrorFeedback.showErrorDialog(
          context,
          title: 'Quiz action failed',
          error: e,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorFeedback.userMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _buildQuestionSubmitPayload(
    _QuizQuestion question,
    String answerValue,
  ) {
    final quizId = _quizId;
    final questionId = question.id;
    _QuizOption? option;
    for (final candidate in question.options) {
      if (candidate.value == answerValue) {
        option = candidate;
        break;
      }
    }

    return {
      if (quizId != null) 'quiz_id': quizId,
      if (quizId != null) 'id': quizId,
      if (questionId != null) 'question_id': questionId,
      if (questionId != null) 'quiz_question_id': questionId,
      if (_sessionId != null) 'session_id': _sessionId,
      if (_sessionId != null) 'attempt_id': _sessionId,
      'answer': answerValue,
      'selected_answer': answerValue,
      'selected_option': answerValue,
      if (option?.id != null) 'option_id': option?.id,
    };
  }

  Future<void> _finishQuiz() async {
    final quizId = _quizId;
    final finalPayload = {
      if (quizId != null) 'quiz_id': quizId,
      if (quizId != null) 'id': quizId,
      if (_sessionId != null) 'session_id': _sessionId,
      if (_sessionId != null) 'attempt_id': _sessionId,
    };

    try {
      final submitResponse = await LearnerDashboardApiService.instance
          .submitFinalQuiz(finalPayload);
      final resultResponse = await LearnerDashboardApiService.instance
          .fetchQuizResult(finalPayload);

      if (!mounted) return;
      setState(() {
        _resultData = resultResponse ?? submitResponse ?? <String, dynamic>{};
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _resultData = {
          'message': 'Quiz submitted, but results could not be loaded yet.',
        };
      });
    }
  }

  String? get _quizId =>
      widget.quizItem['quiz_id']?.toString() ??
      widget.quizItem['id']?.toString();

  String? get _sessionId {
    final session = _sessionData;
    if (session == null) return null;

    final values = [
      session['session_id'],
      session['attempt_id'],
      session['quiz_session_id'],
      session['id'],
      if (session['session'] is Map<String, dynamic>)
        (session['session'] as Map<String, dynamic>)['id'],
    ];

    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions.isNotEmpty ? _questions[_currentIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lightGreen),
              )
            : _error != null
            ? _buildErrorState()
            : _resultData != null
            ? _buildResultState()
            : question == null
            ? _buildEmptyState()
            : _buildQuestionState(question),
      ),
    );
  }

  Widget _buildErrorState() {
    return ErrorFeedback.buildInlineError(
      context: context,
      title: 'Could not start this quiz',
      error: _error,
      onRetry: _startQuiz,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No quiz questions available right now.',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.textMain,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuestionState(_QuizQuestion question) {
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.darkGray.withValues(alpha: 0.35),
              color: AppColors.lightGreen,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    if (question.hint != null && question.hint!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        question.hint!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (question.options.isNotEmpty)
                      ...question.options.map(_buildOptionTile)
                    else
                      TextField(
                        controller: _textAnswerController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Type your answer here',
                          filled: true,
                          fillColor: AppColors.surfaceGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCurrentAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentIndex == _questions.length - 1
                          ? 'Submit Quiz'
                          : 'Next Question',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(_QuizOption option) {
    final isSelected = _selectedOptionValue == option.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedOptionValue = option.value;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.lightGreen.withValues(alpha: 0.1)
                : AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.lightGreen : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.lightGreen
                        : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightGreen,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultState() {
    final score = _readResultValue(const [
      'score',
      'marks',
      'total_score',
      'result',
    ]);
    final total = _readResultValue(const [
      'total',
      'total_marks',
      'questions_count',
      'total_questions',
    ]);
    final message = _readResultValue(const [
      'message',
      'remarks',
      'feedback',
      'status',
    ]);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentYellow,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quiz Complete',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(height: 12),
              if (score != null)
                Text(
                  total != null ? '$score / $total' : score,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _readResultValue(List<String> keys) {
    final result = _resultData;
    if (result == null) return null;

    for (final key in keys) {
      final value = result[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    final data = result['data'];
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return null;
  }
}

class _QuizQuestion {
  final String? id;
  final String text;
  final String? hint;
  final List<_QuizOption> options;

  const _QuizQuestion({
    required this.id,
    required this.text,
    required this.hint,
    required this.options,
  });

  factory _QuizQuestion.fromMap(Map<String, dynamic> map) {
    final text =
        map['question']?.toString() ??
        map['question_text']?.toString() ??
        map['title']?.toString() ??
        map['text']?.toString() ??
        '';

    final optionSources = [
      map['options'],
      map['answers'],
      map['choices'],
      map['question_options'],
    ];

    List<_QuizOption> options = const [];
    for (final source in optionSources) {
      final normalized = _QuizOption.fromDynamicList(source);
      if (normalized.isNotEmpty) {
        options = normalized;
        break;
      }
    }

    return _QuizQuestion(
      id: map['question_id']?.toString() ?? map['id']?.toString(),
      text: text.trim(),
      hint:
          map['hint']?.toString() ??
          map['instruction']?.toString() ??
          map['description']?.toString(),
      options: options,
    );
  }
}

class _QuizOption {
  final String? id;
  final String label;
  final String value;

  const _QuizOption({
    required this.id,
    required this.label,
    required this.value,
  });

  static List<_QuizOption> fromDynamicList(dynamic source) {
    if (source is! List) {
      return const [];
    }

    return source
        .map((item) {
          if (item is Map<String, dynamic>) {
            final label =
                item['text']?.toString() ??
                item['label']?.toString() ??
                item['answer']?.toString() ??
                item['title']?.toString() ??
                item['name']?.toString() ??
                '';
            final value =
                item['value']?.toString() ??
                item['id']?.toString() ??
                item['answer']?.toString() ??
                label;

            return _QuizOption(
              id: item['id']?.toString() ?? item['option_id']?.toString(),
              label: label.isNotEmpty ? label : value,
              value: value,
            );
          }

          final text = item.toString();
          return _QuizOption(id: null, label: text, value: text);
        })
        .where((option) => option.label.trim().isNotEmpty)
        .toList();
  }
}
