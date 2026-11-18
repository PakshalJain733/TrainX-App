import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/widgets.dart';
import '../../services/student_service.dart';

class WeeklyReportsScreen extends StatefulWidget {
  final bool isEmbedded;
  const WeeklyReportsScreen({super.key, this.isEmbedded = false});

  @override
  State<WeeklyReportsScreen> createState() => _WeeklyReportsScreenState();
}

class _WeeklyReportsScreenState extends State<WeeklyReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final list = await StudentService.getWeeklyReports();
    if (!mounted) return;
    setState(() {
      _reports = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: TrainXColors.primary))
        : RefreshIndicator(
            color: TrainXColors.primary,
            onRefresh: _loadReports,
            child: _reports.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      icon: Icons.assignment_outlined,
                      title: 'No Weekly Reports Filed',
                      description: 'Your mentor reviews and weekly performance evaluations will appear here as you complete modules.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (ctx, i) {
                      final r = _reports[i];
                      final week = r['week_number'] ?? r['week'] ?? (i + 1);
                      final mentor = r['mentor_name'] ?? 'Faculty Mentor';
                      final rating = r['performance_rating'] ?? r['rating'] ?? 'Satisfactory';
                      final feedback = r['feedback'] ?? r['comments'] ?? 'Consistent progress shown in practice sessions.';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TrainXColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Week $week Report', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                BadgePill(
                                  text: rating.toString().toUpperCase(),
                                  bg: const Color(0xFFD1FAE5),
                                  textColor: const Color(0xFF065F46),
                                  borderColor: const Color(0xFF6EE7B7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Evaluator: $mentor', style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted)),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(feedback.toString(), style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155))),
                          ],
                        ),
                      );
                    },
                  ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      appBar: AppBar(
        title: const Text('Weekly Progress Reports', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: content,
    );
  }
}
