import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            hintStyle: TextStyle(color: NoorDesignSystem.textSecondary.withOpacity(0.5)),
            border: InputBorder.none,
          ),
          style: GoogleFonts.cairo(fontSize: 18),
          onChanged: (val) {
            // Debounce could be added here
            ref.read(searchResultsProvider.notifier).search(val);
          },
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
    final metadata = result.metadata;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          if (isQuran) {
            // Navigate to Surah
            context.push('/quran/surah/${metadata['surah']}'); 
            // Ideally scroll to verse, but that requires more complex navigation state
          }
        },
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
                       color: isQuran ? NoorDesignSystem.emeraldGreen.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(6),
                     ),
                     child: Text(
                       isQuran ? 'القرآن الكريم' : 'الحديث الشريف',
                       style: TextStyle(
                         color: isQuran ? NoorDesignSystem.emeraldGreen : Colors.blue,
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                   const Spacer(),
                   if (isQuran)
                     Text(
                       'سورة ${metadata['surah']} : آية ${metadata['verse']}',
                       style: const TextStyle(color: Colors.grey, fontSize: 12),
                     ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.text,
                maxLines: 2,
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
}
