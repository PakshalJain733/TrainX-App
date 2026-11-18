import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_client.dart';

class RoadmapTab extends StatefulWidget {
  const RoadmapTab({super.key});

  @override
  State<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends State<RoadmapTab> {
  Map<String, dynamic> _roadmap = {};
  bool _loading = true;
  final _goalCtrl = TextEditingController(text: 'Full Stack Web Development');
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoadmap() async {
    setState(() => _loading = true);
    final res = await ApiClient.get('/roadmap/my-roadmap');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true && res['data'] is Map<String, dynamic>) {
        _roadmap = res['data'];
      } else if (res['data'] is Map<String, dynamic>) {
        _roadmap = res['data'];
      }
      _loading = false;
    });
  }

  Future<void> _generateRoadmap() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) return;

    setState(() => _generating = true);
    final res = await ApiClient.post('/roadmap/generate', {
      'target_role': goal,
      'targetRole': goal,
      'goal': goal,
    });

    if (!mounted) return;
    setState(() => _generating = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Learning Roadmap generated successfully!'),
          backgroundColor: TrainXColors.emerald,
        ),
      );
      _loadRoadmap();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Could not generate roadmap.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
    }

    final rawMilestones = _roadmap['milestones'] ?? _roadmap['steps'] ?? [];
    final milestones = (rawMilestones is List) ? rawMilestones.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    final title = _roadmap['title'] ?? _roadmap['target_role'] ?? 'AI Learning Roadmap';

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      body: RefreshIndicator(
        color: TrainXColors.primary,
        onRefresh: _loadRoadmap,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Page Header Text (no card container)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: TrainXColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Step-by-step verified milestones generated based on your academic profile.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Milestone list or Generator Form
              if (milestones.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TrainXColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generate Custom AI Roadmap',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your target technical role or specialization goal:',
                        style: TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _goalCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Full Stack Developer, Data Analyst',
                          filled: true,
                          fillColor: TrainXColors.pageBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generating ? null : _generateRoadmap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TrainXColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: _generating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Generate My Roadmap', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: milestones.length,
                  itemBuilder: (ctx, i) {
                    final m = milestones[i];
                    final stepTitle = m['title'] ?? m['milestone'] ?? 'Milestone ${i + 1}';
                    final desc = m['description'] ?? m['desc'] ?? 'Focus on mastering core fundamentals and implementation.';
                    final isDone = m['completed'] == true || m['status'] == 'completed';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone ? TrainXColors.primaryBorder : TrainXColors.borderLight,
                          width: isDone ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone ? TrainXColors.primary : TrainXColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: isDone
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: TrainXColors.primary),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stepTitle.toString(),
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc.toString(),
                                  style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
