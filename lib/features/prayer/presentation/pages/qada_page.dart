import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../domain/entities/prayer_entities.dart';
import '../providers/prayer_providers.dart';

/// صفحة متتبع القضاء - Qada Tracker Page (Riverpod)
/// For tracking missed prayers and fasting — persisted with Hive
class QadaTrackerPage extends ConsumerStatefulWidget {
  const QadaTrackerPage({super.key});

  @override
  ConsumerState<QadaTrackerPage> createState() => _QadaTrackerPageState();
}

class _QadaTrackerPageState extends ConsumerState<QadaTrackerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qada = ref.watch(qadaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('متتبع القضاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(),
          tabs: const [
            Tab(text: 'الصلاة', icon: Icon(Icons.mosque_rounded)),
            Tab(text: 'الصيام', icon: Icon(Icons.nights_stay_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QadaList(
            records: qada.prayerRecords,
            type: QadaType.prayer,
            onIncrement: (id) => _incrementRecord(id),
            onDelete: (id) => ref.read(qadaProvider.notifier).deleteRecord(id),
            onAdd: () => _showAddDialog(QadaType.prayer),
          ),
          _QadaList(
            records: qada.fastingRecords,
            type: QadaType.fasting,
            onIncrement: (id) => _incrementRecord(id),
            onDelete: (id) => ref.read(qadaProvider.notifier).deleteRecord(id),
            onAdd: () => _showAddDialog(QadaType.fasting),
          ),
        ],
      ),
    );
  }

  void _incrementRecord(String id) async {
    await HapticFeedback.lightImpact();
    final isComplete = ref.read(qadaProvider.notifier).incrementRecord(id);
    if (isComplete) {
      HapticFeedback.heavyImpact();
      _showCompletionDialog();
    }
  }

  void _showAddDialog(QadaType type) {
    showDialog(
      context: context,
      builder: (context) => _AddQadaDialog(
        type: type,
        onAdd: (name, count, notes) {
          ref.read(qadaProvider.notifier).addRecord(type, name, count, notes);
        },
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 تهانينا!'),
        content: Text('لقد أتممت قضاء هذا السجل', style: GoogleFonts.cairo()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('الحمد لله', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QadaList extends StatelessWidget {
  final List<QadaRecord> records;
  final QadaType type;
  final Function(String) onIncrement;
  final Function(String) onDelete;
  final VoidCallback onAdd;

  const _QadaList({
    required this.records,
    required this.type,
    required this.onIncrement,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == QadaType.prayer
                  ? Icons.mosque_rounded
                  : Icons.nights_stay_rounded,
              size: 64,
              color: NoorTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: NoorTheme.spacingMd),
            Text(
              type == QadaType.prayer
                  ? 'لا توجد صلوات فائتة للقضاء'
                  : 'لا توجد أيام صيام للقضاء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoorTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: NoorTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      itemCount: records.length + 1,
      itemBuilder: (context, index) {
        if (index == records.length) {
          return Padding(
            padding: const EdgeInsets.only(top: NoorTheme.spacingMd),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة سجل جديد'),
            ),
          );
        }

        final record = records[index];
        return _QadaCard(
          record: record,
          type: type,
          onIncrement: () => onIncrement(record.id),
          onDelete: () => onDelete(record.id),
        );
      },
    );
  }
}

class _QadaCard extends StatelessWidget {
  final QadaRecord record;
  final QadaType type;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;

  const _QadaCard({
    required this.record,
    required this.type,
    required this.onIncrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = record.remainingCount;
    final progress = record.progressPercentage;
    final isComplete = remaining <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? Colors.green.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? Colors.green.withOpacity(0.1)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        type == QadaType.prayer
                            ? Icons.mosque_rounded
                            : Icons.nights_stay_rounded,
                        color: isComplete ? Colors.green : theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isComplete ? Colors.green : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: (isComplete ? Colors.green : theme.colorScheme.primary)
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تم: ${record.completedCount} من ${record.totalCount}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      isComplete
                          ? '✓ مكتمل'
                          : 'متبقي: $remaining ${type == QadaType.prayer ? 'صلاة' : 'يوم'}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isComplete)
            InkWell(
              onTap: onIncrement,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      type == QadaType.prayer ? 'قضيت صلاة واحدة' : 'صمت يوماً واحداً',
                      style: GoogleFonts.cairo(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddQadaDialog extends StatefulWidget {
  final QadaType type;
  final Function(String name, int count, String? notes) onAdd;

  const _AddQadaDialog({
    required this.type,
    required this.onAdd,
  });

  @override
  State<_AddQadaDialog> createState() => _AddQadaDialogState();
}

class _AddQadaDialogState extends State<_AddQadaDialog> {
  final _nameController = TextEditingController();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.type == QadaType.prayer
            ? 'إضافة صلوات للقضاء'
            : 'إضافة أيام صيام للقضاء',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الاسم (اختياري)',
                hintText: 'مثال: صلوات سنة 2020',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'العدد *',
                hintText: widget.type == QadaType.prayer
                    ? 'عدد الصلوات'
                    : 'عدد الأيام',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'أي ملاحظات إضافية',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            final count = int.tryParse(_countController.text);
            if (count == null || count <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('الرجاء إدخال عدد صحيح', style: GoogleFonts.cairo()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            final name = _nameController.text.isNotEmpty
                ? _nameController.text
                : widget.type == QadaType.prayer
                    ? 'صلوات قضاء'
                    : 'أيام صيام';

            widget.onAdd(
              name,
              count,
              _notesController.text.isNotEmpty ? _notesController.text : null,
            );
            Navigator.pop(context);
          },
          child: Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
