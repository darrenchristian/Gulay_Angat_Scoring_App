import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class JudgeScorecardScreen extends StatefulWidget {
  final EventModel event;
  final ContestantModel contestant;
  final JudgeModel judge;
  final CriteriaGroupModel? category;
  final List<CriterionModel> criteria;
  final ScoreSubmissionModel? existingScore;

  const JudgeScorecardScreen({
    super.key,
    required this.event,
    required this.contestant,
    required this.judge,
    this.category,
    required this.criteria,
    this.existingScore,
  });

  @override
  State<JudgeScorecardScreen> createState() => _JudgeScorecardScreenState();
}

class _JudgeScorecardScreenState extends State<JudgeScorecardScreen> {
  final Map<String, double> _scores = {};
  late TextEditingController _remarksController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final categoryId = widget.category?.id ?? '';

    // Initialize criteria scores from existing or default to 80% baseline
    for (final criterion in widget.criteria) {
      if (widget.existingScore != null &&
          widget.existingScore!.criteriaScores.containsKey(criterion.id)) {
        _scores[criterion.id] = widget.existingScore!.criteriaScores[criterion.id]!;
      } else {
        _scores[criterion.id] = (criterion.maxScore * 0.8).roundToDouble();
      }
    }

    // Initialize remarks: category-specific remarks if category is present, otherwise general remarks
    final initialRemarks = (widget.category != null)
        ? (widget.existingScore?.categoryRemarks[categoryId] ?? '')
        : (widget.existingScore?.remarks ?? '');
    _remarksController = TextEditingController(text: initialRemarks);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  double _getScoreFor(CriterionModel c) {
    return _scores[c.id] ??
        widget.existingScore?.criteriaScores[c.id] ??
        (c.maxScore * 0.8).roundToDouble();
  }

  double _calculateCategoryTotal() {
    double total = 0.0;
    for (final criterion in widget.criteria) {
      total += _getScoreFor(criterion);
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double _calculateCategoryMax() {
    return widget.criteria.fold<double>(0.0, (sum, c) => sum + c.maxScore);
  }

  void _updateScore(String criterionId, double newScore, double maxScore) {
    setState(() {
      _scores[criterionId] = newScore.clamp(0.0, maxScore);
    });
  }

  void _confirmAndSubmit() {
    if (widget.category?.isLocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.category!.name} is currently locked by the administrator.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (widget.contestant.isEliminated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This contestant has been eliminated and scores cannot be submitted.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    for (final criterion in widget.criteria) {
      _scores.putIfAbsent(criterion.id, () => _getScoreFor(criterion));
    }

    final double total = _calculateCategoryTotal();
    final double maxPossible = _calculateCategoryMax();
    final categoryId = widget.category?.id ?? '';
    final bool isAlreadySubmitted = widget.existingScore != null &&
        widget.existingScore!.isCategorySubmitted(categoryId, widget.criteria);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              isAlreadySubmitted ? 'Update Category Score' : 'Submit Category Score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isAlreadySubmitted ? "Update" : "Submit"} scores for Contestant #${widget.contestant.number} - ${widget.contestant.name}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
            if (widget.category != null) ...[
              const SizedBox(height: 6),
              Text(
                'Category: ${widget.category!.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${total.toStringAsFixed(1)} / ${maxPossible.toStringAsFixed(0)} pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scores for this category are saved immediately and permanently in Firestore.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Review'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _submitScore();
            },
            child: Text(isAlreadySubmitted ? 'Confirm Update' : 'Confirm & Save'),
          ),
        ],
      ),
    );
  }

  void _submitScore() async {
    setState(() => _isSubmitting = true);

    try {
      final categoryId = widget.category?.id ?? '';

      // Merge current category scores with any previously submitted scores for other categories
      final Map<String, double> mergedCriteriaScores = Map<String, double>.from(
        widget.existingScore?.criteriaScores ?? {},
      );

      for (final c in widget.criteria) {
        mergedCriteriaScores[c.id] = _getScoreFor(c);
      }

      // Track submitted category IDs
      final Set<String> updatedCategoryIds = Set<String>.from(
        widget.existingScore?.submittedCategoryIds ?? [],
      );
      if (categoryId.isNotEmpty) {
        updatedCategoryIds.add(categoryId);
      }

      // Track category remarks
      final Map<String, String> updatedCategoryRemarks = Map<String, String>.from(
        widget.existingScore?.categoryRemarks ?? {},
      );
      final remarkText = _remarksController.text.trim();
      if (categoryId.isNotEmpty) {
        if (remarkText.isNotEmpty) {
          updatedCategoryRemarks[categoryId] = remarkText;
        } else {
          updatedCategoryRemarks.remove(categoryId);
        }
      }

      // Compute total score across all scored criteria
      final double newTotalScore = mergedCriteriaScores.values.fold(0.0, (s, v) => s + v);

      final submission = ScoreSubmissionModel(
        id: ScoreSubmissionModel.generateId(
          contestantId: widget.contestant.id,
          judgeId: widget.judge.id,
        ),
        eventId: widget.event.id,
        contestantId: widget.contestant.id,
        judgeId: widget.judge.id,
        judgeNumber: widget.judge.judgeNumber,
        criteriaScores: mergedCriteriaScores,
        totalScore: double.parse(newTotalScore.toStringAsFixed(2)),
        remarks: categoryId.isEmpty ? remarkText : (widget.existingScore?.remarks ?? ''),
        submittedCategoryIds: updatedCategoryIds.toList(),
        categoryRemarks: updatedCategoryRemarks,
        isSubmitted: true,
        submittedAt: widget.existingScore?.submittedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bool syncedImmediately = await FirestoreService().submitScore(submission);

      if (mounted) {
        final catLabel = widget.category?.name ?? 'Scorecard';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  syncedImmediately ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    syncedImmediately
                        ? '$catLabel saved for #${widget.contestant.number} ${widget.contestant.name}!'
                        : '$catLabel saved offline for #${widget.contestant.number} — will sync automatically.',
                  ),
                ),
              ],
            ),
            backgroundColor: syncedImmediately ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit score: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculateCategoryTotal();
    final double maxPossible = _calculateCategoryMax();
    final category = widget.category;
    final categoryName = category?.name ?? 'Category Criteria';
    final categoryId = category?.id ?? '';
    final bool isAlreadySubmitted = widget.existingScore != null &&
        widget.existingScore!.isCategorySubmitted(categoryId, widget.criteria);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Score Contestant #${widget.contestant.number}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.judge.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contestant Profile Header Banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '#${widget.contestant.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.contestant.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: widget.contestant.isEliminated
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: widget.contestant.isEliminated
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (widget.contestant.isEliminated) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'ELIMINATED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.contestant.representation.isNotEmpty)
                        Text(
                          widget.contestant.representation,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.contestant.isEliminated
                                ? AppColors.textMuted
                                : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Submitted badge if already saved
                if (isAlreadySubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Scored',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Elimination Banner if eliminated
          if (widget.contestant.isEliminated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.error.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.block, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This contestant has been eliminated by the administrator and is locked from further scoring.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Category Locked Banner if locked
          if (category?.isLocked == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.danger.withValues(alpha: 0.08),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: AppColors.danger),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This category is currently locked by the administrator. Scores cannot be submitted.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Category Badge Header (Reminds the Judge what segment they are scoring)
          if (category != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: category.affectsOverallScore
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.amber.withValues(alpha: 0.08),
                border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Icon(
                    category.affectsOverallScore
                        ? Icons.pie_chart_rounded
                        : Icons.military_tech_rounded,
                    size: 18,
                    color: category.affectsOverallScore ? AppColors.primary : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                category.affectsOverallScore
                                    ? '${category.weightPercentage.toStringAsFixed(0)}% in Final'
                                    : 'Special Award',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: category.affectsOverallScore
                                      ? AppColors.primary
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (category.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            category.description,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Criteria List for THIS Category Only
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...widget.criteria.asMap().entries.map((entry) {
                  final index = entry.key;
                  final criterion = entry.value;
                  final maxScore = criterion.maxScore;
                  final scoreVal = _getScoreFor(criterion);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      criterion.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (criterion.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        criterion.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Score badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${scoreVal.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              thumbColor: AppColors.primary,
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              overlayColor: AppColors.primary.withValues(alpha: 0.15),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: scoreVal.clamp(0.0, maxScore),
                              min: 0.0,
                              max: maxScore,
                              divisions: maxScore <= 20 ? (maxScore * 2).toInt() : maxScore.toInt(),
                              label: scoreVal.toStringAsFixed(1),
                              onChanged: (val) {
                                _updateScore(criterion.id, val, maxScore);
                              },
                            ),
                          ),

                          // Stepper quick adjust buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: scoreVal > 0
                                        ? () => _updateScore(criterion.id, scoreVal - 1, maxScore)
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: scoreVal < maxScore
                                        ? () => _updateScore(criterion.id, scoreVal + 1, maxScore)
                                        : null,
                                  ),
                                ],
                              ),
                              Text(
                                'Weight: ${criterion.weightPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Category Remarks Field
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category != null
                              ? '${category.name} Comments & Remarks (Optional)'
                              : 'Comments & Remarks (Optional)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _remarksController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Add constructive feedback specific to $categoryName...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Submission Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category != null ? '${category.name} Score' : 'Total Score',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Row(
                        children: [
                          Text(
                            '${total.toStringAsFixed(1)} / ${maxPossible.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            ' pts',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isSubmitting ||
                              widget.contestant.isEliminated ||
                              widget.category?.isLocked == true)
                          ? null
                          : _confirmAndSubmit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: isAlreadySubmitted ? AppColors.success : AppColors.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isAlreadySubmitted
                                      ? Icons.check_circle_rounded
                                      : Icons.send_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAlreadySubmitted
                                      ? 'Update $categoryName Score'
                                      : 'Submit $categoryName Score',
                                ),
                              ],
                            ),
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
