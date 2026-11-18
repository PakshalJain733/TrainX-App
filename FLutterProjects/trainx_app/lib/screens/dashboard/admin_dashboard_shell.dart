import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _currentIndex = 0;
  String _adminName = 'College Admin';
  String _adminEmail = '';
  String _collegeName = 'College Administrator';
  bool _loading = false;

  List<dynamic> _batches = [];
  List<dynamic> _pendingUsers = [];
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchAdminData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adminName = prefs.getString('studentName') ?? prefs.getString('userName') ?? 'College Admin';
      _adminEmail = prefs.getString('studentEmail') ?? prefs.getString('userEmail') ?? '';
      _collegeName = prefs.getString('collegeName') ?? 'College Portal';
    });
  }

  Future<void> _fetchAdminData() async {
    setState(() => _loading = true);
    try {
      final batchRes = await ApiClient.get('/admin/batches');
      if (batchRes['success'] == true && batchRes['data'] is List) {
        _batches = batchRes['data'];
      } else {
        final publicBatches = await ApiClient.get('/batches');
        if (publicBatches['success'] == true && publicBatches['data'] is List) {
          _batches = publicBatches['data'];
        }
      }

      final pendingRes = await ApiClient.get('/admin/pending-users');
      if (pendingRes['success'] == true && pendingRes['data'] is List) {
        _pendingUsers = pendingRes['data'];
      }

      final statsRes = await ApiClient.get('/admin/users');
      if (statsRes['success'] == true && statsRes['data'] is List) {
        _totalStudents = (statsRes['data'] as List).where((u) => u['role'] == 'student').length;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of your Admin Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _buildOverview() {
    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2942), Color(0xFF0053C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('College Administration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text('ADMIN', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$_collegeName • $_adminName', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                  if (_adminEmail.isNotEmpty)
                    Text(_adminEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Institutional Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildCard('Batches', '${_batches.length}', 'Active training batches', Icons.class_rounded, const Color(0xFF0053C0)),
                _buildCard('Students', '$_totalStudents', 'Enrolled candidates', Icons.school_rounded, const Color(0xFF10B981)),
                _buildCard('Pending', '${_pendingUsers.length}', 'Awaiting approval', Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
                _buildCard('Attendance', '88%', 'Average eligibility', Icons.check_circle_rounded, const Color(0xFF8B5CF6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String count, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(sub, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildBatchesTab() {
    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      child: _batches.isEmpty
          ? const Center(child: Text('No batches found for this institution.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _batches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final b = _batches[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.code_rounded, color: Color(0xFF0053C0)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['name']?.toString() ?? 'Batch', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Year: ${b['year'] ?? 'N/A'} • Div: ${b['division'] ?? 'A'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildApprovalsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      child: _pendingUsers.isEmpty
          ? const Center(child: Text('All registrations are currently up to date.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final u = _pendingUsers[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name']?.toString() ?? 'Applicant', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(u['email']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await ApiClient.post('/admin/approve-user', {'userId': u['id']});
                          _fetchAdminData();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                        child: const Text('Approve'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Image.asset('assets/images/Logo.png', height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Color(0xFF0053C0))),
            const SizedBox(width: 8),
            const Text('TrainX', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
              child: const Text('COLLEGE ADMIN', style: TextStyle(color: Color(0xFF0053C0), fontWeight: FontWeight.w800, fontSize: 9.5)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0053C0)))
          : (_currentIndex == 0 ? _buildOverview() : (_currentIndex == 1 ? _buildBatchesTab() : _buildApprovalsTab())),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_rounded), label: 'Batches'),
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg_rounded), label: 'Approvals'),
        ],
      ),
    );
  }
}
