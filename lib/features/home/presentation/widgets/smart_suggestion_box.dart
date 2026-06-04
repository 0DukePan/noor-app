import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../providers/home_provider.dart';

class SmartSuggestionBox extends ConsumerWidget {
  const SmartSuggestionBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select precisely what we need so it doesn't rebuild entire home page
    final suggestion = ref.watch(smartSuggestionProvider.select((s) => s));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NoorDesignSystem.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NoorDesignSystem.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: NoorDesignSystem.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '💡 اقتراح ذكي الآن:\n$suggestion',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: isDark ? Colors.white : NoorDesignSystem.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
