import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';
import '../models/match_suggestion.dart';
import 'match_suggestions_screen.dart';

/// One ranked candidate paired with the user's own post it matched against.
typedef _Best = ({ItemModel source, MatchSuggestion match});

/// Aggregates the highest-scoring match candidates across all of the user's
/// open posts into a single ranked list. Tapping a card jumps to that post's
/// full match view where the claim / notify actions live.
class BestMatchesScreen extends StatefulWidget {
  const BestMatchesScreen({super.key});

  @override
  State<BestMatchesScreen> createState() => _BestMatchesScreenState();
}

class _BestMatchesScreenState extends State<BestMatchesScreen> {
  final _ctrl = Get.find<ItemController>();

  bool _loading = true;
  List<_Best> _best = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _ctrl.fetchMyItems();

    // Collect candidates from every open post, keeping only the strongest score
    // per candidate item so the same find isn't listed twice.
    final byCandidate = <String, _Best>{};
    for (final source in _ctrl.myItems.where((i) => !i.isResolved)) {
      final result = await _ctrl.fetchMatches(source.id);
      if (result == null) continue;
      for (final match in result.matches) {
        final existing = byCandidate[match.item.id];
        if (existing == null || match.score > existing.match.score) {
          byCandidate[match.item.id] = (source: result.source, match: match);
        }
      }
    }

    final best = byCandidate.values.toList()
      ..sort((a, b) => b.match.score.compareTo(a.match.score));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _best = best;
    });
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
          'Best Matches',
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
              child: _best.isEmpty ? _emptyState() : _list(),
            ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: _best.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _intro();
        return _matchCard(_best[i - 1]);
      },
    );
  }

  Widget _intro() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your strongest matches',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Items most likely to match the posts you have open. Tap one to claim or notify the owner.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey.shade300),
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
            'Post a lost or found item and we\'ll surface the best matches here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _matchCard(_Best best) {
    final item = best.match.item;
    final isLost = item.status == ItemStatus.lost;
    final statusColor =
        isLost ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
    final statusBg =
        isLost ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchSuggestionsScreen(itemId: best.source.id),
        ),
      ),
      child: Container(
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
                          : const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFFCBD5E1),
                            ),
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
                                isLost ? 'LOST' : 'FOUND',
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
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _confidenceBadge(best.match),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        size: 15, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Matches your post: ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          children: [
                            TextSpan(
                              text: best.source.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ],
          ),
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
}
