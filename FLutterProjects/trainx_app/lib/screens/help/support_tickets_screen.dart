import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/widgets.dart';
import '../../services/student_service.dart';

class SupportTicketsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SupportTicketsScreen({super.key, this.isEmbedded = false});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;

  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Technical';
  String _priority = 'Medium';
  bool _creating = false;

  final List<String> _categories = ['Technical', 'Course / Academic', 'Attendance Query', 'Assessment Issue', 'Other'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    final list = await StudentService.getSupportTickets();
    if (!mounted) return;
    setState(() {
      _tickets = list;
      _loading = false;
    });
  }

  void _showCreateTicketModal() {
    _subjectCtrl.clear();
    _descCtrl.clear();

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
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Raise Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Reach out to college helpdesk for assistance', style: TextStyle(fontSize: 12, color: TrainXColors.textMuted)),
                const SizedBox(height: 16),

                const Text('Subject *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 5),
                TextField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Unable to submit Quiz 3',
                    filled: true,
                    fillColor: TrainXColors.pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: TrainXColors.pageBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setModalState(() => _category = v ?? _category),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: TrainXColors.pageBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setModalState(() => _priority = v ?? _priority),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('Description *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 5),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue in detail...',
                    filled: true,
                    fillColor: TrainXColors.pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _creating
                        ? null
                        : () async {
                            if (_subjectCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill subject and description.')),
                              );
                              return;
                            }
                            setModalState(() => _creating = true);
                            final res = await StudentService.createSupportTicket(
                              subject: _subjectCtrl.text.trim(),
                              category: _category,
                              priority: _priority,
                              description: _descCtrl.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            if (res['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ticket created successfully!'), backgroundColor: TrainXColors.emerald),
                              );
                              _loadTickets();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrainXColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _creating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: TrainXColors.primary))
        : RefreshIndicator(
            color: TrainXColors.primary,
            onRefresh: _loadTickets,
            child: _tickets.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      icon: Icons.help_outline_rounded,
                      title: 'No Support Tickets Found',
                      description: 'Have questions or issues? Create a support ticket to get help from your coordinator.',
                      action: ElevatedButton(
                        onPressed: _showCreateTicketModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrainXColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Raise Ticket'),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (ctx, i) {
                      final t = _tickets[i];
                      final subject = t['subject'] ?? 'Query';
                      final category = t['category'] ?? 'Technical';
                      final priority = t['priority'] ?? 'Medium';
                      final status = t['status'] ?? 'Open';
                      final isOpen = status.toString().toLowerCase() == 'open';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TrainXColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t['id'] ?? 'TICK-101', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TrainXColors.primary)),
                                BadgePill(
                                  text: status.toString().toUpperCase(),
                                  bg: isOpen ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                  textColor: isOpen ? const Color(0xFF92400E) : const Color(0xFF065F46),
                                  borderColor: isOpen ? const Color(0xFFFDE68A) : const Color(0xFF6EE7B7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('$category  •  Priority: $priority', style: const TextStyle(fontSize: 12, color: TrainXColors.textMuted)),
                            if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(t['description'].toString(), style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showCreateTicketModal,
              backgroundColor: TrainXColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Raise Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      appBar: AppBar(
        title: const Text('Support Tickets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: TrainXColors.primary),
            onPressed: _showCreateTicketModal,
          ),
        ],
      ),
      body: content,
    );
  }
}
