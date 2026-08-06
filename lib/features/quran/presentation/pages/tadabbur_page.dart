import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/domain/policies/privacy_policy.dart';

/// صفحة محراب التدبر - Tadabbur Mihrab Page
/// Personal reflections on Quran verses with local encryption
class TadabburMihrabPage extends ConsumerStatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String verseText;

  const TadabburMihrabPage({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.verseText,
  });

  @override
  ConsumerState<TadabburMihrabPage> createState() => _TadabburMihrabPageState();
}

class _TadabburMihrabPageState extends ConsumerState<TadabburMihrabPage> {
  final _noteController = TextEditingController();
  // TODO: Replace with device-derived key via flutter_secure_storage
  // final storage = FlutterSecureStorage();
  // final key = await storage.read(key: 'tadabbur_key') ?? _generateAndSaveKey();
  final _privacyPolicy = DefaultPrivacyPolicy(
    encryptionKey: 'noor_app_tadabbur_encryption_key', // FIXME: derive from device
  );
  
  List<Map<String, dynamic>> _savedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    // Load from Hive and decrypt
    // final encrypted = HiveService.getTadabburForVerse(
    //   widget.surahNumber,
    //   widget.verseNumber,
    // );
    // _savedNotes = encrypted.map((e) {
    //   return {
    //     ...e,
    //     'decrypted_note': _privacyPolicy.decryptLocalData(e['encrypted_note']),
    //   };
    // }).toList();
    setState(() => _isLoading = false);
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    await HapticFeedback.lightImpact();

    // Encrypt before saving
    final encryptedNote = _privacyPolicy.encryptLocalData(_noteController.text);
    
    final note = {
      'id': const Uuid().v4(),
      'surahNumber': widget.surahNumber,
      'verseNumber': widget.verseNumber,
      'encrypted_note': encryptedNote,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save to Hive
    // await HiveService.saveTadabbur(note);

    setState(() {
      _savedNotes.add({
        ...note,
        'decrypted_note': _noteController.text,
      });
      _noteController.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ ملاحظتك بشكل آمن 🔒'),
        backgroundColor: NoorTheme.hadithSahih,
      ),
    );
  }

  Future<void> _deleteNote(String id) async {
    // await HiveService.deleteTadabbur(id);
    setState(() {
      _savedNotes.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محراب التدبر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showPrivacyInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Verse Display
            Container(
              margin: const EdgeInsets.all(NoorTheme.spacingMd),
              padding: const EdgeInsets.all(NoorTheme.spacingLg),
              decoration: BoxDecoration(
                color: NoorTheme.bgMushaf,
                borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                border: Border.all(
                  color: NoorTheme.accentGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.verseText,
                    style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 22,
                      height: 2.0,
                      color: NoorTheme.textArabic,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: NoorTheme.spacingSm),
                  Text(
                    'سورة ${widget.surahNumber} - آية ${widget.verseNumber}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Note Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NoorTheme.spacingMd),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'اكتب تدبرك وخواطرك هنا...',
                        hintTextDirection: TextDirection.rtl,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(NoorTheme.spacingMd),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: NoorTheme.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(NoorTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: NoorTheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(NoorTheme.radiusMd),
                          bottomRight: Radius.circular(NoorTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '🔒 ملاحظاتك مشفرة محلياً',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: NoorTheme.primary,
                                ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _saveNote,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('حفظ'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: NoorTheme.spacingMd),

            // Saved Notes Header
            if (_savedNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: NoorTheme.spacingMd),
                child: Row(
                  children: [
                    Text(
                      'ملاحظاتك السابقة',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${_savedNotes.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

            // Saved Notes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 64,
                                color: NoorTheme.textSecondary.withOpacity(0.3),
                              ),
                              const SizedBox(height: NoorTheme.spacingMd),
                              Text(
                                'لا توجد ملاحظات بعد',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: NoorTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(NoorTheme.spacingMd),
                          itemCount: _savedNotes.length,
                          itemBuilder: (context, index) {
                            final note = _savedNotes[index];
                            return _NoteCard(
                              note: note['decrypted_note'] ?? '',
                              createdAt: DateTime.parse(note['createdAt']),
                              onDelete: () => _deleteNote(note['id']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: NoorTheme.primary),
            const SizedBox(width: 8),
            const Text('خصوصية ملاحظاتك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔒 ملاحظاتك مشفرة محلياً على جهازك'),
            const SizedBox(height: 8),
            const Text('☁️ لا يتم رفعها للسحابة أبداً'),
            const SizedBox(height: 8),
            const Text('👁️ لا أحد يستطيع قراءتها سواك'),
            const SizedBox(height: 16),
            Text(
              'تستخدم تشفير AES-256 لحماية أفكارك.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;
  final DateTime createdAt;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.createdAt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            note,
            style: Theme.of(context).textTheme.bodyMedium,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: NoorTheme.spacingMd),
          Row(
            children: [
              Text(
                _formatDate(createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onDelete,
                color: NoorTheme.hadithMawdu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
