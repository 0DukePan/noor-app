import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/algorithms/fsrs_algorithm.dart';
import '../../../../core/data/data_sources/local_hadith_data_source.dart';
import '../../../../core/data/repositories/hadith_repository_impl.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/domain/repositories/hadith_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY & DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

final localHadithDataSourceProvider = Provider<LocalHadithDataSource>((ref) {
  return LocalHadithDataSource();
});

final hadithRepositoryProvider = Provider<HadithRepository>((ref) {
  final dataSource = ref.watch(localHadithDataSourceProvider);
  return HadithRepositoryImpl(dataSource);
});

// ═══════════════════════════════════════════════════════════════════════════
// USE CASE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// List of all available collections
final hadithCollectionsProvider = FutureProvider<List<HadithCollection>>((ref) async {
  final repository = ref.watch(hadithRepositoryProvider);
  return repository.getCollections();
});

/// Lightweight book summary (metadata + chapters, no hadith rows).
final hadithBookSummaryProvider =
    FutureProvider.family<HadithBook, String>((ref, bookId) async {
  return ref.watch(localHadithDataSourceProvider).getBookSummary(bookId);
});

/// Per-chapter hadith counts (SQL GROUP BY — O(chapters), not O(hadiths)).
final hadithChapterCountsProvider =
    FutureProvider.family<Map<int, int>, String>((ref, bookId) async {
  return ref.watch(localHadithDataSourceProvider).getChapterHadithCounts(bookId);
});

// ═══════════════════════════════════════════════════════════════════════════
// QUIZ SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

enum QuizType {
  completeHadith,
  chooseCorrect,
  identifyNarrator,
  gradeHadith,
}

class QuizQuestion extends Equatable {

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.hadith,
  });
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Hadith hadith;

  @override
  List<Object?> get props => [question, options, correctAnswer, hadith];
}

class QuizState extends Equatable {

  const QuizState({
    this.type = QuizType.completeHadith,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isComplete = false,
    this.selectedAnswer,
    this.showResult = false,
  });
  final QuizType type;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final bool isComplete;
  final String? selectedAnswer;
  final bool showResult;

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length 
        ? questions[currentIndex] 
        : null;

  QuizState copyWith({
    QuizType? type,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    bool? isComplete,
    String? selectedAnswer,
    bool? showResult,
  }) {
    return QuizState(
      type: type ?? this.type,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isComplete: isComplete ?? this.isComplete,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      showResult: showResult ?? this.showResult,
    );
  }

  @override
  List<Object?> get props => [type, questions, currentIndex, score, isComplete, selectedAnswer, showResult];
}

class QuizNotifier extends StateNotifier<QuizState> {

  QuizNotifier(this.hadiths) : super(const QuizState());
  final List<Hadith> hadiths;

  void startQuiz(QuizType type, {int questionCount = 10}) {
    // Generate questions from hadiths
    final shuffled = List<Hadith>.from(hadiths)..shuffle();
    final selected = shuffled.take(questionCount).toList();

    final questions = selected.map((hadith) {
      final text = hadith.arabic;
      final words = text.split(' ');

      // Gather distractor texts from other hadiths
      final otherHadiths = List<Hadith>.from(hadiths)
        ..remove(hadith)
        ..shuffle();

      if (words.length < 5) {
        // Simple "What is the hadith text?" question
        final distractors = otherHadiths
            .take(3)
            .map((h) => h.arabic.length > 100
                ? '${h.arabic.substring(0, 100)}...'
                : h.arabic,)
            .toList();

        return QuizQuestion(
          question: 'ما هو نص الحديث؟',
          options: ([text, ...distractors]..shuffle()),
          correctAnswer: text,
          hadith: hadith,
        );
      }

      final half = words.length ~/ 2;
      final partial = '${words.sublist(0, half).join(' ')}...';
      final completion = words.sublist(half).join(' ');

      // Build distractor completions from other hadiths
      final distractorCompletions = <String>[];
      for (final other in otherHadiths) {
        if (distractorCompletions.length >= 3) break;
        final otherWords = other.arabic.split(' ');
        if (otherWords.length > half) {
          distractorCompletions.add(otherWords.sublist(half).join(' '));
        } else if (otherWords.length > 3) {
          distractorCompletions.add(otherWords.sublist(otherWords.length ~/ 2).join(' '));
        }
      }

      // Ensure we always have 3 distractors
      while (distractorCompletions.length < 3) {
        distractorCompletions.add(
          otherHadiths.isNotEmpty
              ? otherHadiths[distractorCompletions.length % otherHadiths.length].arabic
              : 'لا يوجد',
        );
      }

      return QuizQuestion(
        question: partial,
        options: ([completion, ...distractorCompletions.take(3)]..shuffle()),
        correctAnswer: completion,
        hadith: hadith,
      );
    }).toList();

    state = state.copyWith(
      type: type,
      questions: questions,
      currentIndex: 0,
      score: 0,
      isComplete: false,
    );
  }

  void answerQuestion(String answer) {
    if (state.currentQuestion == null) return;

    final isCorrect = answer == state.currentQuestion!.correctAnswer;
    final newScore = isCorrect ? state.score + 1 : state.score;
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.questions.length;

    state = state.copyWith(
      selectedAnswer: answer,
      showResult: true,
      score: newScore,
    );

    // Persist the finished quiz to the history box (read by the stats page).
    if (isComplete) {
      _saveQuizResult(newScore, state.questions.length);
    }
    
    // Move to next after a delay (handled in UI)
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (isComplete) {
        state = state.copyWith(isComplete: true, showResult: false);
      } else {
        state = state.copyWith(
          currentIndex: nextIndex,
          showResult: false,
        );
      }
    });
  }

  void reset() {
    state = const QuizState();
  }

  /// Append the finished quiz result to the `quiz_history` Hive box so the
  /// learning-statistics page can show real quiz data. Keys are timestamped
  /// so multiple quizzes on the same day are all kept.
  Future<void> _saveQuizResult(int score, int total) async {
    try {
      final box = await Hive.openBox<dynamic>('quiz_history');
      final now = DateTime.now();
      await box.put(
        'quiz_${now.millisecondsSinceEpoch}',
        {
          'score': score,
          'total': total,
          'date': now.toIso8601String(),
        },
      );
    } on Exception catch (_) {
      // Best-effort persistence; the stats page degrades gracefully.
    }
  }
}

final quizProvider = StateNotifierProvider.family<QuizNotifier, QuizState, List<Hadith>>((ref, hadiths) {
  return QuizNotifier(hadiths);
});

// ═══════════════════════════════════════════════════════════════════════════
// MEMORIZATION SYSTEM (FSRS Spaced Repetition)
// ═══════════════════════════════════════════════════════════════════════════

class MemorizationState extends Equatable {

  const MemorizationState({
    required this.streak, this.deck = const [],
    this.fsrsCards = const {},
    this.currentIndex = 0,
    this.isComplete = false,
  });
  final List<Hadith> deck;
  final Map<String, MemorizationCard> fsrsCards;
  final int currentIndex;
  final bool isComplete;
  final StreakTracker streak;

  Hadith? get currentCard =>
      deck.isNotEmpty && currentIndex < deck.length ? deck[currentIndex] : null;

  MemorizationCard? get currentFsrsCard {
    final card = currentCard;
    if (card == null) return null;
    return fsrsCards[card.id.toString()];
  }

  /// Hadiths due for review today (new cards are always due).
  List<Hadith> get dueCards =>
      deck.where((h) => fsrsCards[h.id.toString()]?.isDue ?? true).toList();

  int get todayReviewed =>
      fsrsCards.values.where((c) => c.repetitions > 0 && _isToday(c.lastReview)).length;

  int get totalMemorized =>
      fsrsCards.values.where((c) => c.repetitions > 0).length;

  MemorizationState copyWith({
    List<Hadith>? deck,
    Map<String, MemorizationCard>? fsrsCards,
    int? currentIndex,
    bool? isComplete,
    StreakTracker? streak,
  }) {
    return MemorizationState(
      deck: deck ?? this.deck,
      fsrsCards: fsrsCards ?? this.fsrsCards,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
      streak: streak ?? this.streak,
    );
  }

  @override
  List<Object?> get props => [deck, fsrsCards, currentIndex, isComplete, streak];

  static bool _isToday(DateTime time) {
    final now = DateTime.now();
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }
}

class MemorizationNotifier extends StateNotifier<MemorizationState> {
  MemorizationNotifier() : super(MemorizationState(streak: StreakTracker()));

  static const _boxName = 'memorization_cards';
  Box<dynamic>? _box;

  Future<void> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  /// Load the deck of hadiths to memorize, restoring persisted FSRS state.
  Future<void> loadCards(List<Hadith> hadiths) async {
    await _ensureBox();
    final fsrsCards = <String, MemorizationCard>{};
    for (final h in hadiths) {
      final key = h.id.toString();
      final raw = _box!.get(key);
      fsrsCards[key] = raw != null
          ? MemorizationCard.fromJson(Map<String, dynamic>.from(raw as Map))
          : MemorizationCard(id: key, hadithId: key);
    }
    var streak = StreakTracker();
    final streakRaw = _box!.get('_streak');
    if (streakRaw != null) {
      streak = StreakTracker.fromJson(Map<String, dynamic>.from(streakRaw as Map));
    }
    state = MemorizationState(
      deck: hadiths,
      fsrsCards: fsrsCards,
      streak: streak,
    );
  }

  /// Review the current card with a 1..4 rating (1 = again, 4 = easy).
  ///
  /// In-memory state updates FIRST so the UI advances instantly; persistence
  /// follows fire-and-forget and must never block or fail the review (the
  /// qada notifier uses the same pattern: memory authoritative, Hive best
  /// effort). Awaiting the puts here would also stall forever inside
  /// widget tests, where Hive write-flushes never complete.
  Future<void> reviewCard(int rating) async {
    final card = state.currentFsrsCard;
    if (card == null) return;
    card.review(_ratingFromInt(rating));

    final streak = state.streak..recordPractice();
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.deck.length;

    state = state.copyWith(
      fsrsCards: {...state.fsrsCards, card.hadithId: card},
      streak: streak,
      currentIndex: isComplete ? state.currentIndex : nextIndex,
      isComplete: isComplete,
    );
    unawaited(_persistReview(card, streak));
  }

  Future<void> _persistReview(
    MemorizationCard card,
    StreakTracker streak,
  ) async {
    try {
      await _ensureBox();
      await _box?.put(card.hadithId, card.toJson());
      await _box?.put('_streak', streak.toJson());
    } on Object catch (e) {
      // Persistence failure must never surface an unhandled async error;
      // in-memory state stays authoritative. Anything else rethrows.
      if (e is! HiveError) rethrow;
    }
  }

  Map<int, String> getIntervalPreviews() {
    final card = state.currentFsrsCard;
    if (card == null) {
      return const {
        1: '1 يوم',
        2: 'نفس الفترة',
        3: 'ضعف الفترة',
        4: '3x الفترة',
      };
    }
    final previews = card.previewIntervals();
    return {
      for (final entry in previews.entries)
        entry.key.index + 1: '${entry.value} يوم',
    };
  }

  void reset() {
    state = state.copyWith(currentIndex: 0, isComplete: false);
  }

  static Rating _ratingFromInt(int rating) {
    switch (rating) {
      case 1:
        return Rating.again;
      case 2:
        return Rating.hard;
      case 3:
        return Rating.good;
      case 4:
        return Rating.easy;
      default:
        return Rating.good;
    }
  }
}

final memorizationProvider = StateNotifierProvider<MemorizationNotifier, MemorizationState>((ref) {
  return MemorizationNotifier();
});
