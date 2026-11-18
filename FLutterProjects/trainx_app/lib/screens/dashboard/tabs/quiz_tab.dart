import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/quiz_service.dart';

class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _attempts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      QuizService.getAvailableQuizzes(),
      QuizService.getMyAttempts(),
    ]);

    if (!mounted) return;
    setState(() {
      _available = results[0];
      _attempts = results[1];
      _loading = false;
    });
  }

  void _startQuizFlow(Map<String, dynamic> quiz) async {
    final quizId = quiz['id'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: TrainXColors.primary),
      ),
    );

    final details = await QuizService.getAssessmentById(quizId);
    if (!mounted) return;
    Navigator.pop(context); // close loader

    final rawQuestions = details['questions'] ?? details['data']?['questions'];
    final questions = (rawQuestions is List) ? rawQuestions.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active questions found in this assessment.')),
      );
      return;
    }

    _openQuizModal(quiz, questions);
  }

  void _openQuizModal(Map<String, dynamic> quiz, List<Map<String, dynamic>> questions) {
    int currentQIndex = 0;
    final Map<String, dynamic> answers = {};
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final q = questions[currentQIndex];
          final qId = (q['id'] ?? currentQIndex).toString();
          final qText = q['question_text'] ?? q['question'] ?? 'Question ${currentQIndex + 1}';
          final options = [
            q['option_a'] ?? q['options']?[0] ?? 'Option A',
            q['option_b'] ?? q['options']?[1] ?? 'Option B',
            q['option_c'] ?? q['options']?[2] ?? 'Option C',
            q['option_d'] ?? q['options']?[3] ?? 'Option D',
          ];

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quiz['title'] ?? 'Assessment Quiz',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (currentQIndex + 1) / questions.length,
                  color: TrainXColors.primary,
                  backgroundColor: TrainXColors.pageBg,
                ),
                const SizedBox(height: 14),

                Text(
                  'Question ${currentQIndex + 1} of ${questions.length}',
                  style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Question Text
                Text(
                  qText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Options List
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, optIdx) {
                      final optLetter = String.fromCharCode(65 + optIdx); // A, B, C, D
                      final optText = options[optIdx].toString();
                      final isSelected = answers[qId] == optLetter || answers[qId] == optText;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            answers[qId] = optLetter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? TrainXColors.primaryLight : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? TrainXColors.primary : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected ? TrainXColors.primary : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? TrainXColors.primary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  optLetter,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : TrainXColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? TrainXColors.primaryDark : TrainXColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation (Prev / Next / Submit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentQIndex > 0)
                      OutlinedButton(
                        onPressed: () => setModalState(() => currentQIndex--),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox.shrink(),

                    if (currentQIndex < questions.length - 1)
                      ElevatedButton(
                        onPressed: () => setModalState(() => currentQIndex++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrainXColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Next Question'),
                      )
                    else
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                await QuizService.submitAssessment(
                                  id: quiz['id'],
                                  answers: answers,
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quiz submitted successfully! Score recorded.'),
                                    backgroundColor: TrainXColors.emerald,
                                  ),
                                );
                                _loadQuizzes();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrainXColors.emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Submit Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      body: RefreshIndicator(
        color: TrainXColors.primary,
        onRefresh: _loadQuizzes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TrainXColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded, color: TrainXColors.emerald, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Quizzes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${_available.length} Available  •  ${_attempts.length} Completed',
                            style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Available Quizzes Section
              SectionCard(
                title: 'Available Assessments',
                description: 'Active scheduled quizzes for your enrolled batch',
                icon: Icons.assignment_outlined,
                iconColor: TrainXColors.primary,
                trailing: BadgePill(text: '${_available.length} Active'),
                body: _available.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No pending quizzes available at this time.',
                            style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: _available.map((quiz) {
                            final title = quiz['title'] ?? 'Batch Assessment';
                            final duration = quiz['duration_minutes'] ?? quiz['duration'] ?? 15;
                            final qCount = quiz['total_questions'] ?? 5;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: TrainXColors.pageBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TrainXColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 13, color: TrainXColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text('$duration Mins', style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted)),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.help_outline_rounded, size: 13, color: TrainXColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text('$qCount Qs', style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _startQuizFlow(quiz),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TrainXColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Start', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Completed Attempts Section
              if (_attempts.isNotEmpty) ...[
                SectionCard(
                  title: 'My Quiz Results',
                  description: 'Past quiz submissions and scores',
                  icon: Icons.emoji_events_outlined,
                  iconColor: TrainXColors.amber,
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: _attempts.map((att) {
                        final title = att['assessment_title'] ?? att['title'] ?? 'Quiz Assessment';
                        final score = att['score_text'] ?? '${att['marks_obtained'] ?? att['correct_count'] ?? 0} Marks';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TrainXColors.pageBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: TrainXColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(
                                    att['submitted_at'] != null ? att['submitted_at'].toString().split('T').first : 'Completed',
                                    style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted),
                                  ),
                                ],
                              ),
                              BadgePill(
                                text: score,
                                bg: const Color(0xFFD1FAE5),
                                textColor: const Color(0xFF065F46),
                                borderColor: const Color(0xFF6EE7B7),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
