import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import 'item_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late final ItemController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ItemController>();
    _ctrl.fetchMyItems();
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Documents':
        return Icons.description_outlined;
      case 'Keys':
        return Icons.key_rounded;
      case 'Bags & Wallets':
      case 'Bags':
        return Icons.shopping_bag_outlined;
      case 'Clothing':
        return Icons.checkroom_outlined;
      case 'Accessories':
        return Icons.watch_outlined;
      case 'Books':
        return Icons.menu_book_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await _ctrl.deleteMyItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Post deleted' : 'Failed to delete post'),
            backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xffF5FAFF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'My Posts',
            style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: Color(0xff17324D)),
        ),
        body: SafeArea(
          child: Obx(() {
            if (_ctrl.myItemsLoading.value && _ctrl.myItems.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_ctrl.myItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your lost & found posts will appear here',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _ctrl.fetchMyItems,
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _ctrl.myItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (ctx, i) => _PostCard(
                  item: _ctrl.myItems[i],
                  icon: _iconForCategory(_ctrl.myItems[i].category),
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: _ctrl.myItems[i]),
                    ),
                  ),
                  onDelete: () => _confirmDelete(ctx, _ctrl.myItems[i]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ItemModel item;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.item,
    required this.icon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = item.status == ItemStatus.lost;
    final statusLabel = item.isResolved ? 'Resolved' : (isLost ? 'Lost' : 'Found');
    final statusColor = item.isResolved
        ? Colors.blue
        : (isLost ? Colors.red : Colors.green);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.white, Color(0xffF2F9FF)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: statusColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xff17324D)),
                  ),
                  const SizedBox(height: 6),
                  Text(item.location, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
