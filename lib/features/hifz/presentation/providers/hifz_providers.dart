import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';

import '../../data/hifz_ayah_card.dart';

/// حالة الحفظ: البطاقات + سلسلة الممارسة اليومية.
class HifzState {

  HifzState({List<HifzAyahCard>? cards, StreakTracker? streak})
      : cards = cards ?? const [],
        streak = streak ?? StreakTracker();
  final List<HifzAyahCard> cards;
  final StreakTracker streak;

  List<HifzAyahCard> get dueCards {
    return cards.where((c) => c.isDue).toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }

  List<HifzAyahCard> get newCards {
    return cards.where((c) => c.isNew).toList();
  }

  int get masteredCount {
    return cards.where((c) => c.masteryLevel >= 3).length;
  }
}

/// إدارة بطاقات حفظ الآيات (Hive + FSRS + سلسلة الممارسة).
class HifzNotifier extends StateNotifier<HifzState> {

  HifzNotifier() : super(HifzState()) {
    ready = _load();
  }

  /// يكتمل عند انتهاء تحميل البطاقات من Hive — تُنتظره كل الطفرات حتى لا
  /// تتعارض الكتابة مع القراءة الأولى.
  late final Future<void> ready;

  static const _boxName = 'hifz_box';
  static const _cardsKey = 'hifz_cards';
  static const _streakKey = 'hifz_streak';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _getBox();
    final cardsData = box.get(_cardsKey) as List<dynamic>? ?? const [];
    final cards = cardsData
        .map((e) => HifzAyahCard.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    final streakData = box.get(_streakKey);
    final streak = streakData != null
        ? StreakTracker.fromJson(
            Map<String, dynamic>.from(streakData as Map),
          )
        : StreakTracker();
    state = HifzState(cards: cards, streak: streak);
  }

  Future<void> _save() async {
    final box = await _getBox();
    await box.put(
      _cardsKey,
      state.cards.map((c) => c.toJson()).toList(),
    );
    await box.put(_streakKey, state.streak.toJson());
  }

  HifzAyahCard? cardFor(int surah, int ayah) {
    final id = HifzAyahCard.keyOf(surah, ayah);
    for (final card in state.cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// إضافة آية للحفظ (أو تحديث نصها إن وُجدت).
  Future<void> addAyah({
    required int surah,
    required int ayah,
    required String arabicText,
  }) async {
    await ready;
    final id = HifzAyahCard.keyOf(surah, ayah);
    final existing = cardFor(surah, ayah);
    if (existing != null) {
      existing.arabicText = arabicText;
      state = HifzState(cards: List.of(state.cards), streak: state.streak);
      await _save();
      return;
    }
    state = HifzState(
      cards: [
        ...state.cards,
        HifzAyahCard(id: id, surah: surah, ayah: ayah, arabicText: arabicText),
      ],
      streak: state.streak,
    );
    await _save();
  }

  /// حذف آية من الحفظ.
  Future<void> removeAyah(String id) async {
    await ready;
    state = HifzState(
      cards: state.cards.where((c) => c.id != id).toList(),
      streak: state.streak,
    );
    await _save();
  }

  /// مراجعة آية بتقييم FSRS وتسجيل الممارسة في السلسلة اليومية.
  Future<void> reviewAyah(String id, Rating rating) async {
    await ready;
    final cards = List.of(state.cards);
    var found = false;
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].id == id) {
        cards[i].review(rating);
        found = true;
        break;
      }
    }
    if (!found) return;

    final streak = StreakTracker.fromJson(state.streak.toJson())
      ..recordPractice();

    state = HifzState(cards: cards, streak: streak);
    await _save();
  }

  /// ضبط عدد تكرارات الاستماع لبطاقة.
  Future<void> setRepeatCount(String id, int count) async {
    await ready;
    final cards = List.of(state.cards);
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].id == id) {
        cards[i].repeatCount = count.clamp(1, 20);
        break;
      }
    }
    state = HifzState(cards: cards, streak: state.streak);
    await _save();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final hifzProvider = StateNotifierProvider<HifzNotifier, HifzState>((ref) {
  return HifzNotifier();
});
