import 'package:equatable/equatable.dart';

class TafsirVerse extends Equatable {
  final int surahId;
  final int verseId;
  final String text; // The actual Tafsir
  final String source; // e.g., 'muyassar', 'ibn_kathir'

  const TafsirVerse({
    required this.surahId,
    required this.verseId,
    required this.text,
    required this.source,
  });

  @override
  List<Object?> get props => [surahId, verseId, text, source];
}

/// Tafsir Book Metadata
enum TafsirBook {
  muyassar(
    id: 'muyassar',
    nameArabic: 'التفسير الميسر',
    nameEnglish: 'Al-Muyassar',
    folderName: 'ar-tafsir-muyassar',
  ),
  ibnKathir(
    id: 'ibn_kathir',
    nameArabic: 'تفسير ابن كثير',
    nameEnglish: 'Ibn Kathir',
    folderName: 'full/ar-tafsir-ibn-kathir',
  ),
  saadi(
    id: 'saadi',
    nameArabic: 'تفسير السعدي',
    nameEnglish: 'Al-Saadi',
    folderName: 'ar-tafseer-al-saddi',
  ),
  tabari(
    id: 'tabari',
    nameArabic: 'تفسير الطبري',
    nameEnglish: 'Al-Tabari',
    folderName: 'ar-tafsir-al-tabari',
  );

  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String folderName;

  const TafsirBook({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.folderName,
  });
}
