import 'package:flutter/material.dart';
import '../../../../core/models/tafsir_models.dart';
import '../../../../core/services/tafsir_data_source.dart';

/// 📖 TafsirInlineView - عرض التفسير المختصر تحت الآية
class TafsirInlineView extends StatefulWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final bool initiallyExpanded;
  final VoidCallback? onExpand;
  final VoidCallback? onFullScreen;

  const TafsirInlineView({
    super.key,
    required this.surah,
    required this.ayah,
    this.source = TafsirSourceId.muyassar,
    this.initiallyExpanded = false,
    this.onExpand,
    this.onFullScreen,
  });

  @override
  State<TafsirInlineView> createState() => _TafsirInlineViewState();
}

class _TafsirInlineViewState extends State<TafsirInlineView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  bool _isExpanded = false;
  bool _isLoading = true;
  TafsirEntry? _tafsir;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
    
    _loadTafsir();
  }

  @override
  void didUpdateWidget(TafsirInlineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah ||
        oldWidget.ayah != widget.ayah ||
        oldWidget.source != widget.source) {
      _loadTafsir();
    }
  }

  Future<void> _loadTafsir() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tafsir = await TafsirDataSource.getAyahTafsir(
        surah: widget.surah,
        ayah: widget.ayah,
        source: widget.source,
      );
      
      if (mounted) {
        setState(() {
          _tafsir = tafsir;
          _isLoading = false;
        });
        
        // Record reading
        if (tafsir != null) {
          TafsirDataSource.recordReading(
            surah: widget.surah,
            ayah: widget.ayah,
            source: widget.source,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل في تحميل التفسير';
          _isLoading = false;
        });
      }
    }
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _controller.forward();
      widget.onExpand?.call();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = TafsirDataSource.getSettings();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TafsirSource.get(widget.source).arabicName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else ...[
                    // Bookmark button
                    IconButton(
                      icon: Icon(
                        TafsirDataSource.isBookmarked(
                          surah: widget.surah,
                          ayah: widget.ayah,
                          source: widget.source,
                        ) ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (TafsirDataSource.isBookmarked(
                          surah: widget.surah,
                          ayah: widget.ayah,
                          source: widget.source,
                        )) {
                          await TafsirDataSource.removeBookmark(
                            surah: widget.surah,
                            ayah: widget.ayah,
                            source: widget.source,
                          );
                        } else {
                          await TafsirDataSource.addBookmark(
                            surah: widget.surah,
                            ayah: widget.ayah,
                            source: widget.source,
                          );
                        }
                        setState(() {});
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Expand icon
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Expandable content
          SizeTransition(
            sizeFactor: _animation,
            child: _buildContent(theme, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, TafsirDisplaySettings settings) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: TextStyle(color: theme.colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_tafsir == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'لا يوجد تفسير لهذه الآية',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          // Tafsir text
          SelectableText(
            _tafsir!.text,
            style: TextStyle(
              fontSize: settings.fontSize,
              height: 1.8,
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: 12),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Full screen button
              TextButton.icon(
                onPressed: () {
                  widget.onFullScreen?.call();
                  _showFullScreen(context);
                },
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('عرض كامل'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              
              // Compare button
              TextButton.icon(
                onPressed: () => _showCompare(context),
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('مقارنة'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TafsirFullScreenPage(
          surah: widget.surah,
          ayah: widget.ayah,
          source: widget.source,
        ),
      ),
    );
  }

  void _showCompare(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TafsirCompareSheet(
        surah: widget.surah,
        ayah: widget.ayah,
      ),
    );
  }
}

/// 📖 TafsirFullScreenPage - صفحة التفسير الكاملة
class TafsirFullScreenPage extends StatefulWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;

  const TafsirFullScreenPage({
    super.key,
    required this.surah,
    required this.ayah,
    required this.source,
  });

  @override
  State<TafsirFullScreenPage> createState() => _TafsirFullScreenPageState();
}

class _TafsirFullScreenPageState extends State<TafsirFullScreenPage> {
  late TafsirSourceId _currentSource;
  SurahTafsir? _surahTafsir;
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.source;
    _pageController = PageController(initialPage: widget.ayah - 1);
    _loadSurahTafsir();
  }

  Future<void> _loadSurahTafsir() async {
    setState(() => _isLoading = true);
    
    final tafsir = await TafsirDataSource.getSurahTafsir(
      surah: widget.surah,
      source: _currentSource,
    );
    
    if (mounted) {
      setState(() {
        _surahTafsir = tafsir;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = TafsirDataSource.getSettings();

    return Scaffold(
      appBar: AppBar(
        title: Text(TafsirSource.get(_currentSource).arabicName),
        actions: [
          // Source selector
          PopupMenuButton<TafsirSourceId>(
            icon: const Icon(Icons.menu_book),
            onSelected: (source) {
              setState(() => _currentSource = source);
              _loadSurahTafsir();
            },
            itemBuilder: (_) => TafsirSource.all.map((s) => PopupMenuItem(
              value: s.id,
              child: Row(
                children: [
                  if (s.id == _currentSource)
                    Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                  if (s.id != _currentSource)
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(s.arabicName),
                ],
              ),
            )).toList(),
          ),
          
          // Font size
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _showFontSizeDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surahTafsir == null
              ? const Center(child: Text('لا يوجد تفسير'))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _surahTafsir!.length,
                  itemBuilder: (context, index) {
                    final entry = _surahTafsir!.entries[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Verse indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'الآية ${entry.ayah}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Tafsir text
                          SelectableText(
                            entry.text,
                            style: TextStyle(
                              fontSize: settings.fontSize + 2,
                              height: 2.0,
                              fontFamily: 'Amiri',
                            ),
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _surahTafsir != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_pageController.page! > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                  Text(
                    'سورة ${widget.surah}',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: () {
                      if (_pageController.page! < _surahTafsir!.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    var settings = TafsirDataSource.getSettings();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('حجم الخط'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: settings.fontSize,
                min: 14,
                max: 32,
                divisions: 9,
                label: settings.fontSize.round().toString(),
                onChanged: (value) {
                  setDialogState(() {
                    settings = settings.copyWith(fontSize: value);
                  });
                },
              ),
              Text(
                'معاينة النص',
                style: TextStyle(fontSize: settings.fontSize),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                TafsirDataSource.saveSettings(settings);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// 📖 TafsirCompareSheet - مقارنة التفاسير
class TafsirCompareSheet extends StatefulWidget {
  final int surah;
  final int ayah;

  const TafsirCompareSheet({
    super.key,
    required this.surah,
    required this.ayah,
  });

  @override
  State<TafsirCompareSheet> createState() => _TafsirCompareSheetState();
}

class _TafsirCompareSheetState extends State<TafsirCompareSheet> {
  final List<TafsirSourceId> _selectedSources = [
    TafsirSourceId.muyassar,
    TafsirSourceId.saadi,
  ];
  
  Map<TafsirSourceId, TafsirEntry> _tafsirs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTafsirs();
  }

  Future<void> _loadTafsirs() async {
    setState(() => _isLoading = true);
    
    final tafsirs = await TafsirDataSource.getCompareTafsir(
      surah: widget.surah,
      ayah: widget.ayah,
      sources: _selectedSources,
    );
    
    if (mounted) {
      setState(() {
        _tafsirs = tafsirs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = TafsirDataSource.getSettings();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'مقارنة التفاسير',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  'الآية ${widget.ayah}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Source chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: TafsirSource.all.map((source) {
                final isSelected = _selectedSources.contains(source.id);
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(source.arabicName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected && _selectedSources.length < 3) {
                          _selectedSources.add(source.id);
                        } else {
                          _selectedSources.remove(source.id);
                        }
                      });
                      _loadTafsirs();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Divider(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedSources.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final sourceId = _selectedSources[index];
                      final source = TafsirSource.get(sourceId);
                      final entry = _tafsirs[sourceId];
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Source name
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    source.arabicName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Tafsir text
                              entry != null
                                  ? SelectableText(
                                      entry.text,
                                      style: TextStyle(
                                        fontSize: settings.fontSize,
                                        height: 1.8,
                                        fontFamily: 'Amiri',
                                      ),
                                      textDirection: TextDirection.rtl,
                                    )
                                  : Text(
                                      'لا يوجد تفسير',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 📖 TafsirBottomSheet - عرض التفسير السفلي
class TafsirBottomSheet extends StatelessWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;

  const TafsirBottomSheet({
    super.key,
    required this.surah,
    required this.ayah,
    this.source = TafsirSourceId.muyassar,
  });

  static void show(
    BuildContext context, {
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TafsirBottomSheet(
        surah: surah,
        ayah: ayah,
        source: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => TafsirSheetContent(
        surah: surah,
        ayah: ayah,
        source: source,
        scrollController: scrollController,
      ),
    );
  }
}

class TafsirSheetContent extends StatefulWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final ScrollController scrollController;

  const TafsirSheetContent({
    super.key,
    required this.surah,
    required this.ayah,
    required this.source,
    required this.scrollController,
  });

  @override
  State<TafsirSheetContent> createState() => _TafsirSheetContentState();
}

class _TafsirSheetContentState extends State<TafsirSheetContent> {
  late TafsirSourceId _currentSource;
  TafsirEntry? _tafsir;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.source;
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() => _isLoading = true);
    
    final tafsir = await TafsirDataSource.getAyahTafsir(
      surah: widget.surah,
      ayah: widget.ayah,
      source: _currentSource,
    );
    
    if (mounted) {
      setState(() {
        _tafsir = tafsir;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = TafsirDataSource.getSettings();

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TafsirSource.get(_currentSource).arabicName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'سورة ${widget.surah} - الآية ${widget.ayah}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Source selector
              PopupMenuButton<TafsirSourceId>(
                icon: const Icon(Icons.swap_horiz),
                onSelected: (source) {
                  setState(() => _currentSource = source);
                  _loadTafsir();
                },
                itemBuilder: (_) => TafsirSource.all.map((s) => PopupMenuItem(
                  value: s.id,
                  child: Text(s.arabicName),
                )).toList(),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tafsir == null
                  ? const Center(child: Text('لا يوجد تفسير'))
                  : SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(
                        _tafsir!.text,
                        style: TextStyle(
                          fontSize: settings.fontSize,
                          height: 2.0,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
        ),
      ],
    );
  }
}
