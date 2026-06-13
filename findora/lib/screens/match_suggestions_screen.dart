import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../models/match_suggestion.dart';
import '../utils/app_snackbar.dart';
import 'claim_submission_screen.dart';
import 'item_detail_screen.dart';

/// Lists scored match candidates for one of the user's own posts. The call to
/// action adapts to that post's status:
///   - lost post  → candidates are FOUND items → "This is mine — Claim"
///   - found post → candidates are LOST reports → "Notify owner"
class MatchSuggestionsScreen extends StatefulWidget {
  final String itemId;

  const MatchSuggestionsScreen({super.key, required this.itemId});

  @override
  State<MatchSuggestionsScreen> createState() => _MatchSuggestionsScreenState();
}

class _MatchSuggestionsScreenState extends State<MatchSuggestionsScreen> {
  final _itemController = Get.find<ItemController>();

  bool _loading = true;
  ItemModel? _source;
  List<MatchSuggestion> _matches = const [];
  final _notifying = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _itemController.fetchMatches(widget.itemId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _source = result?.source;
      _matches = result?.matches ?? const [];
    });
  }

  bool get _sourceIsLost => _source?.status == ItemStatus.lost;

  Future<void> _notifyOwner(MatchSuggestion match) async {
    setState(() => _notifying.add(match.item.id));
    final ok = await _itemController.notifyMatch(
      itemId: widget.itemId,
      matchItemId: match.item.id,
    );
    if (!mounted) return;
    setState(() => _notifying.remove(match.item.id));
    if (ok) {
      AppSnackBar.success(context, 'The owner has been notified.');
    } else {
      AppSnackBar.error(context, 'Could not notify the owner. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0A3D62),
        title: const Text(
          'Possible Matches',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A3D62),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _matches.isEmpty ? _emptyState() : _list(),
            ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: _matches.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _header();
        return _matchCard(_matches[i - 1]);
      },
    );
  }

  Widget _header() {
    final title = _source?.title ?? 'your post';
    final subtitle = _sourceIsLost
        ? 'These found items may be yours. Confirm one to start a claim.'
        : 'People are looking for items like the one you found. Notify them.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matches for "$title"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No matches yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'We\'ll notify you the moment a matching item is posted.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _matchCard(MatchSuggestion match) {
    final item = match.item;
    final isLostCandidate = item.status == ItemStatus.lost;
    final statusColor =
        isLostCandidate ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
    final statusBg =
        isLostCandidate ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFF1F5F9),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFFCBD5E1),
                            ),
                          )
                        : const Icon(Icons.inventory_2_outlined,
                            color: Color(0xFFCBD5E1)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLostCandidate ? 'LOST' : 'FOUND',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.distanceKm != null
                                  ? '${item.location} · ${item.distanceKm!.toStringAsFixed(1)} km'
                                  : item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _confidenceBadge(match),
                    ],
                  ),
                ),
              ],
            ),
            if (match.reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.reasons.map(_reasonChip).toList(),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _primaryCta(match)),
                const SizedBox(width: 10),
                _detailsButton(item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(MatchSuggestion match) {
    final high = match.isHigh;
    final color = high ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final bg = high ? const Color(0xFFF0FDF4) : const Color(0xFFFEF9C3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(high ? Icons.verified_rounded : Icons.help_outline_rounded,
              size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '${high ? 'High match' : 'Possible'} · ${match.score}%',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _reasonChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: Color(0xFF2563EB)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta(MatchSuggestion match) {
    if (_sourceIsLost) {
      return SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClaimSubmissionScreen(item: match.item),
            ),
          ),
          icon: const Icon(Icons.verified_user_outlined, size: 17),
          label: const Text('This is mine'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    final busy = _notifying.contains(match.item.id);
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: busy ? null : () => _notifyOwner(match),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.notifications_active_outlined, size: 17),
        label: Text(busy ? 'Notifying…' : 'Notify owner'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _detailsButton(ItemModel item) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: const Text('Details'),
      ),
    );
  }
}
