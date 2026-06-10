import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/claim_controller.dart';
import '../models/claim_model.dart';

class ClaimReviewScreen extends StatefulWidget {
  final ClaimModel claim;

  const ClaimReviewScreen({super.key, required this.claim});

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _approve() async {
    final note = await _showNoteDialog('Approve Claim', 'Approval message (optional)');
    if (note == null) return;

    setState(() => _isApproving = true);
    final ok = await Get.find<ClaimController>().approveClaim(
      widget.claim.id,
      adminNote: note.isNotEmpty ? note : null,
    );
    if (!mounted) return;
    setState(() => _isApproving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim Approved')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve claim')),
      );
    }
  }

  Future<void> _reject() async {
    final note = await _showNoteDialog('Reject Claim', 'Rejection reason (optional)');
    if (note == null) return;

    setState(() => _isRejecting = true);
    final ok = await Get.find<ClaimController>().rejectClaim(
      widget.claim.id,
      adminNote: note.isNotEmpty ? note : null,
    );
    if (!mounted) return;
    setState(() => _isRejecting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim Rejected')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject claim')),
      );
    }
  }

  Future<String?> _showNoteDialog(String title, String hint) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final statement = claim.answers.isNotEmpty
        ? claim.answers.map((a) => '${a.question}\n${a.answer}').join('\n\n')
        : 'No statement provided.';
    final shortId = '#CLM-${claim.id.substring(0, 6).toUpperCase()}';

    return Scaffold(
      backgroundColor: const Color(0xffF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff17324D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Claim Review',
          style: TextStyle(
            color: Color(0xff17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Claim Item Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xffF3FAFF)],
                ),
                borderRadius: BorderRadius.circular(24),
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
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xffDCEFFF),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xff0A5EB0),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.itemTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Color(0xff17324D),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$shortId • ${claim.claimantName ?? claim.claimantId}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ownership Proof placeholder
            const Text(
              'Ownership Proof',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff17324D),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xffEAF5FF),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 50, color: Color(0xff0A5EB0)),
                  const SizedBox(height: 8),
                  Text(
                    claim.proofType ?? 'No proof type specified',
                    style: const TextStyle(
                      color: Color(0xff0A5EB0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Statement
            const Text(
              'User Statement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff17324D),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statement,
                style: const TextStyle(height: 1.6, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 30),

            // Approve / Reject
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isApproving || _isRejecting ? null : _approve,
                    child: _isApproving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isApproving || _isRejecting ? null : _reject,
                    child: _isRejecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Reject'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Unlock Chat (placeholder — requires chat backend)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0A84FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat Unlocked between users'),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Unlock Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
