import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../models/item_model.dart';
import 'post_review_screen.dart';

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  late final AdminController _ctrl;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminController>();
    _ctrl.fetchAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff17324D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Posts',
          style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: ['All', 'Lost', 'Found']
                  .map(_filterChip)
                  .toList(),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_ctrl.itemsLoading.value && _ctrl.allItems.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _selectedFilter == 'All'
                  ? _ctrl.allItems.toList()
                  : _ctrl.allItems
                      .where((i) => i.status.name.toLowerCase() == _selectedFilter.toLowerCase())
                      .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No posts found', style: TextStyle(fontSize: 16, color: Colors.black54)),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _ctrl.fetchAllItems(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _postCard(context, filtered[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text) {
    final selected = _selectedFilter == text;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = text),
        child: Chip(
          label: Text(text),
          backgroundColor: selected ? const Color(0xff0A84FF) : Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _postCard(BuildContext context, ItemModel item) {
    final isLost = item.status == ItemStatus.lost;
    final color = isLost ? Colors.orange : Colors.green;
    final statusLabel = isLost ? 'Lost' : 'Found';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xffF3FAFF)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xffDCEFFF),
                child: Icon(Icons.inventory_2_rounded, color: Color(0xff0A5EB0)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xff17324D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.location} • by ${item.postedBy}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xff0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => PostReviewScreen(item: item)),
                    );
                    if (deleted == true) _ctrl.fetchAllItems();
                  },
                  child: const Text('Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _confirmDelete(context, item),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await _ctrl.deleteItem(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Post deleted' : 'Failed to delete post')),
    );
  }
}
