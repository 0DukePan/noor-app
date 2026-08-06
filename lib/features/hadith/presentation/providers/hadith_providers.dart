import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/data/data_sources/local_hadith_data_source.dart';
import '../../../../core/data/repositories/hadith_repository_impl.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/domain/repositories/hadith_repository.dart';
import '../../../../core/algorithms/fsrs_algorithm.dart';

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

/// Specific book details (Metadata, Chapters)
final hadithBookProvider = FutureProvider.family<HadithBook, String>((ref, bookId) async {
  final repository = ref.watch(hadithRepositoryProvider);
  return repository.getBook(bookId);
});

// ═══════════════════════════════════════════════════════════════════════════
// PAGINATED HADITH LIST
// ═══════════════════════════════════════════════════════════════════════════

class PaginatedHadithsState extends Equatable {
  final List<Hadith> hadiths;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const PaginatedHadithsState({
    this.hadiths = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  PaginatedHadithsState copyWith({
    List<Hadith>? hadiths,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return PaginatedHadithsState(
      hadiths: hadiths ?? this.hadiths,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [hadiths, isLoading, error, currentPage, hasMore];
}

class PaginatedHadithsNotifier extends StateNotifier<PaginatedHadithsState> {
  final HadithRepository _repository;
  final String _bookId;
  static const int _limit = 50;

  PaginatedHadithsNotifier(this._repository, this._bookId)
      : super(const PaginatedHadithsState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true);
    try {
      final hadiths = await _repository.getHadiths(_bookId, page: 1, limit: _limit);
      state = state.copyWith(
        hadiths: hadiths,
        isLoading: false,
        currentPage: 1,
        hasMore: hadiths.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final newHadiths = await _repository.getHadiths(
        _bookId, 
        page: nextPage, 
        limit: _limit
      );
      
      state = state.copyWith(
        hadiths: [...state.hadiths, ...newHadiths],
        isLoading: false,
        currentPage: nextPage,
        hasMore: newHadiths.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final paginatedHadithsProvider = StateNotifierProvider.family<PaginatedHadithsNotifier, PaginatedHadithsState, String>((ref, bookId) {
  final repository = ref.watch(hadithRepositoryProvider);
  return PaginatedHadithsNotifier(repository, bookId);
});

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════════════════════════════════════════

final hadithSearchProvider = FutureProvider.family<List<Hadith>, String>((ref, query) async {
  // NOTE: This search requires a bookId context. 
  // Ideally, search should be handled within the page context or global search.
  // For now, we assume search is within the *currently selected book* via a different provider/controller.
  // BUT the architecture usually passes the scope.
  // This simplistic provider might need to be scoped.
  return []; 
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
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Hadith hadith;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.hadith,
  });

  @override
  List<Object?> get props => [question, options, correctAnswer, hadith];
}

class QuizState extends Equatable {
  final QuizType type;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final bool isComplete;
  final String? selectedAnswer;
  final bool showResult;

  const QuizState({
    this.type = QuizType.completeHadith,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isComplete = false,
    this.selectedAnswer,
    this.showResult = false,
  });

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
  final List<Hadith> hadiths;

  QuizNotifier(this.hadiths) : super(const QuizState());

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
                : h.arabic)
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
    
    // Move to next after a delay (handled in UI)
    Future.delayed(const Duration(seconds: 1), () {
      if (isComplete) {
        state = state.copyWith(isComplete: true, showResult: false);
      } else {
        state = state.copyWith(
          currentIndex: nextIndex,
          selectedAnswer: null,
          showResult: false,
        );
      }
    });
  }

  void reset() {
    state = const QuizState();
  }
}

final quizProvider = StateNotifierProvider.family<QuizNotifier, QuizState, List<Hadith>>((ref, hadiths) {
  return QuizNotifier(hadiths);
});

// ═══════════════════════════════════════════════════════════════════════════
// MEMORIZATION SYSTEM (Spaced Repetition)
// ═══════════════════════════════════════════════════════════════════════════

class MemorizationState extends Equatable {
  final List<Hadith> cards;
  final int currentIndex;
  final bool isComplete;
  final Map<int, int> intervals; // hadith id -> days until next review

  const MemorizationState({
    this.cards = const [],
    this.currentIndex = 0,
    this.isComplete = false,
    this.intervals = const {},
  });

  Hadith? get currentCard => 
      cards.isNotEmpty && currentIndex < cards.length ? cards[currentIndex] : null;

  int get todayReviewed => currentIndex; // Simple approximation
  int get totalMemorized => intervals.length;
  List<Hadith> get dueCards => cards; // Simplified
  StreakTracker get streak => StreakTracker(currentStreak: 0); // Simplified

  MemorizationState copyWith({
    List<Hadith>? cards,
    int? currentIndex,
    bool? isComplete,
    Map<int, int>? intervals,
  }) {
    return MemorizationState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
      intervals: intervals ?? this.intervals,
    );
  }

  @override
  List<Object?> get props => [cards, currentIndex, isComplete, intervals];
}

class MemorizationNotifier extends StateNotifier<MemorizationState> {
  MemorizationNotifier() : super(const MemorizationState());

  void loadCards(List<Hadith> hadiths) {
    state = state.copyWith(cards: hadiths, currentIndex: 0, isComplete: false);
  }

  void reviewCard(int rating) {
    // Simplified spaced repetition: rating 1-4 affects interval
    final currentCard = state.currentCard;
    if (currentCard == null) return;

    final newIntervals = Map<int, int>.from(state.intervals);
    final prevInterval = newIntervals[currentCard.id] ?? 1;
    
    // Rating: 1 = Again, 2 = Hard, 3 = Good, 4 = Easy
    int newInterval;
    switch (rating) {
      case 1:
        newInterval = 1;
        break;
      case 2:
        newInterval = prevInterval;
        break;
      case 3:
        newInterval = (prevInterval * 2).clamp(1, 30);
        break;
      case 4:
        newInterval = (prevInterval * 3).clamp(1, 60);
        break;
      default:
        newInterval = prevInterval;
    }
    newIntervals[currentCard.id] = newInterval;

    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.cards.length;

    state = state.copyWith(
      intervals: newIntervals,
      currentIndex: isComplete ? state.currentIndex : nextIndex,
      isComplete: isComplete,
    );
  }

  Map<int, String> getIntervalPreviews() {
    // Returns a map of rating -> human-readable interval
    return {
      1: '1 يوم',
      2: 'نفس الفترة',
      3: 'ضعف الفترة',
      4: '3x الفترة',
    };
  }

  void reset() {
    state = state.copyWith(currentIndex: 0, isComplete: false);
  }
}

final memorizationProvider = StateNotifierProvider<MemorizationNotifier, MemorizationState>((ref) {
  return MemorizationNotifier();
});


