import 'item_model.dart';

/// A scored match candidate returned by `GET /items/:id/matches`. Wraps the
/// candidate item with why it matched and how confident the match is.
class MatchSuggestion {
  final ItemModel item;
  final int score;
  final String confidence; // 'high' | 'possible'
  final List<String> reasons;

  const MatchSuggestion({
    required this.item,
    required this.score,
    required this.confidence,
    required this.reasons,
  });

  bool get isHigh => confidence == 'high';

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) {
    final reasonsRaw = json['reasons'];
    return MatchSuggestion(
      item: ItemModel.fromJson(
        (json['item'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      score: (json['score'] as num?)?.toInt() ?? 0,
      confidence: json['confidence']?.toString() ?? 'possible',
      reasons: reasonsRaw is List
          ? reasonsRaw.map((r) => r.toString()).toList()
          : <String>[],
    );
  }
}
