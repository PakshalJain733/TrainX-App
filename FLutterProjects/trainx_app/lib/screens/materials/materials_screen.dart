import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/student_service.dart';

class MaterialsScreen extends StatefulWidget {
  final bool isEmbedded;
  const MaterialsScreen({super.key, this.isEmbedded = false});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _loading = true);
    final list = await StudentService.getMaterials();
    if (!mounted) return;
    setState(() {
      _materials = list;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    if (_searchQuery.isEmpty) return _materials;
    return _materials.where((m) {
      final title = (m['title'] ?? '').toString().toLowerCase();
      final cat = (m['category'] ?? m['subject'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) || cat.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: TrainXColors.primary))
        : RefreshIndicator(
            color: TrainXColors.primary,
            onRefresh: _loadMaterials,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search study materials & lecture notes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: TrainXColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrainXColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrainXColors.borderLight)),
                  ),
                ),
                const SizedBox(height: 14),

                if (_filteredMaterials.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No learning materials available at this time.',
                        style: TextStyle(color: TrainXColors.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  ..._filteredMaterials.map((m) {
                    final title = m['title'] ?? 'Course Resource';
                    final category = m['category'] ?? m['subject'] ?? 'General';
                    final type = m['file_type'] ?? m['type'] ?? 'PDF Document';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: TrainXColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF9333EA), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('$category  •  $type', style: const TextStyle(fontSize: 11.5, color: TrainXColors.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 18, color: TrainXColors.primary),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening resource: $title')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: TrainXColors.pageBg,
      appBar: AppBar(
        title: const Text('Learning Content', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: content,
    );
  }
}
