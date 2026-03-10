import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/quran_audio_engine.dart';
import '../../../../core/services/quran_data_source.dart';

/// 🔊 صفحة مشغل الصوت الاحترافية - Professional Audio Player Page
class AudioPlayerPage extends StatefulWidget {
  final int? initialSurah;
  final int? initialAyah;

  const AudioPlayerPage({
    super.key,
    this.initialSurah,
    this.initialAyah,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  // State
  int _currentSurah = 1;
  int _currentAyah = 1;
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _showSpeedControl = false;
  
  // Streams
  StreamSubscription? _ayahSubscription;
  StreamSubscription? _stateSubscription;
  
  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.initialSurah ?? 1;
    _currentAyah = widget.initialAyah ?? 1;
    _loadSurah();
    _setupListeners();
    _checkResume();
  }

  void _setupListeners() {
    _ayahSubscription = QuranAudioEngine.currentAyahStream.listen((ayah) {
      if (mounted) {
        setState(() => _currentAyah = ayah);
        _scrollToAyah(ayah);
      }
    });

    _stateSubscription = QuranAudioEngine.playStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.isPlaying);
      }
    });
  }

  Future<void> _checkResume() async {
    final resumeInfo = await QuranAudioEngine.getLastPosition();
    if (resumeInfo != null && mounted) {
      final shouldResume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.play_circle_outline, size: 48),
          title: const Text('استئناف التلاوة؟'),
          content: Text(
            'هل تريد متابعة التلاوة من سورة ${_getSurahName(resumeInfo.surah)} - الآية ${resumeInfo.ayah}؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استئناف'),
            ),
          ],
        ),
      );

      if (shouldResume == true) {
        _currentSurah = resumeInfo.surah;
        await _loadSurah();
        await QuranAudioEngine.resumeLastPosition();
      }
    }
  }

  Future<void> _loadSurah() async {
    setState(() => _isLoading = true);
    
    try {
      final surahData = await QuranDataSource.getSurah(_currentSurah);
      final ayahs = surahData['ayahs'] as List? ?? [];
      
      // Create verse keys for scrolling
      _verseKeys.clear();
      for (int i = 0; i < ayahs.length; i++) {
        _verseKeys[i + 1] = GlobalKey();
      }
      
      setState(() {
        _verses = ayahs.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل السورة: $e')),
        );
      }
    }
  }

  void _scrollToAyah(int ayah) {
    final key = _verseKeys[ayah];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  @override
  void dispose() {
    _ayahSubscription?.cancel();
    _stateSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${_getSurahName(_currentSurah)}'),
        actions: [
          // Surah selector
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showSurahSelector,
          ),
          // Reciter selector
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showReciterSelector,
          ),
        ],
      ),
      body: Column(
        children: [
          // Reciter info bar
          _ReciterBar(
            reciter: QuranAudioEngine.currentReciterInfo,
            onTap: _showReciterSelector,
          ),
          
          // Verses list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVersesList(theme),
          ),
          
          // Speed control (conditional)
          if (_showSpeedControl) _buildSpeedControl(theme),
          
          // Player controls
          _buildPlayerControls(theme),
        ],
      ),
    );
  }

  Widget _buildVersesList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final verseNumber = verse['numberInSurah'] ?? index + 1;
        final isPlaying = verseNumber == _currentAyah && _isPlaying;
        
        return _VerseCard(
          key: _verseKeys[verseNumber],
          verseNumber: verseNumber,
          text: verse['text'] ?? '',
          isPlaying: isPlaying,
          isCurrentAyah: verseNumber == _currentAyah,
          onTap: () => _playFromAyah(verseNumber),
        );
      },
    );
  }

  Widget _buildSpeedControl(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.speed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: QuranAudioEngine.speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${QuranAudioEngine.speed}x',
              onChanged: (value) {
                QuranAudioEngine.setSpeed(value);
                setState(() {});
              },
            ),
          ),
          Text(
            '${QuranAudioEngine.speed}x',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration>(
              stream: QuranAudioEngine.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: QuranAudioEngine.durationStream,
                  builder: (context, durationSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = durationSnapshot.data ?? const Duration(seconds: 1);
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;
                    
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * duration.inMilliseconds).toInt(),
                              );
                              QuranAudioEngine.seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                _formatDuration(duration),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed
                IconButton(
                  icon: Icon(
                    Icons.speed,
                    color: _showSpeedControl 
                        ? theme.colorScheme.primary 
                        : null,
                  ),
                  onPressed: () {
                    setState(() => _showSpeedControl = !_showSpeedControl);
                  },
                ),
                
                // Previous
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    QuranAudioEngine.previousAyah();
                  },
                ),
                
                // Play/Pause
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (!_isPlaying && QuranAudioEngine.currentAyah == 0) {
                        _playFromAyah(1);
                      } else {
                        QuranAudioEngine.togglePlay();
                      }
                    },
                  ),
                ),
                
                // Next
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    QuranAudioEngine.nextAyah();
                  },
                ),
                
                // Repeat mode
                IconButton(
                  icon: Icon(
                    QuranAudioEngine.repeatMode.icon,
                    color: QuranAudioEngine.repeatMode != RepeatMode.none
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  onPressed: _cycleRepeatMode,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Current ayah indicator
            Text(
              'الآية $_currentAyah من ${_verses.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playFromAyah(int ayah) async {
    HapticFeedback.lightImpact();
    await QuranAudioEngine.playAyah(
      surah: _currentSurah,
      ayah: ayah,
    );
  }

  void _cycleRepeatMode() {
    final modes = RepeatMode.values;
    final currentIndex = modes.indexOf(QuranAudioEngine.repeatMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    QuranAudioEngine.setRepeatMode(modes[nextIndex]);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(QuranAudioEngine.repeatMode.arabicName),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSurahSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر السورة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 114,
                itemBuilder: (context, index) {
                  final surahNumber = index + 1;
                  final isCurrent = surahNumber == _currentSurah;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$surahNumber',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(_getSurahName(surahNumber)),
                    trailing: isCurrent
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => _currentSurah = surahNumber);
                      await _loadSurah();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'اختر القارئ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...QuranAudioEngine.reciters.values.map((reciter) => ListTile(
            leading: Text(reciter.flag, style: const TextStyle(fontSize: 24)),
            title: Text(reciter.arabicName),
            subtitle: Text(reciter.englishName),
            trailing: QuranAudioEngine.currentReciterInfo.id == reciter.id
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              QuranAudioEngine.setReciter(reciter.id);
              Navigator.pop(context);
              setState(() {});
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getSurahName(int surah) {
    const names = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
      'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل',
      'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون', 'النور',
      'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان', 'السجدة',
      'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
      'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
      'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة',
      'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن',
      'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن',
      'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية',
      'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
      'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة',
      'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
      'الفلق', 'الناس',
    ];
    if (surah < 1 || surah > 114) return 'القرآن الكريم';
    return names[surah - 1];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// شريط القارئ
class _ReciterBar extends StatelessWidget {
  final ReciterInfo reciter;
  final VoidCallback onTap;

  const _ReciterBar({
    required this.reciter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Text(reciter.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reciter.arabicName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الآية
class _VerseCard extends StatelessWidget {
  final int verseNumber;
  final String text;
  final bool isPlaying;
  final bool isCurrentAyah;
  final VoidCallback onTap;

  const _VerseCard({
    super.key,
    required this.verseNumber,
    required this.text,
    required this.isPlaying,
    required this.isCurrentAyah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentAyah
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isCurrentAyah
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Verse number badge
            Row(
              children: [
                if (isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'يُتلى الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrentAyah
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$verseNumber',
                      style: TextStyle(
                        color: isCurrentAyah ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Verse text
            Text(
              text,
              style: TextStyle(
                fontSize: 22,
                height: 2.0,
                fontFamily: 'Amiri',
                color: isCurrentAyah
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
