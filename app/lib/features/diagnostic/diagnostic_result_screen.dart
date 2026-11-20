import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_model.dart';
import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../home/main_navigation_scaffold.dart';

// ---------------------------------------------------------------------------
// DiagnosticResultScreen — Screen 3: profile summary after questionnaire
// ---------------------------------------------------------------------------

class DiagnosticResultScreen extends ConsumerWidget {
  final LearnerProfile profile;

  const DiagnosticResultScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        centerTitle: true,
        title: Text(
          'Ton profil',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Celebration header ──────────────────────────────────
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  // ── Section title ───────────────────────────────────────
                  Text(
                    'Tes résultats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  // ── Dimension cards ────────────────────────────────────
                  ...profile.dimensions.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DimensionCard(dimension: d),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Reassurance note ───────────────────────────────────
                  _buildReassuranceNote(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // ── Sticky CTA ──────────────────────────────────────────────────
          _buildStickyButton(context, ref),
        ],
      ),
    );
  }

  // ── sub-builders ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Success icon with celebratory pop
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.1, end: 1.0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9F6), Color(0xFFEAF2EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: AppAssetIcon(
                assetPath: AppUiAssets.badgeSuccess,
                size: 56,
                fallbackEmoji: '✅',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ton profil est prêt !',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "L'application va adapter son aide selon tes besoins.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildReassuranceNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EC),
        border: Border.all(color: const Color(0xFFCDE3D4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppAssetIcon(
            assetPath: AppUiAssets.heartSupport,
            size: 24,
            fallbackEmoji: '💚',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Ces résultats sont uniquement là pour t'aider. Ils ne définissent pas tes capacités.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2D7A4F),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await ref
                .read(learnerProfileProvider.notifier)
                .saveCompletedProfile(profile);
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainNavigationScaffold(initialIndex: 0),
                ),
                (route) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("Commencer l'application ✓"),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DimensionCard — one result card with progress bar and flag chips
// ---------------------------------------------------------------------------

class _DimensionCard extends StatelessWidget {
  final DimensionResult dimension;

  const _DimensionCard({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                dimension.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dimension.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Severity badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dimension.level.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dimension.level.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dimension.level.badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar with smooth animated fill
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.0,
                end: (dimension.score / 100.0).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, animatedVal, _) {
                return LinearProgressIndicator(
                  value: animatedVal,
                  minHeight: 5,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    dimension.level.barColor,
                  ),
                );
              },
            ),
          ),
          // Flag chips (only if any)
          if (dimension.flags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dimension.flags
                  .map((flag) => _FlagChip(label: '🚩 $flag'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FlagChip — small pill with flag label
// ---------------------------------------------------------------------------

class _FlagChip extends StatelessWidget {
  final String label;
  const _FlagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        border: Border.all(color: const Color(0xFFFFD6D6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9B1A1A),
        ),
      ),
    );
  }
}
