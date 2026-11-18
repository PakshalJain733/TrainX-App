import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class TrainerDashboardShell extends StatefulWidget {
  final String role;
  const TrainerDashboardShell({super.key, this.role = 'trainer'});

  @override
  State<TrainerDashboardShell> createState() => _TrainerDashboardShellState();
}

class _TrainerDashboardShellState extends State<TrainerDashboardShell> {
  String _name = 'Trainer';
  String _email = '';
  bool _loading = false;
  List<dynamic> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('studentName') ?? prefs.getString('userName') ?? 'Trainer';
      _email = prefs.getString('studentEmail') ?? prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/batches');
      if (res['success'] == true && res['data'] is List) {
        _batches = res['data'];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.role.toUpperCase();

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
              child: Text(roleLabel, style: const TextStyle(color: Color(0xFF0053C0), fontWeight: FontWeight.w800, fontSize: 9.5)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0053C0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F2942), Color(0xFF0053C0)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $_name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        if (_email.isNotEmpty)
                          Text(_email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$roleLabel Workspace • Manage students & evaluate progress', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Active Batches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  if (_batches.isEmpty)
                    const Text('No assigned batches found.')
                  else
                    ..._batches.map((b) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Row(
                            children: [
                              const Icon(Icons.groups_rounded, color: Color(0xFF0053C0)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(b['name']?.toString() ?? 'Batch', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
