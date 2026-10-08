/// Immutable Mushaf page model (Phase 1 data rule).
///
/// The canonical Qur'an payload is immutable content; presentation is a
/// reversible view over it. A [MushafToken] never holds manually retyped
/// Qur'an text — it references text produced deterministically from the
/// reviewed canonical asset by `tool/generate_mushaf_tokens.dart`.
library;

import 'package:equatable/equatable.dart';

/// One display token on a Mushaf page.
class MushafToken extends Equatable {
  const MushafToken({
    required this.kind,
    this.surahNumber,
    this.ayahNumber,
    this.canonicalText,
    this.semanticLabel,
  });

  /// Token kinds: surahHeading, basmala, quranText, ayahEnd, sajdah,
  /// metadata, spacing. Only [quranText]/[basmala]/[ayahEnd] carry text.
  final MushafTokenKind kind;
  final int? surahNumber;
  final int? ayahNumber;

  /// Exact approved substring moved here by the generator.
  /// Concatenating content-bearing tokens reconstructs approved display text.
  final String? canonicalText;

  /// Accessibility label; ornaments are never read as ordinary prose.
  final String? semanticLabel;

  /// True when this token carries Qur'an text that must be preserved.
  bool get isContentBearing =>
      kind == MushafTokenKind.quranText ||
      kind == MushafTokenKind.basmala ||
      kind == MushafTokenKind.ayahEnd;

  @override
  List<Object?> get props => [
    kind,
    surahNumber,
    ayahNumber,
    canonicalText,
    semanticLabel,
  ];
}

enum MushafTokenKind {
  surahHeading,
  basmala,
  quranText,
  ayahEnd,
  sajdah,
  metadata,
  spacing,
}

/// One fixed Mushaf page (1..604).
class MushafPage extends Equatable {
  const MushafPage({
    required this.pageNumber,
    required this.headerMetadata,
    required this.tokens,
  });

  final int pageNumber;
  final MushafPageMetadata headerMetadata;
  final List<MushafToken> tokens;

  @override
  List<Object?> get props => [pageNumber, headerMetadata, tokens];
}

/// Header/footer metadata derived from real page data — never invented.
class MushafPageMetadata extends Equatable {
  const MushafPageMetadata({
    required this.firstSurahNumber,
    required this.firstSurahName,
    required this.juz,
    required this.hizb,
  });

  final int firstSurahNumber;
  final String firstSurahName;
  final int juz;
  final int hizb;

  @override
  List<Object?> get props => [firstSurahNumber, firstSurahName, juz, hizb];
}

/// Policy for the basmala display token.
///
/// The renderer consumes an approved token or no token — it never injects
/// hard-coded Qur'an text. Basmala appears exactly once where approved,
/// never at At-Tawbah (9) start, never appended by widget code.
class BasmalaPolicy {
  /// Surah 1 (Al-Fatihah) carries its basmala as ayah 1 in the canonical
  /// source; Surah 9 (At-Tawbah) has none. All others render one basmala
  /// token at surah start when the token map specifies it.
  static bool basmalaAllowedForSurah(int surah) => surah != 1 && surah != 9;
}

/// Typed view over one token row in `mushaf_tokens.json`.
class MushafTokenModel extends Equatable {
  const MushafTokenModel({
    required this.kind,
    this.surahNumber,
    this.ayahNumber,
    this.text,
    this.semanticLabel,
    this.juz = 0,
    this.hizb = 0,
    this.surahName,
    this.headingName,
  });

  factory MushafTokenModel.fromJson(Map<String, dynamic> json) {
    return MushafTokenModel(
      kind: _kindFrom(json['kind'] as String?),
      surahNumber: json['surah'] as int?,
      ayahNumber: json['ayah'] as int?,
      text: json['text'] as String?,
      semanticLabel: json['semanticLabel'] as String?,
      juz: (json['juz'] as int?) ?? 0,
      hizb: (json['hizb'] as int?) ?? 0,
      surahName: json['surahName'] as String?,
      headingName: json['name'] as String?,
    );
  }

  final MushafTokenKind kind;
  final int? surahNumber;
  final int? ayahNumber;

  /// Display text for content-bearing tokens; null for metadata tokens.
  final String? text;
  final String? semanticLabel;
  final int juz;
  final int hizb;
  final String? surahName;
  final String? headingName;

  bool get isContentBearing =>
      kind == MushafTokenKind.quranText ||
      kind == MushafTokenKind.basmala ||
      kind == MushafTokenKind.ayahEnd;

  @override
  List<Object?> get props => [
        kind,
        surahNumber,
        ayahNumber,
        text,
        semanticLabel,
        juz,
        hizb,
        surahName,
        headingName,
      ];
}

MushafTokenKind _kindFrom(String? raw) {
  switch (raw) {
    case 'surahHeading':
      return MushafTokenKind.surahHeading;
    case 'basmala':
      return MushafTokenKind.basmala;
    case 'quranText':
      return MushafTokenKind.quranText;
    case 'ayahEnd':
      return MushafTokenKind.ayahEnd;
    case 'sajdah':
      return MushafTokenKind.sajdah;
    case 'metadata':
      return MushafTokenKind.metadata;
    case 'spacing':
      return MushafTokenKind.spacing;
    default:
      throw StateError('mushaf_tokens: unknown token kind "$raw"');
  }
}

/// One resolved verse row derived from tokens (no widget dependency).
typedef MushafVerseRow = ({
  int surah,
  int ayah,
  String text,
  int juz,
  int hizb,
  String? surahName,
});

/// Typed view over one page in `mushaf_tokens.json`.
class MushafPageModel extends Equatable {
  const MushafPageModel({
    required this.pageNumber,
    required this.header,
    required this.tokens,
  });

  factory MushafPageModel.fromJson(String pageKey, Map<String, dynamic> json) {
    final tokens = (json['tokens'] as List? ?? [])
        .map((t) => MushafTokenModel.fromJson(
            Map<String, dynamic>.from(t as Map)))
        .toList();
    return MushafPageModel(
      pageNumber: int.parse(pageKey),
      header: MushafPageMetadata(
        firstSurahNumber:
            (json['header'] as Map?)?['firstSurah'] as int? ?? 0,
        firstSurahName:
            (json['header'] as Map?)?['firstSurahName'] as String? ?? '',
        juz: (json['header'] as Map?)?['juz'] as int? ?? 0,
        hizb: (json['header'] as Map?)?['hizb'] as int? ?? 0,
      ),
      tokens: tokens,
    );
  }

  final int pageNumber;
  final MushafPageMetadata header;
  final List<MushafTokenModel> tokens;

  /// Resolves content tokens into verse rows. A `basmala` token joins its
  /// following `quranText` exactly once; `ayahEnd` closes the ayah.
  List<MushafVerseRow> verses() {
    final out = <MushafVerseRow>[];
    var pendingBasmala = '';
    final pendingText = StringBuffer();
    for (final token in tokens) {
      switch (token.kind) {
        case MushafTokenKind.basmala:
          pendingBasmala = token.text ?? '';
        case MushafTokenKind.quranText:
          pendingText.write(token.text ?? '');
        case MushafTokenKind.ayahEnd:
          final text = '$pendingBasmala${pendingText.toString()}';
          if (text.isNotEmpty) {
            out.add((
              surah: token.surahNumber ?? 0,
              ayah: token.ayahNumber ?? 0,
              text: text,
              juz: token.juz,
              hizb: token.hizb,
              surahName: token.surahName,
            ));
          }
          pendingBasmala = '';
          pendingText.clear();
        case MushafTokenKind.surahHeading:
        case MushafTokenKind.sajdah:
        case MushafTokenKind.metadata:
        case MushafTokenKind.spacing:
          break;
      }
    }
    return out;
  }

  @override
  List<Object?> get props => [pageNumber, header, tokens];
}
