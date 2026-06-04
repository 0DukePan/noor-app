import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/isnad_parser_service.dart';
import '../../../../core/services/narrator_database_service.dart';
import '../../../../core/theme/noor_theme.dart';

/// 🔗 رسم بياني تفاعلي للإسناد - Interactive Isnad DAG Graph
///
/// Renders a directed acyclic graph of the narrator chain using CustomPainter.
/// Features:
/// - Zoom + pan via InteractiveViewer
/// - Color-coded nodes by narrator type
/// - Tap node → narrator detail bottom sheet
class IsnadGraphPage extends StatefulWidget {
  final String hadithText;
  final String hadithSource;

  const IsnadGraphPage({
    super.key,
    required this.hadithText,
    this.hadithSource = '',
  });

  @override
  State<IsnadGraphPage> createState() => _IsnadGraphPageState();
}

class _IsnadGraphPageState extends State<IsnadGraphPage>
    with SingleTickerProviderStateMixin {
  List<NarratorInfo> _chain = [];
  List<_GraphNode> _nodes = [];
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    await NarratorDatabaseService.init();
    final chain = IsnadParserService.parseChain(widget.hadithText);

    if (!mounted) return;

    // Layout nodes in a vertical chain (DAG with single path)
    final nodes = <_GraphNode>[];
    const nodeWidth = 200.0;
    const nodeHeight = 60.0;
    const verticalGap = 40.0;
    const startX = 150.0;
    const startY = 30.0;

    for (var i = 0; i < chain.length; i++) {
      final narrator = chain[i];
      final profile = NarratorDatabaseService.lookupFromNarratorInfo(narrator);
      nodes.add(_GraphNode(
        narrator: narrator,
        profile: profile,
        rect: Rect.fromLTWH(
          startX,
          startY + i * (nodeHeight + verticalGap),
          nodeWidth,
          nodeHeight,
        ),
      ));
    }

    setState(() {
      _chain = chain;
      _nodes = nodes;
      _loading = false;
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('الرسم البياني للإسناد'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
        actions: [
          if (_chain.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Chip(
                label: Text('${_chain.length} راوٍ'),
                backgroundColor: NoorTheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: NoorTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _nodes.isEmpty
              ? _buildEmpty()
              : _buildGraph(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جارٍ تحليل الإسناد...'),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_rounded, size: 64, color: NoorTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على إسناد',
            style: TextStyle(color: NoorTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    // Calculate canvas size
    final canvasHeight = _nodes.isEmpty
        ? 400.0
        : _nodes.last.rect.bottom + 80;
    const canvasWidth = 500.0;

    return Column(
      children: [
        // Source info
        if (widget.hadithSource.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: NoorTheme.primary.withOpacity(0.05),
            child: Text(
              widget.hadithSource,
              style: TextStyle(
                color: NoorTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Graph
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: AnimatedBuilder(
              animation: _animProgress,
              builder: (context, _) {
                return SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: GestureDetector(
                    onTapDown: (details) => _handleTap(details.localPosition),
                    child: CustomPaint(
                      size: Size(canvasWidth, canvasHeight),
                      painter: _IsnadGraphPainter(
                        nodes: _nodes,
                        progress: _animProgress.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem('النبي ﷺ', NoorTheme.accentGold),
          _legendItem('صحابي', NoorTheme.hadithSahih),
          _legendItem('راوي', NoorTheme.primary),
          _legendItem('مؤلف', Colors.teal),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _handleTap(Offset position) {
    for (final node in _nodes) {
      if (node.rect.inflate(10).contains(position)) {
        HapticFeedback.mediumImpact();
        _showNodeDetail(node);
        return;
      }
    }
  }

  void _showNodeDetail(_GraphNode node) {
    final color = _getNodeColor(node.narrator.role);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Name + Role
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    node.narrator.role,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    node.narrator.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),

            if (node.narrator.linkWord.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'صيغة التحمل: ${node.narrator.linkWord}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textDirection: TextDirection.rtl,
              ),
            ],

            if (node.profile != null) ...[
              const Divider(height: 24),
              if (node.profile!.rank.isNotEmpty)
                _detailRow('المرتبة', node.profile!.rank),
              if (node.profile!.deathYear > 0)
                _detailRow('الوفاة', node.profile!.deathYearDisplay),
              if (node.profile!.teachers.isNotEmpty)
                _detailRow('شيوخه', node.profile!.teachers.take(4).join('، ')),
              if (node.profile!.students.isNotEmpty)
                _detailRow('تلاميذه', node.profile!.students.take(4).join('، ')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13), textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(String role) {
    if (role.contains('النبي')) return NoorTheme.accentGold;
    if (role.contains('صحابي')) return NoorTheme.hadithSahih;
    return NoorTheme.primary;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRAPH PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _IsnadGraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final double progress;

  _IsnadGraphPainter({required this.nodes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final visibleCount = (nodes.length * progress).ceil().clamp(0, nodes.length);

    // Draw edges first (behind nodes)
    for (var i = 0; i < visibleCount - 1; i++) {
      _drawEdge(canvas, nodes[i], nodes[i + 1]);
    }

    // Draw nodes
    for (var i = 0; i < visibleCount; i++) {
      _drawNode(canvas, nodes[i], i);
    }
  }

  void _drawEdge(Canvas canvas, _GraphNode from, _GraphNode to) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final start = Offset(from.rect.center.dx, from.rect.bottom);
    final end = Offset(to.rect.center.dx, to.rect.top);

    // Draw curved edge
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx, start.dy + 20,
        end.dx, end.dy - 20,
        end.dx, end.dy,
      );
    canvas.drawPath(path, paint);

    // Draw arrowhead
    final arrowPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 5, end.dy - 10)
      ..lineTo(end.dx + 5, end.dy - 10)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Draw link word label
    if (to.narrator.linkWord.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: to.narrator.linkWord,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontFamily: 'Amiri',
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final midY = (start.dy + end.dy) / 2;
      tp.paint(canvas, Offset(start.dx + 10, midY - tp.height / 2));
    }
  }

  void _drawNode(Canvas canvas, _GraphNode node, int index) {
    final color = _getColor(node.narrator.role);
    final rect = node.rect;

    // Shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(0, 3), const Radius.circular(12)),
      shadowPaint,
    );

    // Background
    final bgPaint = Paint()..color = Colors.white;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // Color indicator strip (left side)
    final stripRect = RRect.fromLTRBAndCorners(
      rect.left, rect.top, rect.left + 6, rect.bottom,
      topLeft: const Radius.circular(12),
      bottomLeft: const Radius.circular(12),
    );
    canvas.drawRRect(stripRect, Paint()..color = color);

    // Node number
    final numPainter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numPainter.paint(canvas, Offset(rect.left + 12, rect.top + 4));

    // Name
    final namePainter = TextPainter(
      text: TextSpan(
        text: node.narrator.name,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Amiri',
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - 30);
    namePainter.paint(
      canvas,
      Offset(rect.right - namePainter.width - 12, rect.top + 8),
    );

    // Role subtitle
    final rolePainter = TextPainter(
      text: TextSpan(
        text: node.narrator.role,
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    rolePainter.paint(
      canvas,
      Offset(rect.right - rolePainter.width - 12, rect.bottom - 18),
    );

    // Verified icon if profile exists
    if (node.profile != null) {
      final iconPainter = TextPainter(
        text: const TextSpan(text: '✓', style: TextStyle(fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, Offset(rect.left + 12, rect.bottom - 18));
    }
  }

  Color _getColor(String role) {
    if (role.contains('النبي')) return NoorTheme.accentGold;
    if (role.contains('صحابي')) return NoorTheme.hadithSahih;
    return NoorTheme.primary;
  }

  @override
  bool shouldRepaint(covariant _IsnadGraphPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.nodes != nodes;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class _GraphNode {
  final NarratorInfo narrator;
  final NarratorProfile? profile;
  final Rect rect;

  const _GraphNode({
    required this.narrator,
    this.profile,
    required this.rect,
  });
}
