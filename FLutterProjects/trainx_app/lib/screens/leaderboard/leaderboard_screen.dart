import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/widgets.dart';
import '../../services/student_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isEmbedded;
  const LeaderboardScreen({super.key, this.isEmbedded = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic> _myRank = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      StudentService.getLeaderboard(),
      StudentService.getMyRank(),
    ]);

    if (!mounted) return;
    setState(() {
      _leaderboard = results[0] as List<Map<String, dynamic>>;
      _myRank = results[1] as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: TrainXColors.primary))
        : RefreshIndicator(
            color: TrainXColors.primary,
            onRefresh: _loadLeaderboard,
            child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My Rank Highlight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), TrainXColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: TrainXColors.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YOUR CURRENT RANK',
                                style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#${_myRank['rank'] ?? _myRank['currentRank'] ?? 'N/A'} in Batch',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_myRank['xp'] ?? _myRank['points'] ?? 0} XP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Top Student Rankings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TrainXColors.textPrimary),
                  ),
                  const SizedBox(height: 10),

                  if (_leaderboard.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No leaderboard records yet.',
                          style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._leaderboard.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      final name = item['name'] ?? 'Student';
                      final batch = item['batch'] ?? 'Batch';
                      final score = item['score'] ?? item['xp'] ?? '0 XP';

                      Color rankBg = const Color(0xFFF1F5F9);
                      Color rankFg = const Color(0xFF475569);
                      if (rank == 1) { rankBg = TrainXColors.gold; rankFg = Colors.white; }
                      else if (rank == 2) { rankBg = TrainXColors.silver; rankFg = Colors.white; }
                      else if (rank == 3) { rankBg = TrainXColors.bronze; rankFg = Colors.white; }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TrainXColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                '#$rank',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: rankFg),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InitialsAvatar(name: name, radius: 17, fontSize: 11, backgroundColor: TrainXColors.primaryLight, textColor: TrainXColors.primaryDark),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  Text(batch.toString(), style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted)),
                                ],
                              ),
                            ),
                            Text(
                              score.toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TrainXColors.primaryDark),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      appBar: AppBar(
        title: const Text('Batch Leaderboard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: content,
    );
  }
}
