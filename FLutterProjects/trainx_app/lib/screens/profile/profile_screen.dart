import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/widgets.dart';
import '../../services/student_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _semCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _cgpaCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _deptCtrl.dispose();
    _semCtrl.dispose();
    _rollCtrl.dispose();
    _cgpaCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final data = await StudentService.getProfile();
    final student = (data['studentProfile'] as Map?)?.cast<String, dynamic>() ?? {};

    if (!mounted) return;
    setState(() {
      _nameCtrl.text = data['name'] ?? data['fullName'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _mobileCtrl.text = data['mobile_number'] ?? data['mobile'] ?? '';
      _deptCtrl.text = student['department'] ?? data['department'] ?? '';
      _semCtrl.text = (student['semester'] ?? data['semester'] ?? '').toString();
      _rollCtrl.text = student['roll_number'] ?? data['roll_number'] ?? '';
      _cgpaCtrl.text = (student['cgpa'] ?? data['cgpa'] ?? '').toString();
      _skillsCtrl.text = student['skills'] ?? data['skills'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final res = await StudentService.updateProfile({
      'name': _nameCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'semester': _semCtrl.text.trim(),
      'roll_number': _rollCtrl.text.trim(),
      'cgpa': _cgpaCtrl.text.trim(),
      'skills': _skillsCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: TrainXColors.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update profile.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TrainXColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TrainXColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            name: _nameCtrl.text,
                            radius: 30,
                            fontSize: 18,
                            backgroundColor: TrainXColors.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Student Name',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _emailCtrl.text,
                                  style: const TextStyle(fontSize: 12.5, color: TrainXColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                const BadgePill(
                                  text: 'STUDENT ACCOUNT',
                                  bg: TrainXColors.primaryLight,
                                  textColor: TrainXColors.primary,
                                  borderColor: TrainXColors.primaryBorder,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Academic Information Fields
                    const Text('Academic & Personal Details', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    _buildField('Full Name', _nameCtrl, icon: Icons.person_outline),
                    _buildField('Email Address', _emailCtrl, icon: Icons.mail_outline, readOnly: true),
                    _buildField('Department', _deptCtrl, icon: Icons.school_outlined),
                    _buildField('Semester', _semCtrl, icon: Icons.calendar_view_day_outlined),
                    _buildField('Roll Number', _rollCtrl, icon: Icons.badge_outlined),
                    _buildField('CGPA', _cgpaCtrl, icon: Icons.grade_outlined),
                    _buildField('Skills (comma-separated)', _skillsCtrl, icon: Icons.psychology_outlined, maxLines: 2),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrainXColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {required IconData icon, bool readOnly = false, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 5),
          TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(icon, size: 18, color: TrainXColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TrainXColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TrainXColors.borderLight)),
            ),
          ),
        ],
      ),
    );
  }
}
