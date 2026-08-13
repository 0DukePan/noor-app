import 'package:equatable/equatable.dart';

enum RevelationType { meccan, medinan }

class Surah extends Equatable {

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.englishNameTranslation,
    required this.versesCount, required this.revelationType, required this.verses, this.nameTransliteration = '',
    this.page = 0,
  });
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String englishNameTranslation;
  final String nameTransliteration;
  final int versesCount;
  final RevelationType revelationType;
  final int page;
  final List<Verse> verses;

  @override
  List<Object?> get props => [
        number,
        nameArabic,
        nameEnglish,
        englishNameTranslation,
        nameTransliteration,
        versesCount,
        revelationType,
        page,
        verses,
      ];
}

class Verse extends Equatable {

  const Verse({
    required this.number,
    required this.numberInSurah,
    required this.textUthmani,
    this.textSimple,
    this.juz = 0,
    this.page = 0,
    this.hizb = 0,
    this.quarter = 0,
    this.sajdah = false,
    this.surahNumber = 0,
    this.surahName,
  });
  final int number; // Global number if available, otherwise 0
  final int numberInSurah;
  final String textUthmani;
  final String? textSimple;
  final int juz;
  final int page;
  final int hizb;
  final int quarter;
  final bool sajdah;
  final int surahNumber;
  final String? surahName;

  @override
  List<Object?> get props => [
        number, 
        numberInSurah, 
        textUthmani, 
        textSimple, 
        juz, 
        page, 
        hizb, 
        quarter, 
        sajdah,
        surahNumber,
        surahName,
      ];
}
