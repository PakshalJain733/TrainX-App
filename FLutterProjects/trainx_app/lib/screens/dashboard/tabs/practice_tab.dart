import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/coding_service.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  List<Map<String, dynamic>> _problems = [];
  bool _loading = true;
  String _selectedDifficulty = 'All';
  String _searchQuery = '';

  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    setState(() => _loading = true);
    final list = await CodingService.getPracticeProblems();
    if (!mounted) return;
    setState(() {
      _problems = list;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredProblems {
    return _problems.filter((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? p['topic'] ?? '').toString().toLowerCase();
      final diff = (p['difficulty'] ?? 'Medium').toString();

      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          category.contains(_searchQuery.toLowerCase());

      final matchesDiff = _selectedDifficulty == 'All' ||
          diff.toLowerCase() == _selectedDifficulty.toLowerCase();

      return matchesQuery && matchesDiff;
    }).toList();
  }

  void _showProblemModal(Map<String, dynamic> prob) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prob['title'] ?? 'Problem Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                _difficultyPill(prob['difficulty'] ?? 'Medium'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${prob['category'] ?? 'DSA'}  •  ${prob['points'] ?? 100} XP',
              style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              'Problem Statement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  prob['description'] ?? 'No description provided for this coding problem.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Use the desktop browser web IDE for full Monaco code editor execution.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrainXColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.code_rounded, size: 18),
                label: const Text('Solve in Web IDE', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyPill(String diff) {
    Color bg = const Color(0xFFD1FAE5);
    Color fg = const Color(0xFF065F46);
    Color border = const Color(0xFF6EE7B7);

    final d = diff.toLowerCase();
    if (d == 'medium') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      border = const Color(0xFFFDE68A);
    } else if (d == 'hard') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      border = const Color(0xFFFECACA);
    }

    return BadgePill(text: diff.toUpperCase(), bg: bg, textColor: fg, borderColor: border);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
    }

    final total = _problems.length;
    final solved = _problems.where((p) => p['solve_status'] == 'Solved' || p['solved'] == true).length;
    final pct = total > 0 ? ((solved / total) * 100).round() : 0;
    final displayList = _filteredProblems;

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      body: RefreshIndicator(
        color: TrainXColors.primary,
        onRefresh: _loadProblems,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TrainXColors.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coding Arena',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'DSA Practice Problems',
                              style: TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          '$solved / $total Solved ($pct%)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: TrainXColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: total > 0 ? (solved / total) : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: TrainXColors.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by title or topic...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: TrainXColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TrainXColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TrainXColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Difficulty Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _difficulties.map((diff) {
                    final isSel = _selectedDifficulty == diff;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(diff),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : TrainXColors.textSecondary,
                        ),
                        selectedColor: TrainXColors.primary,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSel ? TrainXColors.primary : TrainXColors.borderLight,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _selectedDifficulty = diff),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Problems list
              if (displayList.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(28.0),
                  child: Center(
                    child: Text(
                      'No matching problems found.',
                      style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  itemBuilder: (ctx, i) {
                    final p = displayList[i];
                    final isSolved = p['solve_status'] == 'Solved' || p['solved'] == true;
                    final title = p['title'] ?? 'Problem';
                    final category = p['category'] ?? p['topic'] ?? 'General DSA';
                    final diff = p['difficulty'] ?? 'Medium';
                    final points = p['points'] ?? 100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: TrainXColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSolved ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            size: 20,
                            color: isSolved ? TrainXColors.emerald : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: TrainXColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$category  •  $points XP',
                                  style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          _difficultyPill(diff),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: TrainXColors.textMuted),
                            onPressed: () => _showProblemModal(p),
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

extension _IterableFilter<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
