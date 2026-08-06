import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/domain/entities/hadith.dart'; // Use the core entity
import '../providers/hadith_providers.dart';

/// صفحة الاختبارات - Quiz Page
class QuizPage extends ConsumerStatefulWidget {
  final List<Hadith> hadiths;
  final QuizType quizType;

  const QuizPage({
    super.key,
    required this.hadiths,
    this.quizType = QuizType.completeHadith,
  });

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider(widget.hadiths).notifier).startQuiz(
            widget.quizType,
            questionCount: 10,
          );
    });
  }

  void _selectAnswer(String answer) {
    HapticFeedback.selectionClick();
    ref.read(quizProvider(widget.hadiths).notifier).answerQuestion(answer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider(widget.hadiths));

    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: Text(_getQuizTitle(state.type)),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
        actions: [
          // Score display
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: NoorTheme.hadithSahih.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: NoorTheme.accentGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${state.score}/${state.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isComplete
          ? _buildResultScreen(state)
          : state.currentQuestion != null
              ? _buildQuestionScreen(state)
              : const Center(child: CircularProgressIndicator()),
    );
  }

  String _getQuizTitle(QuizType type) {
    switch (type) {
      case QuizType.completeHadith:
        return 'أكمل الحديث';
      case QuizType.chooseCorrect:
        return 'اختر الصحيح';
      case QuizType.identifyNarrator:
        return 'حدد الراوي';
      case QuizType.gradeHadith:
        return 'درجة الحديث';
    }
  }

  Widget _buildQuestionScreen(QuizState state) {
    final question = state.currentQuestion!;
    final progress = state.questions.isEmpty 
        ? 0.0 
        : (state.currentIndex + 1) / state.questions.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السؤال ${state.currentIndex + 1} من ${state.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 32),
                      const SizedBox(height: 16),
                      Text(
                        question.question,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Amiri',
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Answer options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = state.selectedAnswer == option;
                  final isCorrect = option == question.correctAnswer;
                  final showFeedback = state.showResult;

                  Color? bgColor;
                  Color? borderColor;
                  if (showFeedback) {
                    if (isCorrect) {
                      bgColor = NoorTheme.hadithSahih.withOpacity(0.2);
                      borderColor = NoorTheme.hadithSahih;
                    } else if (isSelected) {
                      bgColor = NoorTheme.hadithDaif.withOpacity(0.2);
                      borderColor = NoorTheme.hadithDaif;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: bgColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: state.showResult ? null : () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor ?? Colors.grey.shade300,
                              width: borderColor != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text('${index + 1}'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              if (showFeedback && isCorrect)
                                const Icon(Icons.check_circle, color: NoorTheme.hadithSahih)
                              else if (showFeedback && isSelected && !isCorrect)
                                const Icon(Icons.cancel, color: NoorTheme.hadithDaif),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen(QuizState state) {
    final percentage = state.questions.isEmpty 
        ? 0 
        : ((state.score / state.questions.length) * 100).round();
    final isPassed = percentage >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed 
                    ? NoorTheme.hadithSahih.withOpacity(0.2)
                    : NoorTheme.hadithDaif.withOpacity(0.2),
              ),
              child: Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 60,
                color: isPassed ? NoorTheme.hadithSahih : NoorTheme.hadithDaif,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              isPassed ? 'أحسنت!' : 'حاول مرة أخرى',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Score
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall,
                children: [
                  TextSpan(
                    text: '$percentage',
                    style: TextStyle(
                      color: isPassed ? NoorTheme.hadithSahih : NoorTheme.hadithDaif,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                  const TextSpan(text: '%'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '${state.score} من ${state.questions.length} إجابات صحيحة',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),

            // Retry Button
            FilledButton.icon(
              onPressed: () {
                ref.read(quizProvider(widget.hadiths).notifier).startQuiz(
                  widget.quizType,
                  questionCount: 10,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة الاختبار'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Back Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}
