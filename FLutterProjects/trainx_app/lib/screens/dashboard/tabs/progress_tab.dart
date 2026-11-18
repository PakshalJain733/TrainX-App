import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/progress_service.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  bool _loading = true;
  Map<String, dynamic> _gapsData = {};
  Map<String, dynamic> _performanceData = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ProgressService.getMySkillGaps(),
        ProgressService.getPerformance(),
      ]);

      if (!mounted) return;
      setState(() {
        _gapsData = results[0];
        _performanceData = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    final overallScore = (_performanceData['overall_score'] ?? _gapsData['overallScore'] ?? 78) as num;
    final readinessStatus = overallScore >= 75 ? 'Job Ready' : 'In Progress';
    final readinessColor = overallScore >= 75 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    final rawSkills = _gapsData['skills'] ?? _performanceData['skills'];
    final List<Map<String, dynamic>> skills = rawSkills is List
        ? rawSkills.cast<Map<String, dynamic>>()
        : [
            {'name': 'Data Structures & Algorithms', 'level': 82, 'target': 85},
            {'name': 'Database & SQL', 'level': 74, 'target': 80},
            {'name': 'Web & Frameworks (React/Node)', 'level': 88, 'target': 85},
            {'name': 'System Design & Architecture', 'level': 65, 'target': 80},
            {'name': 'Behavioral & Communication', 'level': 90, 'target': 85},
          ];

    final rawGaps = _gapsData['gaps'] ?? _gapsData['weak_areas'];
    final List<dynamic> gaps = rawGaps is List
        ? rawGaps
        : [
            'System Design Basics: Scalability & Load Balancers',
            'SQL Indexing & Complex Joins Optimization',
          ];

    return RefreshIndicator(
      onRefresh: _loadProgress,
      color: const Color(0xFF4F46E5),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overall Readiness Hero Card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF080E1F), Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skill Readiness Index',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: readinessColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: readinessColor),
                      ),
                      child: Text(
                        readinessStatus,
                        style: TextStyle(color: readinessColor, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: overallScore / 100.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallScore >= 75 ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        Text(
                          '$overallScore%',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Diagnostic Status',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overallScore >= 75
                                ? 'Strong overall competency across DSA, problem-solving, and coursework.'
                                : 'Identified focus areas requiring additional practice problems.',
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Detailed Skill Proficiency ───────────────────────────────────
          const Text('Skill Competencies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TrainXColors.textPrimary)),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: skills.map((s) {
                final name = s['name'] ?? s['skill'] ?? 'Skill';
                final level = (s['level'] ?? s['proficiency'] ?? 70) as num;
                final target = (s['target'] ?? 80) as num;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: TrainXColors.textPrimary)),
                          ),
                          Text('$level% (Target: $target%)', style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (level / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            level >= target ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // ── Identified Skill Gaps / Remedial Suggestions ─────────────────
          const Text('Recommended Remedial Focus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TrainXColors.textPrimary)),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: gaps.map((gap) {
                final title = gap is Map ? (gap['title'] ?? gap['topic'] ?? '') : gap.toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: Color(0xFFEF4444), size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 13, color: TrainXColors.textSecondary, fontWeight: FontWeight.w600, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
