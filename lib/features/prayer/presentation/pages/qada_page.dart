import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final qada = ref.watch(qadaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qadaTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(),
          tabs: [
            Tab(text: l10n.qadaTabPrayer, icon: const Icon(Icons.mosque_rounded)),
            Tab(text: l10n.qadaTabFast, icon: const Icon(Icons.nights_stay_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QadaList(
            records: qada.prayerRecords,
            type: QadaType.prayer,
            onIncrement: _incrementRecord,
            onDelete: (id) => ref.read(qadaProvider.notifier).deleteRecord(id),
            onAdd: () => _showAddDialog(QadaType.prayer),
          ),
          _QadaList(
            records: qada.fastingRecords,
            type: QadaType.fasting,
            onIncrement: _incrementRecord,
            onDelete: (id) => ref.read(qadaProvider.notifier).deleteRecord(id),
            onAdd: () => _showAddDialog(QadaType.fasting),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementRecord(String id) async {
    await HapticFeedback.lightImpact();
    final isComplete = ref.read(qadaProvider.notifier).incrementRecord(id);
    if (isComplete) {
      unawaited(HapticFeedback.heavyImpact());
      _showCompletionDialog();
    }
  }

  void _showAddDialog(QadaType type) {
    showDialog<void>(
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
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.qadaCongrats),
        content: Text(l10n.qadaCongratsBody, style: GoogleFonts.cairo()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.qadaPraiseGod, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QadaList extends StatelessWidget {

  const _QadaList({
    required this.records,
    required this.type,
    required this.onIncrement,
    required this.onDelete,
    required this.onAdd,
  });
  final List<QadaRecord> records;
  final QadaType type;
  final void Function(String) onIncrement;
  final void Function(String) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              color: NoorTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: NoorTheme.spacingMd),
            Text(
              type == QadaType.prayer
                  ? l10n.qadaEmptyPrayer
                  : l10n.qadaEmptyFast,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoorTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: NoorTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.qadaAdd),
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
              label: Text(l10n.qadaAddNew),
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

  const _QadaCard({
    required this.record,
    required this.type,
    required this.onIncrement,
    required this.onDelete,
  });
  final QadaRecord record;
  final QadaType type;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final remaining = record.remainingCount;
    final progress = record.progressPercentage;
    final isComplete = remaining <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                            ? Colors.green.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
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
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
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
                                  .withValues(alpha: 0.4),
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
                      l10n.qadaProgress(record.completedCount, record.totalCount),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      isComplete
                          ? l10n.qadaComplete
                          : type == QadaType.prayer
                              ? l10n.qadaRemainingPrayer(remaining)
                              : l10n.qadaRemainingFast(remaining),
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
            Material(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onIncrement,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        type == QadaType.prayer ? l10n.qadaDidPrayer : l10n.qadaDidFast,
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
            ),
        ],
      ),
    );
  }
}

class _AddQadaDialog extends StatefulWidget {

  const _AddQadaDialog({
    required this.type,
    required this.onAdd,
  });
  final QadaType type;
  final void Function(String name, int count, String? notes) onAdd;

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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.type == QadaType.prayer
            ? l10n.qadaAddPrayerTitle
            : l10n.qadaAddFastTitle,
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
                labelText: l10n.qadaNameLabel,
                hintText: l10n.qadaNameHint,
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
                labelText: l10n.qadaCountLabel,
                hintText: widget.type == QadaType.prayer
                    ? l10n.qadaCountPrayerHint
                    : l10n.qadaCountFastHint,
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
                labelText: l10n.qadaNotesLabel,
                hintText: l10n.qadaNotesHint,
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
          child: Text(l10n.settingsCancel, style: GoogleFonts.cairo(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            final count = int.tryParse(_countController.text);
            if (count == null || count <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.qadaInvalidCount, style: GoogleFonts.cairo()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            final name = _nameController.text.isNotEmpty
                ? _nameController.text
                : widget.type == QadaType.prayer
                    ? l10n.qadaDefaultPrayerName
                    : l10n.qadaDefaultFastName;

            widget.onAdd(
              name,
              count,
              _notesController.text.isNotEmpty ? _notesController.text : null,
            );
            Navigator.pop(context);
          },
          child: Text(l10n.qadaAdd, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
