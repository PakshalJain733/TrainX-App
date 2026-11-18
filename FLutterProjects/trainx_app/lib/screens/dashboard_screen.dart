import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard/student_dashboard_shell.dart';
import 'dashboard/super_admin_dashboard_shell.dart';
import 'dashboard/admin_dashboard_shell.dart';
import 'dashboard/trainer_dashboard_shell.dart';
import '../services/app_update_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final storedRole = (prefs.getString('studentRole') ?? prefs.getString('userRole') ?? 'student')
        .toLowerCase()
        .trim();

    if (!mounted) return;
    setState(() {
      _role = storedRole;
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

    switch (_role) {
      case 'super_admin':
        return const SuperAdminDashboardShell();

      case 'college_admin':
      case 'admin':
        return const AdminDashboardShell();

      case 'trainer':
      case 'mentor':
        return TrainerDashboardShell(role: _role ?? 'trainer');

      case 'coordinator':
        return const TrainerDashboardShell(role: 'coordinator');

      case 'student':
      default:
        return const StudentDashboardShell();
    }
  }
}
