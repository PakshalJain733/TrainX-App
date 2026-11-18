import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/student_service.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  Map<String, dynamic> _attendance = {};
  bool _loading = true;

  // Leave form controllers
  final _reasonCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  String _category = 'Medical Leave';
  bool _submittingLeave = false;
  String _leaveFeedback = '';

  final List<String> _categories = [
    'Medical Leave',
    'Academic Event / Competition',
    'Personal Emergency',
    'Other Special Reason',
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    final data = await StudentService.getAttendance();
    if (!mounted) return;
    setState(() {
      _attendance = data;
      _loading = false;
    });
  }

  void _showQrScannerModal() {
    final codeCtrl = TextEditingController();
    String? modalError;
    String? modalSuccess;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF0053C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Attendance QR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Point camera at lecture QR or enter session code',
                            style: TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Viewfinder Container
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: -2,
                              left: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              left: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
                                ),
                              ),
                            ),
                            // Scanning laser line
                            Container(
                              height: 2,
                              width: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Text(
                          modalSuccess != null ? 'QR Code Scanned!' : 'Align QR code within the frame',
                          style: TextStyle(
                            color: modalSuccess != null ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (modalError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modalError!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (modalSuccess != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modalSuccess!,
                            style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Text(
                  'Or enter session code manually:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. ATT-XXXX or session code',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0053C0), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final code = codeCtrl.text.trim();
                              if (code.isEmpty) {
                                setModalState(() {
                                  modalError = 'Please enter a valid session code.';
                                  modalSuccess = null;
                                });
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                modalError = null;
                                modalSuccess = null;
                              });

                              try {
                                final res = await StudentService.markAttendance(code);
                                if (!ctx.mounted) return;

                                if (res['success'] == true || res['error'] == null) {
                                  final msg = res['message'] ?? 'Attendance marked Present successfully!';
                                  setModalState(() {
                                    isSubmitting = false;
                                    modalSuccess = msg;
                                    modalError = null;
                                  });
                                  _loadAttendance();
                                  Future.delayed(const Duration(milliseconds: 1400), () {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  });
                                } else {
                                  setModalState(() {
                                    isSubmitting = false;
                                    modalError = res['message'] ?? res['error'] ?? 'Invalid or expired QR code.';
                                    modalSuccess = null;
                                  });
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                setModalState(() {
                                  isSubmitting = false;
                                  modalError = e.toString().replaceAll('Exception: ', '');
                                  modalSuccess = null;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0053C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplyLeaveModal() {
    _reasonCtrl.clear();
    _fromCtrl.text = DateTime.now().toString().split(' ').first;
    _toCtrl.text = DateTime.now().add(const Duration(days: 1)).toString().split(' ').first;
    _leaveFeedback = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'Apply for Official Leave',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Submit an application to coordinator for leave verification',
                  style: TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                ),
                const SizedBox(height: 16),

                const Text('Leave Category *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TrainXColors.pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setModalState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _fromCtrl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: TrainXColors.pageBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _toCtrl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: TrainXColors.pageBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('Reason *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                const SizedBox(height: 4),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Briefly explain reason for absence...',
                    filled: true,
                    fillColor: TrainXColors.pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_leaveFeedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_leaveFeedback, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submittingLeave
                        ? null
                        : () async {
                            if (_reasonCtrl.text.trim().isEmpty) {
                              setModalState(() => _leaveFeedback = 'Please enter a reason.');
                              return;
                            }
                            setModalState(() => _submittingLeave = true);
                            final res = await StudentService.applyLeave(
                              category: _category,
                              fromDate: _fromCtrl.text.trim(),
                              toDate: _toCtrl.text.trim(),
                              reason: _reasonCtrl.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave application submitted successfully!'),
                                  backgroundColor: TrainXColors.emerald,
                                ),
                              );
                              _loadAttendance();
                            } else {
                              setModalState(() {
                                _submittingLeave = false;
                                _leaveFeedback = res['message'] ?? 'Failed to apply leave.';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrainXColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submittingLeave
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.w700)),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
    }

    final percentage = int.tryParse((_attendance['overallPercentage'] ?? 0).toString().split('.').first) ?? 0;
    final attended = _attendance['attendedClasses'] ?? 0;
    final missed = _attendance['missedClasses'] ?? 0;
    final total = _attendance['totalClasses'] ?? 0;
    final isLow = _attendance['isLowAttendance'] == true || (total > 0 && percentage < 75);
    final history = (_attendance['attendanceHistory'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final verifications = (_attendance['verifications'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      body: RefreshIndicator(
        color: TrainXColors.primary,
        onRefresh: _loadAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row matching ST_Attendance.jsx
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Attendance & Reports',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track attendance eligibility & history',
                        style: TextStyle(fontSize: 11.5, color: TrainXColors.textMuted),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showQrScannerModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0053C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF38BDF8)),
                    label: const Text(
                      'Scan QR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scan QR Hero Banner (unmissable, TrainX navy-to-blue gradient)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2942), Color(0xFF0053C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0053C0).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showQrScannerModal,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Scan QR for Attendance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap to scan lecture QR or enter code',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code, size: 14, color: Color(0xFF0053C0)),
                                SizedBox(width: 4),
                                Text(
                                  'Scan',
                                  style: TextStyle(
                                    color: Color(0xFF0053C0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Attendance Overview Card with circular ring percentage
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TrainXColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Circular percentage indicator
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: total > 0 ? (percentage / 100).clamp(0.0, 1.0) : 0,
                                strokeWidth: 7,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLow ? const Color(0xFFEF4444) : TrainXColors.emerald,
                                ),
                              ),
                              Center(
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isLow ? const Color(0xFFEF4444) : TrainXColors.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isLow ? 'Low Attendance' : 'Good Standing',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isLow ? const Color(0xFFDC2626) : const Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                    size: 18,
                                    color: isLow ? const Color(0xFFDC2626) : TrainXColors.emerald,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLow
                                    ? 'Your attendance is below the mandatory 75% threshold.'
                                    : 'You are currently meeting the mandatory 75% attendance criteria.',
                                style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Metrics row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricItem('Attended', '$attended', TrainXColors.emerald),
                        _metricItem('Missed', '$missed', const Color(0xFFEF4444)),
                        _metricItem('Total Sessions', '$total', TrainXColors.textPrimary),
                        _metricItem('Threshold', '75%', TrainXColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Apply for leave CTA bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TrainXColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need to request leave?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('Apply with coordinator for verification', style: TextStyle(fontSize: 11, color: TrainXColors.textMuted)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showApplyLeaveModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TrainXColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Apply Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Leave requests status if any
              if (verifications.isNotEmpty) ...[
                SectionCard(
                  title: 'Leave Applications',
                  description: 'Status of your submitted leave forms',
                  icon: Icons.assignment_outlined,
                  iconColor: TrainXColors.orange,
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: verifications.map((v) {
                        final isApproved = (v['status'] ?? '').toString().toLowerCase() == 'approved';
                        final isPending = (v['status'] ?? '').toString().toLowerCase() == 'pending';
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v['category'] ?? 'Leave', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text('${v['date']} • ${v['days']} Day(s)', style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted)),
                                ],
                              ),
                              BadgePill(
                                text: (v['status'] ?? 'Pending').toString().toUpperCase(),
                                bg: isApproved ? const Color(0xFFD1FAE5) : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                                textColor: isApproved ? const Color(0xFF065F46) : (isPending ? const Color(0xFF92400E) : const Color(0xFF991B1B)),
                                borderColor: isApproved ? const Color(0xFF6EE7B7) : (isPending ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Attendance History Logs
              SectionCard(
                title: 'Attendance History',
                description: 'Detailed session-wise verification logs',
                icon: Icons.calendar_today_rounded,
                iconColor: TrainXColors.primary,
                body: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No attendance records found yet for this semester.',
                            style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: history.map((log) {
                            final isPresent = (log['status'] ?? '').toString().toLowerCase() == 'present';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: TrainXColors.pageBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: TrainXColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isPresent ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 18,
                                      color: isPresent ? TrainXColors.emerald : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['subject'] ?? log['session_title'] ?? log['batch_name'] ?? 'Training Session',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        Text(
                                          log['date'] ?? log['created_at'] ?? 'Recorded date',
                                          style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  BadgePill(
                                    text: isPresent ? 'PRESENT' : 'ABSENT',
                                    bg: isPresent ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                    textColor: isPresent ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                    borderColor: isPresent ? const Color(0xFF6EE7B7) : const Color(0xFFFECACA),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: TrainXColors.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
