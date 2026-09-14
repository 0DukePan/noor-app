import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/adhkar_models.dart';
import '../../../../core/services/adhkar_data_source.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// مكتبة الأذكار الموسعة — تصفح أكثر من ١٠٠ ذكر بمصادرها حسب الفئة.
///
/// محتوى المكتبة (library.json) قيد المراجعة العلمية — تظهر شارة
/// «قيد المراجعة» حتى اعتماد المحتوى.
class AdhkarLibraryPage extends StatefulWidget {
  const AdhkarLibraryPage({super.key});

  @override
  State<AdhkarLibraryPage> createState() => _AdhkarLibraryPageState();
}

class _AdhkarLibraryPageState extends State<AdhkarLibraryPage> {
  AdhkarLibrary? _library;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = await AdhkarDataSource.getLibrary();
    if (!mounted) return;
    setState(() => _library = library);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? NoorDesignSystem.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          l10n.alibTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: _library == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: NoorDesignSystem.goldAccent,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.alibReviewBanner,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: NoorDesignSystem.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.6,
                  children: _library!.categories.map((category) {
                    final count = _library!.countFor(category.id);
                    return Material(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _CategoryItemsPage(
                              category: category,
                              items: _library!.byCategory(category.id),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Text(category.icon,
                                  style: const TextStyle(fontSize: 22),),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.title,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : NoorDesignSystem.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      AppLocalizations.of(context).alibCount(count),
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: NoorDesignSystem.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

/// قائمة أذكار فئة واحدة مع المصادر
class _CategoryItemsPage extends StatefulWidget {
  const _CategoryItemsPage({required this.category, required this.items});

  final AdhkarCategory category;
  final List<Zekr> items;

  @override
  State<_CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<_CategoryItemsPage> {
  final Map<int, int> _counts = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? NoorDesignSystem.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          '${widget.category.icon} ${widget.category.title}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final zekr = widget.items[index];
          final count = _counts[index] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            zekr.text,
                            style: GoogleFonts.amiri(
                              fontSize: 17,
                              height: 1.8,
                              color: isDark
                                  ? Colors.white
                                  : NoorDesignSystem.textPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (count + 1 >= zekr.repeat) {
                                _counts[index] = 0;
                              } else {
                                _counts[index] = count + 1;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: NoorDesignSystem.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              zekr.repeat > 1 ? '$count / ${zekr.repeat}' : '$count',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: NoorDesignSystem.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (zekr.bless != null || zekr.reference != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        [
                          if (zekr.bless != null) zekr.bless!,
                          if (zekr.reference != null)
                            AppLocalizations.of(context).alibSource(zekr.reference!),
                        ].join(' — '),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: NoorDesignSystem.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
