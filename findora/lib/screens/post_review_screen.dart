import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_controller.dart';
import '../models/item_model.dart';

class PostReviewScreen extends StatefulWidget {
  final ItemModel item;

  const PostReviewScreen({super.key, required this.item});

  @override
  State<PostReviewScreen> createState() => _PostReviewScreenState();
}

class _PostReviewScreenState extends State<PostReviewScreen> {
  bool _isDeleting = false;

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Delete "${widget.item.title}"? This cannot be undone.'),
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

    setState(() => _isDeleting = true);
    final ok = await Get.find<AdminController>().deleteItem(widget.item.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLost = item.status == ItemStatus.lost;

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
          'Post Review',
          style: TextStyle(color: Color(0xff17324D), fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xffEAF5FF),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 60, color: Color(0xff0A5EB0)))
                  : const Icon(Icons.image, size: 60, color: Color(0xff0A5EB0)),
            ),

            const SizedBox(height: 20),

            Text(
              item.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xff17324D)),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.location} • Posted by ${item.postedBy}',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(.08), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Text(
                item.description.isNotEmpty ? item.description : 'No description provided.',
                style: const TextStyle(height: 1.6, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 20),

            _infoRow('Category', item.category),
            _infoRow('Date Posted', item.date),
            _infoRow('Status', isLost ? 'Lost' : 'Found'),
            if (item.color != null && item.color!.isNotEmpty)
              _infoRow('Color', item.color!),
            _infoRow('Resolved', item.isResolved ? 'Yes' : 'No'),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post looks good — no action needed')),
                      );
                      Navigator.pop(context, false);
                    },
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _isDeleting ? null : _deletePost,
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff17324D))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}
