import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/widgets.dart';
import '../../../services/batch_service.dart';

class BatchesTab extends StatefulWidget {
  const BatchesTab({super.key});

  @override
  State<BatchesTab> createState() => _BatchesTabState();
}

class _BatchesTabState extends State<BatchesTab> {
  List<Map<String, dynamic>> _batches = [];
  bool _loading = true;

  // Join batch dialog controller
  final _joinCodeCtrl = TextEditingController();
  bool _joining = false;
  String _dialogError = '';
  String _dialogSuccess = '';

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    setState(() => _loading = true);
    final list = await BatchService.getMyBatches();
    if (!mounted) return;
    setState(() {
      _batches = list;
      _loading = false;
    });
  }

  void _showJoinBatchDialog() {
    _joinCodeCtrl.clear();
    _dialogError = '';
    _dialogSuccess = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.key_rounded, color: TrainXColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Join Training Batch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the secret join access code assigned to your batch (e.g. PYSH-MTQZ).',
                style: TextStyle(fontSize: 12.5, color: TrainXColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _joinCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'Enter Batch Code',
                  filled: true,
                  fillColor: TrainXColors.pageBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: TrainXColors.borderLight),
                  ),
                ),
              ),
              if (_dialogError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_dialogError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              if (_dialogSuccess.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_dialogSuccess, style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: TrainXColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: _joining
                  ? null
                  : () async {
                      final code = _joinCodeCtrl.text.trim();
                      if (code.isEmpty) {
                        setDialogState(() => _dialogError = 'Please enter a code.');
                        return;
                      }
                      setDialogState(() {
                        _joining = true;
                        _dialogError = '';
                        _dialogSuccess = '';
                      });

                      final res = await BatchService.joinBatch(code);
                      if (!mounted) return;

                      if (res['success'] == true) {
                        setDialogState(() {
                          _joining = false;
                          _dialogSuccess = res['message'] ?? 'Successfully joined!';
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadBatches();
                      } else {
                        setDialogState(() {
                          _joining = false;
                          _dialogError = res['message'] ?? 'Failed to join batch.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: TrainXColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Join Batch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchDetailsModal(Map<String, dynamic> b) {
    final batchId = b['id'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['name'] ?? b['title'] ?? 'Training Batch',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        b['track'] ?? 'General Training',
                        style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                      ),
                    ],
                  ),
                ),
                BadgePill(
                  text: (b['status'] ?? 'Active').toString().toUpperCase(),
                  bg: const Color(0xFFD1FAE5),
                  textColor: const Color(0xFF065F46),
                  borderColor: const Color(0xFF6EE7B7),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Batch Curriculum & Daily Topics',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: BatchService.getBatchDailyTopics(batchId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
                  }
                  final topics = snapshot.data ?? [];
                  if (topics.isEmpty) {
                    return const Center(
                      child: Text(
                        'No daily topics published yet for this batch.',
                        style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (ctx, i) {
                      final t = topics[i];
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
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: TrainXColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: TrainXColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['title'] ?? t['topic'] ?? 'Topic ${i + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  if (t['date'] != null)
                                    Text(
                                      t['date'].toString(),
                                      style: const TextStyle(fontSize: 11, color: TrainXColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: TrainXColors.primary));
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      body: RefreshIndicator(
        color: TrainXColors.primary,
        onRefresh: _loadBatches,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner with Join Batch CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TrainXColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TrainXColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.code_rounded, color: TrainXColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Training Batches',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${_batches.length} actively enrolled',
                            style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showJoinBatchDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TrainXColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Join', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Enrolled batches list or empty state
              if (_batches.isEmpty) ...[
                EmptyStateWidget(
                  icon: Icons.layers_outlined,
                  title: 'No Active Batches Enrolled',
                  description:
                      'You are not enrolled in any training batches yet. Ask your instructor for a batch code to get started.',
                  action: ElevatedButton(
                    onPressed: _showJoinBatchDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrainXColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Enter Batch Code'),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _batches.length,
                  itemBuilder: (ctx, i) {
                    final b = _batches[i];
                    final title = b['name'] ?? b['title'] ?? 'Training Batch';
                    final track = b['track'] ?? 'Development';
                    final trainer = b['mentor'] ?? b['trainer'] ?? 'Faculty Lead';
                    final code = b['join_code'] ?? b['code'] ?? 'BATCH-${b['id']}';
                    final status = b['status'] ?? 'Active';
                    final isActive = status.toString().toLowerCase() == 'active';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TrainXColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: TrainXColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: TrainXColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              BadgePill(
                                text: status.toString().toUpperCase(),
                                bg: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                                textColor: isActive ? const Color(0xFF065F46) : const Color(0xFF64748B),
                                borderColor: isActive ? const Color(0xFF6EE7B7) : const Color(0xFFCBD5E1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TrainXColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track,
                            style: const TextStyle(fontSize: 12.5, color: TrainXColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 15, color: TrainXColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                trainer,
                                style: const TextStyle(fontSize: 12, color: TrainXColors.textSecondary),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showBatchDetailsModal(b),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('View Curriculum', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
