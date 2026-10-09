import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class JudgeScorecardScreen extends StatefulWidget {
  final EventModel event;
  final ContestantModel contestant;
  final JudgeModel judge;
  final List<CriterionModel> criteria;
  final ScoreSubmissionModel? existingScore;

  const JudgeScorecardScreen({
    super.key,
    required this.event,
    required this.contestant,
    required this.judge,
    required this.criteria,
    this.existingScore,
  });

  @override
  State<JudgeScorecardScreen> createState() => _JudgeScorecardScreenState();
}

class _JudgeScorecardScreenState extends State<JudgeScorecardScreen> {
  final Map<String, double> _scores = {};
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize criteria scores from existing or default to 0 / midpoint
    for (final criterion in widget.criteria) {
      if (widget.existingScore != null &&
          widget.existingScore!.criteriaScores.containsKey(criterion.id)) {
        _scores[criterion.id] = widget.existingScore!.criteriaScores[criterion.id]!;
      } else {
        // Default to 80% of max score as a comfortable starting baseline
        _scores[criterion.id] = (criterion.maxScore * 0.8).roundToDouble();
      }
    }

    if (widget.existingScore != null) {
      _remarksController.text = widget.existingScore!.remarks;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  double get _totalScore {
    double total = 0.0;
    for (final criterion in widget.criteria) {
      final scoreVal = _scores[criterion.id] ?? 0.0;
      total += scoreVal;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double get _maxPossibleScore {
    return widget.criteria.fold<double>(0.0, (sum, c) => sum + c.maxScore);
  }

  void _updateScore(String criterionId, double newScore, double maxScore) {
    setState(() {
      _scores[criterionId] = newScore.clamp(0.0, maxScore);
    });
  }

  void _confirmAndSubmit() {
    final double total = _totalScore;

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
            const Text('Confirm Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit score for Contestant #${widget.contestant.number} - ${widget.contestant.name}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
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
                  const Text('Total Awarded:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${total.toStringAsFixed(2)} / ${_maxPossibleScore.toStringAsFixed(0)} pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
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
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }

  void _submitScore() async {
    setState(() => _isSubmitting = true);

    try {
      final submission = ScoreSubmissionModel(
        id: ScoreSubmissionModel.generateId(
          contestantId: widget.contestant.id,
          judgeId: widget.judge.id,
        ),
        eventId: widget.event.id,
        contestantId: widget.contestant.id,
        judgeId: widget.judge.id,
        judgeNumber: widget.judge.judgeNumber,
        criteriaScores: Map.from(_scores),
        totalScore: _totalScore,
        remarks: _remarksController.text.trim(),
        isSubmitted: true,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService().submitScore(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score submitted for #${widget.contestant.number} ${widget.contestant.name}!',
            ),
            backgroundColor: AppColors.success,
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
    final double total = _totalScore;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '#${widget.contestant.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contestant.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.contestant.representation.isNotEmpty)
                        Text(
                          widget.contestant.representation,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      if (widget.contestant.bio.isNotEmpty)
                        Text(
                          widget.contestant.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Criteria List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...widget.criteria.map((criterion) {
                  final scoreVal = _scores[criterion.id] ?? 0.0;
                  final maxScore = criterion.maxScore;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                // Remarks Field
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Judge Comments & Remarks (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add constructive feedback or specific notes for this candidate...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      const Text(
                        'Total Score',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} pts',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmAndSubmit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Submit Scorecard'),
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
