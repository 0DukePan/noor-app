import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/data/data_sources/hadith_database.dart';
import '../../../hadith/presentation/hadith_book_names.dart';
import '../../../hadith/presentation/pages/hadith_reader_page.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    // Debounce so the (Quran+hadith+adhkar) FTS query only runs after the
    // user pauses typing.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchResultsProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث في القرآن والحديث...',
            hintStyle: TextStyle(color: NoorDesignSystem.textSecondary.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
          style: GoogleFonts.cairo(fontSize: 18),
          onChanged: _onQueryChanged,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: NoorDesignSystem.deepTeal),
      ),
      body: searchState.when(
        data: (results) {
          if (results.isEmpty && _controller.text.isNotEmpty) {
             return const Center(child: Text('لا توجد نتائج'));
          }
          if (results.isEmpty) {
             return const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.search, size: 64, color: Colors.black12),
                   SizedBox(height: 16),
                   Text('ابحث عن آية أو حديث'),
                 ],
               ),
             );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = results[index];
              return _SearchResultCard(result: result);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final dynamic result; // SearchResult

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isQuran = result.source == 'quran';
    final isHadith = result.source == 'hadith';
    final metadata = result.metadata;

    final badgeColor = isQuran
        ? NoorDesignSystem.emeraldGreen
        : isHadith
            ? NoorDesignSystem.goldAccent
            : NoorDesignSystem.deepTeal;
    final badgeLabel = isQuran
        ? 'القرآن الكريم'
        : isHadith
            ? 'الحديث الشريف'
            : 'الأذكار';

    String? reference;
    if (isQuran) {
      reference = 'سورة ${metadata['surah']} : آية ${metadata['verse']}';
    } else if (isHadith) {
      reference = hadithBookName(metadata['book']?.toString() ?? '');
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => _openResult(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (reference != null)
                    Text(
                      reference,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openResult(BuildContext context) async {
    final metadata = result.metadata as Map<String, dynamic>;

    if (result.source == 'quran') {
      context.push('/quran/surah/${metadata['surah']}');
      return;
    }

    if (result.source == 'hadith') {
      final book = metadata['book']?.toString();
      final id = (metadata['id'] as num?)?.toInt();
      if (book == null || id == null) return;
      try {
        final row = await HadithDatabase.getHadithById(book, id);
        if (row == null || !context.mounted) return;
        final hadith = Hadith(
          id: row['id'] as int,
          idInBook: row['id_in_book'] as int? ?? row['id'] as int,
          arabic: row['arabic'] as String,
          englishText: row['english_text'] as String? ?? '',
          narratorEnglish: row['english_narrator'] as String? ?? '',
          chapterId: row['chapter_id'] as int? ?? 0,
          bookId: null,
          collectionId: book,
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HadithReaderPage(
            hadith: hadith,
            bookTitle: hadithBookName(book),
            chapterTitle: '',
            bookColor: NoorDesignSystem.emeraldGreen,
            allHadiths: [hadith],
            currentIndex: 0,
          ),
        ),);
      } catch (e) {
        debugPrint('Failed to open hadith result: $e');
      }
      return;
    }

    // Adhkar: copy the text.
    await Clipboard.setData(ClipboardData(text: result.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ النص')),
      );
    }
  }
}
