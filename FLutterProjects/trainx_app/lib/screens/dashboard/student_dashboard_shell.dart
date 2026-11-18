import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'tabs/overview_tab.dart';
import 'tabs/batches_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/quiz_tab.dart';
import 'tabs/practice_tab.dart';
import 'tabs/roadmap_tab.dart';
import 'tabs/interview_tab.dart';
import 'tabs/progress_tab.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../materials/materials_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/weekly_reports_screen.dart';
import '../help/support_tickets_screen.dart';

class StudentDashboardShell extends StatefulWidget {
  const StudentDashboardShell({super.key});

  @override
  State<StudentDashboardShell> createState() => _StudentDashboardShellState();
}

class _StudentDashboardShellState extends State<StudentDashboardShell> {
  int _currentIndex = 0;
  String _studentName = 'Student';
  String _studentEmail = '';
  String _studentDept = '';

  // 12 Sidebar Navigation Items matching Frontend ST_Sidebar.jsx exactly
  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Overview', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded},
    {'title': 'Batches', 'icon': Icons.code_rounded, 'activeIcon': Icons.code_rounded},
    {'title': 'Learning Content', 'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book_rounded},
    {'title': 'Practice', 'icon': Icons.terminal_outlined, 'activeIcon': Icons.terminal_rounded},
    {'title': 'Quiz', 'icon': Icons.school_outlined, 'activeIcon': Icons.school_rounded},
    {'title': 'AI Roadmap', 'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome_rounded},
    {'title': 'AI Interview', 'icon': Icons.smart_toy_outlined, 'activeIcon': Icons.smart_toy_rounded},
    {'title': 'Progress', 'icon': Icons.insights_rounded, 'activeIcon': Icons.insights_rounded},
    {'title': 'Leaderboard', 'icon': Icons.emoji_events_outlined, 'activeIcon': Icons.emoji_events_rounded},
    {'title': 'Attendance', 'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded},
    {'title': 'Weekly Reports', 'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment_rounded},
    {'title': 'Support Tickets', 'icon': Icons.help_outline_rounded, 'activeIcon': Icons.help_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _studentName = prefs.getString('studentName') ?? prefs.getString('userName') ?? 'Student';
      _studentEmail = prefs.getString('studentEmail') ?? prefs.getString('userEmail') ?? '';
      _studentDept = prefs.getString('department') ?? '';
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of your student portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: TrainXColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(
          onNavigateToBatches: () => setState(() => _currentIndex = 1),
          onNavigateToLeaderboard: () => setState(() => _currentIndex = 8),
        );
      case 1:
        return const BatchesTab();
      case 2:
        return const MaterialsScreen(isEmbedded: true);
      case 3:
        return const PracticeTab();
      case 4:
        return const QuizTab();
      case 5:
        return const RoadmapTab();
      case 6:
        return const InterviewTab();
      case 7:
        return const ProgressTab();
      case 8:
        return const LeaderboardScreen(isEmbedded: true);
      case 9:
        return const AttendanceTab();
      case 10:
        return const WeeklyReportsScreen(isEmbedded: true);
      case 11:
        return const SupportTicketsScreen(isEmbedded: true);
      default:
        return const OverviewTab();
    }
  }

  String get _appBarTitle {
    if (_currentIndex >= 0 && _currentIndex < _navItems.length) {
      return _navItems[_currentIndex]['title'] as String;
    }
    return 'TrainX';
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      child: Material(
        color: isSelected ? const Color(0xFF0055BA) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _currentIndex = index);
            Navigator.pop(context); // Close drawer
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x380055BA),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      // ─── Top App Bar ────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.school_rounded, color: TrainXColors.primary, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Train',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Image.asset(
                      'assets/images/TrainX.png',
                      height: 14,
                      errorBuilder: (ctx, err, stack) => const Text('X', style: TextStyle(color: Color(0xFF0055BA), fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                Text(
                  _appBarTitle,
                  style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF475569)),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      // ─── Side Navigation Drawer (Exact replication of ST_Sidebar.jsx) ──────
      drawer: Drawer(
        backgroundColor: const Color(0xFFDBE6F2), // Exact --sidebar-bg
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sidebar Brand Header matching ST_Sidebar.jsx <SidebarBrand>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x1F0F172A), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.school_rounded, color: Color(0xFF0055BA), size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Train',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Image.asset(
                                'assets/images/TrainX.png',
                                height: 16,
                                errorBuilder: (ctx, err, stack) => const Text('X', style: TextStyle(color: Color(0xFF0055BA), fontWeight: FontWeight.w900, fontSize: 18)),
                              ),
                            ],
                          ),
                          const Text(
                            'Training Portal',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Navigation Items (All 12 items from ST_Sidebar.jsx)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (int i = 0; i < 11; i++)
                      _buildDrawerItem(
                        icon: _currentIndex == i ? (_navItems[i]['activeIcon'] as IconData) : (_navItems[i]['icon'] as IconData),
                        title: _navItems[i]['title'] as String,
                        index: i,
                      ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: Color(0x1F0F172A), height: 1),
                    ),

                    // Support Tickets (#12)
                    _buildDrawerItem(
                      icon: _currentIndex == 11 ? (_navItems[11]['activeIcon'] as IconData) : (_navItems[11]['icon'] as IconData),
                      title: _navItems[11]['title'] as String,
                      index: 11,
                    ),
                  ],
                ),
              ),

              // 3. Bottom Pinned Account & Logout Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x1F0F172A), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Profile quick link
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF0055BA),
                        child: Text(
                          _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      title: Text(
                        _studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _studentDept.isNotEmpty
                            ? '$_studentEmail • $_studentDept'
                            : (_studentEmail.isNotEmpty ? _studentEmail : 'Student Profile'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                    ),
                    const SizedBox(height: 6),
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ─── Main Body ──────────────────────────────────────────────────────────
      body: _buildBody(),
    );
  }
}
