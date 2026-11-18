import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/student_service.dart';
import '../../../services/batch_service.dart';

class OverviewTab extends StatefulWidget {
  final VoidCallback? onNavigateToBatches;
  final VoidCallback? onNavigateToLeaderboard;

  const OverviewTab({
    super.key,
    this.onNavigateToBatches,
    this.onNavigateToLeaderboard,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  String _name = 'Student';
  String _dept = '';
  String _semester = '';
  String _rollNumber = '';
  String _cgpa = '';

  int _attendancePct = 0;
  int _batchCount = 0;
  String _rank = 'N/A';
  String _earnedXp = '0 XP';

  List<Map<String, dynamic>> _deadlines = [];
  List<Map<String, dynamic>> _leaderboard = [];

  bool _loading = true;

  // Join batch modal state
  bool _showJoinModal = false;
  final _joinCodeCtrl = TextEditingController();
  bool _joining = false;
  String _joinError = '';
  String _joinSuccess = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('studentName') ?? 'Student';
    _dept = prefs.getString('department') ?? '';
    final studentId = prefs.getString('userId') ?? '';

    final results = await Future.wait([
      StudentService.getProfile(),
      StudentService.getDashboard(),
      BatchService.getMyBatches(),
      StudentService.getLeaderboard(),
    ]);

    final profile = results[0] as Map<String, dynamic>;
    final dashboard = results[1] as Map<String, dynamic>;
    final batches = results[2] as List<Map<String, dynamic>>;
    final leaderboard = results[3] as List<Map<String, dynamic>>;

    // Extract profile details
    final studentProfile = profile['studentProfile'] as Map<String, dynamic>? ?? {};
    final profileName = profile['name'] ?? profile['fullName'] ?? profile['full_name'] ?? '';
    final dept = studentProfile['department'] ?? profile['department'] ?? _dept;
    final sem = studentProfile['semester'] ?? profile['semester'] ?? '';
    final roll = studentProfile['roll_number'] ?? profile['roll_number'] ?? '';
    final cgpa = studentProfile['cgpa'] ?? profile['cgpa'] ?? '';

    // Extract dashboard stats
    final attendance = (dashboard['attendanceSummary'] as Map?)?.cast<String, dynamic>() ?? {};
    final coding = (dashboard['codingProgress'] as Map?)?.cast<String, dynamic>() ?? {};
    final deadlines = (dashboard['upcomingDeadlines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final xp = coding['earnedXp'] ?? dashboard['earnedPoints'];

    // Map leaderboard entries
    final mappedLb = leaderboard.asMap().entries.map((e) {
      final item = Map<String, dynamic>.from(e.value);
      final itemId = (item['userId'] ?? item['id'] ?? '').toString();
      item['you'] = itemId.isNotEmpty && itemId == studentId;
      item['rank'] = item['rank'] ?? (e.key + 1);

      final itemName = (item['name'] ?? '').toString();
      final parts = itemName.trim().split(' ').where((p) => p.isNotEmpty).toList();
      item['initials'] = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : (itemName.length >= 2 ? itemName.substring(0, 2).toUpperCase() : 'ST');
      return item;
    }).toList();

    if (!mounted) return;
    setState(() {
      if (profileName.toString().isNotEmpty) _name = profileName.toString();
      _dept = dept.toString();
      _semester = sem.toString();
      _rollNumber = roll.toString();
      _cgpa = cgpa.toString();
      _attendancePct = int.tryParse(
            (attendance['percentage'] ?? 0).toString().split('.').first,
          ) ?? 0;
      _batchCount = batches.length;
      _rank = coding['currentRank']?.toString() ?? 'N/A';
      _earnedXp = xp != null ? '$xp XP' : '0 XP';
      _deadlines = deadlines;
      _leaderboard = mappedLb;
      _loading = false;
    });
  }

  Future<void> _joinBatch() async {
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _joinError = 'Please enter a valid batch code.');
      return;
    }
    setState(() {
      _joining = true;
      _joinError = '';
      _joinSuccess = '';
    });

    final result = await BatchService.joinBatch(code);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _joining = false;
        _joinSuccess = result['message'] ?? 'Successfully joined batch!';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _showJoinModal = false);
      _joinCodeCtrl.clear();
      _loadAll();
      if (widget.onNavigateToBatches != null) {
        widget.onNavigateToBatches!();
      }
    } else {
      setState(() {
        _joining = false;
        _joinError = result['message'] ?? 'Failed to join batch. Please check code.';
      });
    }
  }

  String _heroSubtitle() {
    final parts = <String>[];
    if (_dept.isNotEmpty) parts.add(_dept);
    if (_semester.isNotEmpty) {
      parts.add(_semester.toLowerCase().contains('sem')
          ? _semester
          : 'Semester $_semester');
    }
    if (_cgpa.isNotEmpty) parts.add('CGPA: $_cgpa');
    if (_rollNumber.isNotEmpty) parts.add('Roll: $_rollNumber');
    return parts.join('  |  ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: TrainXColors.primary),
      );
    }

    return RefreshIndicator(
      color: TrainXColors.primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Radiant Hero Banner (matches ST_Overview.jsx overview-hero-card-student)
            _buildHeroCard(),
            const SizedBox(height: 18),

            // 2. 4 Stats Grid (Attendance, Batches, Rank, Points)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Attendance Rate',
                  value: '$_attendancePct%',
                  hint: 'Active semester attendance',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: TrainXColors.emerald,
                  iconBg: const Color(0xFFD1FAE5),
                ),
                StatCard(
                  label: 'Active Batches',
                  value: '$_batchCount Active',
                  hint: 'Assigned training batches',
                  icon: Icons.layers_outlined,
                  iconColor: TrainXColors.primary,
                  iconBg: TrainXColors.primaryLight,
                ),
                StatCard(
                  label: 'Coding Rank',
                  value: '#$_rank',
                  hint: 'Current batch rank',
                  icon: Icons.emoji_events_outlined,
                  iconColor: TrainXColors.amber,
                  iconBg: const Color(0xFFFEF3C7),
                ),
                StatCard(
                  label: 'Earned Points',
                  value: _earnedXp,
                  hint: 'Coding & quiz points',
                  icon: Icons.bolt_rounded,
                  iconColor: TrainXColors.orange,
                  iconBg: const Color(0xFFFFEDD5),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Recent Tasks & Deadlines Section
            SectionCard(
              title: 'Recent Tasks & Deadlines',
              description: 'Your upcoming practice sessions and quizzes',
              icon: Icons.access_time_rounded,
              iconColor: TrainXColors.primary,
              trailing: const BadgePill(text: 'Current Week'),
              body: _buildDeadlines(),
            ),
            const SizedBox(height: 16),

            // 4. Leaderboard Section
            SectionCard(
              title: 'All Batches Leaderboard',
              description: 'Top performers across all training batches',
              icon: Icons.emoji_events_rounded,
              iconColor: TrainXColors.amber,
              trailing: widget.onNavigateToLeaderboard != null
                  ? TextButton(
                      onPressed: widget.onNavigateToLeaderboard,
                      child: const Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TrainXColors.primary,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 14, color: TrainXColors.primary),
                        ],
                      ),
                    )
                  : null,
              body: _buildLeaderboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    // Generate initials from _name (e.g. "Ishita Mahajan" -> "IM")
    final parts = _name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (_name.length >= 2 ? _name.substring(0, 2).toUpperCase() : 'ST');

    return Container(
      decoration: BoxDecoration(
        // Exact blue gradient from ST_Overview.css: linear-gradient(135deg, #0f2942 0%, #0053c0 100%)
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2942),
            Color(0xFF0053C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x380F2942),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with exact ST_Overview.css gradient: #0052cc to #0066ff
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052CC), Color(0xFF0066FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x400052CC),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow badge (#38bdf8 sky blue)
                    Row(
                      children: const [
                        Text(
                          '✦',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'STUDENT WORKSPACE DASHBOARD',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Welcome back, $_name!',
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (_heroSubtitle().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _heroSubtitle(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Join Batch Button
          GestureDetector(
            onTap: () => setState(() {
              _showJoinModal = !_showJoinModal;
              _joinError = '';
              _joinSuccess = '';
              _joinCodeCtrl.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    'Join Batch',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showJoinModal) _buildJoinBatchInline(),
        ],
      ),
    );
  }

  Widget _buildJoinBatchInline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enter Batch Join Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showJoinModal = false),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // White Input Box with Key Icon
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _joinCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g.  PYSH-MTQZ',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontSize: 13.5,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.vpn_key_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              if (_joinError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _joinError,
                  style: const TextStyle(
                    color: Color(0xFFFFCDD2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_joinSuccess.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _joinSuccess,
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // White Submit Code Button with Primary Blue Text
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _joining ? null : _joinBatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0053C0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _joining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0053C0),
                          ),
                        )
                      : const Text(
                          'Submit Code',
                          style: TextStyle(
                            color: Color(0xFF0053C0),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlines() {
    if (_deadlines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TrainXColors.pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TrainXColors.borderLight),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined, size: 26, color: TrainXColors.textHint),
                SizedBox(height: 6),
                Text(
                  'No pending deadlines for this week.',
                  style: TextStyle(fontSize: 12.5, color: TrainXColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: _deadlines.map((task) {
          final isPending = (task['status'] ?? 'Pending') == 'Pending';
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TrainXColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task['dueDate']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted),
                      ),
                    ],
                  ),
                ),
                BadgePill(
                  text: task['status']?.toString() ?? 'Pending',
                  bg: isPending ? const Color(0xFFF8FAFC) : const Color(0xFFD1FAE5),
                  textColor: isPending ? TrainXColors.textMuted : const Color(0xFF065F46),
                  borderColor: isPending ? TrainXColors.borderLight : const Color(0xFF6EE7B7),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: TrainXColors.pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TrainXColors.borderLight),
          ),
          child: const Text(
            'No leaderboard scores recorded yet. Rankings update automatically across all batches.',
            style: TextStyle(fontSize: 12.5, color: TrainXColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: _leaderboard.take(5).map((item) {
          final rank = item['rank'] as int? ?? 1;
          final isYou = item['you'] == true;
          final initials = item['initials']?.toString() ?? 'ST';
          final name = item['name']?.toString() ?? '';
          final batch = item['batch']?.toString() ?? '';
          final badge = item['badge']?.toString() ?? 'Overall Performer';
          final score = item['score']?.toString() ?? '0 XP';

          Color rankBg = const Color(0xFFF1F5F9);
          Color rankFg = const Color(0xFF475569);
          if (rank == 1) { rankBg = const Color(0xFFF59E0B); rankFg = Colors.white; }
          else if (rank == 2) { rankBg = const Color(0xFF94A3B8); rankFg = Colors.white; }
          else if (rank == 3) { rankBg = const Color(0xFFF97316); rankFg = Colors.white; }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isYou ? TrainXColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isYou ? TrainXColors.primaryBorder : const Color(0xFFF1F5F9),
                width: isYou ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: rankFg),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isYou ? TrainXColors.primary : const Color(0xFFF1F5F9),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isYou ? Colors.white : TrainXColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isYou ? '$name (You)' : name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isYou ? TrainXColors.primaryDark : TrainXColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        batch.isNotEmpty ? '$batch • $badge' : badge,
                        style: const TextStyle(fontSize: 10.5, color: TrainXColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isYou ? const Color(0xFFE0E7FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isYou ? const Color(0xFFC7D2FE) : TrainXColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFF97316)),
                      const SizedBox(width: 3),
                      Text(
                        score,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isYou ? TrainXColors.primaryDark : TrainXColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
