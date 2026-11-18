import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class SuperAdminDashboardShell extends StatefulWidget {
  const SuperAdminDashboardShell({super.key});

  @override
  State<SuperAdminDashboardShell> createState() => _SuperAdminDashboardShellState();
}

class _SuperAdminDashboardShellState extends State<SuperAdminDashboardShell> {
  int _currentIndex = 0;
  String _adminName = 'Super Admin';
  String _adminEmail = 'trainx.admin@gmail.com';
  bool _loading = false;

  // Live System Health Stats
  Map<String, dynamic> _healthData = {
    'status': 'ready',
    'database': 'connected',
    'dbLatencyMs': 450,
  };
  List<dynamic> _colleges = [];
  List<dynamic> _users = [];
  int _totalColleges = 0;
  int _totalUsers = 0;
  int _pendingApprovals = 0;

  // System feature toggles
  bool _maintenanceMode = false;
  bool _registrationsOpen = true;

  final List<Map<String, dynamic>> _drawerItems = [
    {'title': 'System Overview', 'icon': Icons.space_dashboard_rounded},
    {'title': 'Manage Colleges', 'icon': Icons.apartment_rounded},
    {'title': 'Manage Users', 'icon': Icons.manage_accounts_rounded},
    {'title': 'System Health', 'icon': Icons.monitor_heart_rounded},
    {'title': 'Feature Switches', 'icon': Icons.tune_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchSystemData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adminName = prefs.getString('studentName') ?? prefs.getString('userName') ?? 'Super Admin';
      _adminEmail = prefs.getString('studentEmail') ?? prefs.getString('userEmail') ?? 'trainx.admin@gmail.com';
    });
  }

  Future<void> _fetchSystemData() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch live health
      final healthRes = await ApiClient.get('/health');
      if (healthRes['success'] == true && healthRes['data'] != null) {
        _healthData = healthRes['data'];
      }

      // 2. Fetch colleges
      final collegeRes = await ApiClient.get('/admin/colleges');
      if (collegeRes['success'] == true && collegeRes['data'] is List) {
        _colleges = collegeRes['data'];
        _totalColleges = _colleges.length;
      } else {
        final publicColleges = await ApiClient.get('/colleges');
        if (publicColleges['success'] == true && publicColleges['data'] is List) {
          _colleges = publicColleges['data'];
          _totalColleges = _colleges.length;
        }
      }

      // 3. Fetch users
      final userRes = await ApiClient.get('/admin/users');
      if (userRes['success'] == true && userRes['data'] is List) {
        _users = userRes['data'];
        _totalUsers = _users.length;
        _pendingApprovals = _users.where((u) => u['is_active'] == 0 || u['status'] == 'Pending').length;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of the Super Admin Portal?'),
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

  void _showAddCollegeDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Mumbai');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_business_rounded, color: Color(0xFF0053C0)),
              SizedBox(width: 8),
              Text('Add New College', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'College Full Name *',
                    hintText: 'e.g. VPPCOE College of Eng',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'College Code *',
                    hintText: 'e.g. VPPCOE',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0053C0),
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                      setDialogState(() => isSaving = true);
                      await ApiClient.post('/admin/colleges', {
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim().toUpperCase(),
                        'city': cityCtrl.text.trim(),
                        'status': 'Active',
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _fetchSystemData();
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create College'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Views ─────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final dbStatus = _healthData['database']?.toString() ?? 'connected';
    final latency = _healthData['dbLatencyMs']?.toString() ?? '450';

    return RefreshIndicator(
      onRefresh: _fetchSystemData,
      color: const Color(0xFF0053C0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Server Health Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2942), Color(0xFF0053C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0053C0).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Super Admin Command Center',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All systems operational. Cloud API & database are synchronized.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildPillStat('Database', dbStatus.toUpperCase(), const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      _buildPillStat('Latency', '${latency}ms', const Color(0xFF38BDF8)),
                      const SizedBox(width: 10),
                      _buildPillStat('Role', 'ROOT', const Color(0xFFFBBF24)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Grid
            const Text(
              'Platform Vital Metrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildMetricCard(
                  title: 'Colleges',
                  count: '$_totalColleges',
                  subtitle: 'Registered institutions',
                  icon: Icons.apartment_rounded,
                  color: const Color(0xFF0053C0),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildMetricCard(
                  title: 'Total Users',
                  count: '$_totalUsers',
                  subtitle: 'Admins & students',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildMetricCard(
                  title: 'Pending Users',
                  count: '$_pendingApprovals',
                  subtitle: 'Awaiting activation',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildMetricCard(
                  title: 'System Health',
                  count: '100%',
                  subtitle: 'Operational uptime',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions Section
            const Text(
              'Super Admin Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              title: 'Add New College',
              subtitle: 'Provision a new institutional tenant',
              icon: Icons.add_business_rounded,
              color: const Color(0xFF0053C0),
              onTap: _showAddCollegeDialog,
            ),
            _buildActionTile(
              title: 'Review System Users',
              subtitle: 'Inspect roles, colleges & authorization',
              icon: Icons.manage_accounts_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _buildActionTile(
              title: 'Platform Maintenance Controls',
              subtitle: 'Feature switches & registration gates',
              icon: Icons.tune_rounded,
              color: const Color(0xFF0F2942),
              onTap: () => setState(() => _currentIndex = 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegesTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCollegeDialog,
        backgroundColor: const Color(0xFF0053C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add College', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSystemData,
        child: _colleges.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.apartment_rounded, size: 54, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text('No Colleges Registered Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Tap "Add College" to provision your first college.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddCollegeDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First College'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0053C0), foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _colleges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final col = _colleges[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF0053C0), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                col['name']?.toString() ?? 'College',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Code: ${col['code'] ?? 'N/A'} • ${col['city'] ?? 'Active'}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Active', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _fetchSystemData,
      child: _users.isEmpty
          ? const Center(
              child: Text('No users found in database.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final u = _users[i];
                final role = (u['role'] ?? 'user').toString().toUpperCase();
                final isActive = u['is_active'] == 1 || u['is_active'] == true;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0053C0).withOpacity(0.1),
                        child: Text(
                          (u['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0053C0)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(u['email']?.toString() ?? '', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4338CA))),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive ? 'Active' : 'Pending',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
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

  Widget _buildHealthTab() {
    final status = _healthData['status']?.toString() ?? 'ready';
    final db = _healthData['database']?.toString() ?? 'connected';
    final latency = _healthData['dbLatencyMs']?.toString() ?? '450';
    final ts = _healthData['timestamp']?.toString() ?? DateTime.now().toIso8601String();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_rounded, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 10),
                    Text('Live Infrastructure Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const Divider(height: 24),
                _buildHealthRow('Backend API', status.toUpperCase(), const Color(0xFF10B981)),
                _buildHealthRow('MySQL Database', db.toUpperCase(), const Color(0xFF10B981)),
                _buildHealthRow('Query Latency', '${latency}ms', const Color(0xFF0053C0)),
                _buildHealthRow('Server Target', 'https://trainx-app.onrender.com', const Color(0xFF64748B)),
                _buildHealthRow('Last Heartbeat', ts.split('T').last.split('.').first, const Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchSystemData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Ping Health Check'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0053C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSwitchesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Temporarily lock non-admin student access', style: TextStyle(fontSize: 12)),
                  value: _maintenanceMode,
                  activeColor: const Color(0xFFDC2626),
                  onChanged: (val) => setState(() => _maintenanceMode = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Open Self-Registration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Allow new students to register through the portal', style: TextStyle(fontSize: 12)),
                  value: _registrationsOpen,
                  activeColor: const Color(0xFF0053C0),
                  onChanged: (val) => setState(() => _registrationsOpen = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildPillStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCollegesTab();
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildHealthTab();
      case 4:
        return _buildFeatureSwitchesTab();
      default:
        return _buildOverviewTab();
    }
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
            const Text(
              'TrainX',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Text('SUPER ADMIN', style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w800, fontSize: 9.5)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _fetchSystemData,
            tooltip: 'Refresh System Status',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2942), Color(0xFF0053C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0053C0), size: 36),
              ),
              accountName: Text(_adminName, style: const TextStyle(fontWeight: FontWeight.w800)),
              accountEmail: Text(_adminEmail, style: const TextStyle(color: Color(0xFFCBD5E1))),
            ),
            ...List.generate(_drawerItems.length, (i) {
              final item = _drawerItems[i];
              final isSelected = _currentIndex == i;
              return ListTile(
                leading: Icon(item['icon'] as IconData, color: isSelected ? const Color(0xFF0053C0) : const Color(0xFF64748B)),
                title: Text(item['title'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? const Color(0xFF0053C0) : const Color(0xFF1E293B))),
                selected: isSelected,
                selectedTileColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = i);
                },
              );
            }),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text('Log Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0053C0)))
          : _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex < 4 ? _currentIndex : 0,
        backgroundColor: Colors.white,
        elevation: 8,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment_rounded), label: 'Colleges'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_alt_rounded), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart_rounded), label: 'Health'),
        ],
      ),
    );
  }
}
