import 'package:flutter/material.dart';
import 'dashboard/student_dashboard_shell.dart';
import 'dashboard/super_admin_dashboard_shell.dart';
import 'dashboard/admin_dashboard_shell.dart';
import 'dashboard/trainer_dashboard_shell.dart';
import '../services/app_update_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveUserRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkAndPrompt(context);
      }
    });
  }

  Future<void> _resolveUserRole() async {
    final canonicalRole = await AuthService.resolveCanonicalRole();

    if (!mounted) return;
    setState(() {
      _role = canonicalRole;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0053C0)),
        ),
      );
    }

    if (_role == 'super_admin') {
      return const SuperAdminDashboardShell();
    }
    if (_role == 'college_admin' || _role == 'admin') {
      return const AdminDashboardShell();
    }
    if (_role == 'trainer' || _role == 'mentor') {
      return TrainerDashboardShell(role: _role ?? 'trainer');
    }
    if (_role == 'coordinator') {
      return const TrainerDashboardShell(role: 'coordinator');
    }

    return const StudentDashboardShell();
  }
}
