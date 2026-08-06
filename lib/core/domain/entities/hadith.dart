import 'package:equatable/equatable.dart';

class HadithCollection extends Equatable {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final int hadithsCount;
  final String author;
  final String description;

  const HadithCollection({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.hadithsCount,
    required this.author,
    this.description = '',
  });

  @override
  List<Object?> get props => [id, titleArabic, titleEnglish, hadithsCount, author];
}

class HadithBook extends Equatable {
  final String id;
  final BookMetadata metadata;
  final List<HadithChapter> chapters;
  final List<Hadith> hadiths;

  const HadithBook({
    required this.id,
    required this.metadata,
    required this.chapters,
    required this.hadiths,
  });

  @override
  List<Object?> get props => [id, metadata, chapters, hadiths];
}

class BookMetadata extends Equatable {
  final String title;
  final String author;
  final String introduction;
  
  const BookMetadata({
    required this.title,
    required this.author,
    this.introduction = '',
  });

  @override
  List<Object?> get props => [title, author, introduction];
}

class HadithChapter extends Equatable {
  final int id;
  final String bookId; // Usually integer in JSON but string logical ID
  final String topicArabic;
  final String topicEnglish;

  const HadithChapter({
    required this.id,
    required this.bookId,
    required this.topicArabic,
    required this.topicEnglish,
  });

  @override
  List<Object?> get props => [id, bookId, topicArabic, topicEnglish];
}

class Hadith extends Equatable {
  final int id;
  final int idInBook;
  final String arabic; // Matn
  final String englishText;
  final String narratorEnglish;
  final int chapterId;
  final int? bookId;
  final String? collectionId; // e.g. 'bukhari', 'muslim'

  const Hadith({
    required this.id,
    required this.idInBook,
    required this.arabic,
    required this.englishText,
    required this.narratorEnglish,
    required this.chapterId,
    this.bookId,
    this.collectionId,
  });

  @override
  List<Object?> get props => [id, idInBook, arabic, englishText, chapterId];
}
