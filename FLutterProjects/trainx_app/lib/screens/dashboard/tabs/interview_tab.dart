import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/interview_service.dart';

class InterviewTab extends StatefulWidget {
  const InterviewTab({super.key});

  @override
  State<InterviewTab> createState() => _InterviewTabState();
}

class _InterviewTabState extends State<InterviewTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  final List<String> _roleOptions = [
    'Software Engineer Intern',
    'Full Stack Developer',
    'Backend Developer',
    'Data Analyst',
    'Frontend Developer',
    'QA / Testing Engineer',
    'DevOps Trainee',
  ];

  late String _selectedRole;
  final List<String> _selectedTopics = [];

  final Map<String, List<String>> _roleTopics = {
    'Software Engineer Intern': ['Data Structures & Algorithms', 'System Design', 'Core CS', 'Python'],
    'Full Stack Developer': ['JavaScript', 'React', 'Node.js', 'SQL / Databases', 'Data Structures & Algorithms'],
    'Backend Developer': ['Node.js', 'Java', 'SQL / Databases', 'System Design Basics', 'Data Structures & Algorithms'],
    'Data Analyst': ['SQL / Databases', 'Python', 'Statistics & Analytics', 'PowerBI / Tableau'],
    'Frontend Developer': ['JavaScript', 'React', 'HTML / CSS', 'TypeScript', 'Web Performance'],
    'QA / Testing Engineer': ['Automation Testing', 'Selenium / Cypress', 'Python', 'API Testing'],
    'DevOps Trainee': ['Docker & Containers', 'CI/CD Pipelines', 'Linux Basics', 'Cloud (AWS)'],
  };

  @override
  void initState() {
    super.initState();
    _selectedRole = _roleOptions[0];
    _updateTopicsForRole(_selectedRole);
    _loadHistory();
  }

  void _updateTopicsForRole(String role) {
    _selectedTopics.clear();
    final topics = _roleTopics[role] ?? ['Data Structures & Algorithms'];
    _selectedTopics.addAll(topics.take(3));
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final list = await InterviewService.getHistory();
      if (!mounted) return;
      setState(() {
        _history = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startInterviewModal() {
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Start AI Mock Interview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: TrainXColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Target Role',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: TrainXColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _selectedRole = val;
                            _updateTopicsForRole(val);
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Topics Covered',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: TrainXColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_roleTopics[_selectedRole] ?? []).map((topic) {
                    final selected = _selectedTopics.contains(topic);
                    return FilterChip(
                      label: Text(topic, style: TextStyle(fontSize: 12, color: selected ? Colors.white : TrainXColors.textPrimary)),
                      selected: selected,
                      selectedColor: const Color(0xFF4F46E5),
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (val) {
                        setModalState(() {
                          if (val) {
                            _selectedTopics.add(topic);
                          } else {
                            _selectedTopics.remove(topic);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            final res = await InterviewService.createInterview(
                              role: _selectedRole,
                              topics: _selectedTopics,
                            );
                            setModalState(() => isSubmitting = false);
                            if (!modalCtx.mounted) return;
                            Navigator.pop(modalCtx);
                            if (!mounted) return;
                            if (res['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AI Interview session initiated!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              _loadHistory();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Interview session scheduled.'),
                                  backgroundColor: const Color(0xFF4F46E5),
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Begin 15-Min Mock Interview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewPastResult(Map<String, dynamic> item) {
    final role = item['role'] ?? item['role_name'] ?? item['interview_type'] ?? 'Software Engineer';
    final score = item['overall_score'] ?? item['score'] ?? 0;
    final date = item['created_at'] != null ? item['created_at'].toString().split('T').first : 'Recent';
    final feedback = (item['feedback'] ?? item['summary'] ?? 'Session completed successfully. Practice consistently to enhance technical accuracy and clarity.').toString();
    final grade = (item['grade'] ?? (score >= 70 ? 'Excellent' : 'Completed')).toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF0053C0), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text('Conducted: $date', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Overall Score', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$score%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0053C0))),
                    ],
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFFCBD5E1)),
                  Column(
                    children: [
                      const Text('Result Grade', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(grade, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('AI Performance Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(
              feedback,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF0053C0)),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF4F46E5),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Clean Header Text (matches ST_AiInterview.jsx) ───────────────
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.smart_toy_rounded, color: Color(0xFF0053C0), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live AI Interview Simulation',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '5-minute voice-driven technical interview with real-time AI questions, speech recognition and instant evaluation.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0053C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start New Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  onPressed: _startInterviewModal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Past Sessions Header (Desktop layout from ST_AiInterview.jsx) ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 18, color: Color(0xFF0053C0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Stored Interview Evaluations & AI Suggestions',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Click any previous interview session to review full scorecards, feedback, and suggestions.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: _loadHistory,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Past Sessions List ───────────────────────────────────────────
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_history.isEmpty)
            SectionCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No Mock Interviews Yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('Launch your first session to simulate job interviews.', style: TextStyle(color: TrainXColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._history.map((item) {
              final role = item['role'] ?? item['role_name'] ?? item['interview_type'] ?? 'Software Engineer';
              final score = item['overall_score'] ?? item['score'] ?? 0;
              final date = item['created_at'] != null ? item['created_at'].toString().split('T').first : 'Recent';
              final grade = item['grade'] ?? (score >= 70 ? 'Excellent' : (score >= 40 ? 'Completed' : 'Completed'));
              final feedback = (item['feedback'] ?? item['summary'] ?? '').toString();

              return GestureDetector(
                onTap: () => _viewPastResult(item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Topic Badge & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role.toString(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0053C0),
                              ),
                            ),
                          ),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Middle Row: Score value + Grade pill
                      Row(
                        children: [
                          Text(
                            '$score%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grade.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          feedback,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // View Feedback Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0053C0),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'View Feedback',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
