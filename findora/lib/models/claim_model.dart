enum ClaimStatus { pending, approved, rejected }

class ClaimModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemCategory;
  final String claimantId;
  final String? claimantName;
  final ClaimStatus status;
  final DateTime createdAt;
  final String? adminNote;
  final String? proofType;
  final List<ClaimAnswer> answers;

  ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemCategory,
    required this.claimantId,
    this.claimantName,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.proofType,
    required this.answers,
  });

  String get submittedAt => _timeAgo(createdAt);

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    final adminNote = json['adminNote']?.toString() ?? '';
    final proofType = json['proofType']?.toString() ?? '';
    return ClaimModel(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemTitle: json['itemTitle']?.toString() ?? 'Unknown item',
      itemCategory: json['itemCategory']?.toString() ?? '',
      claimantId: json['claimantId']?.toString() ?? '',
      claimantName: json['claimantName']?.toString(),
      status: _parseStatus(json['status']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      adminNote: adminNote.isNotEmpty ? adminNote : null,
      proofType: proofType.isNotEmpty ? proofType : null,
      answers: (json['answers'] as List?)
              ?.map((a) => ClaimAnswer(
                    question: a['question']?.toString() ?? '',
                    answer: a['answer']?.toString() ?? '',
                  ))
              .toList() ??
          [],
    );
  }

  static ClaimStatus _parseStatus(String s) {
    switch (s) {
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      default:
        return ClaimStatus.pending;
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inHours > 1) return '${diff.inHours} hours ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inMinutes > 1) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}

class ClaimAnswer {
  final String question;
  final String answer;

  const ClaimAnswer({required this.question, required this.answer});
}

// ── Dummy Claims (kept for reference / offline fallback) ──────
final List<ClaimModel> dummyClaims = [
  ClaimModel(
    id: 'c1dummy000000000000000001',
    itemId: '1',
    itemTitle: 'Black iPhone 14 Pro',
    itemCategory: 'Electronics',
    claimantId: 'user1dummy',
    claimantName: 'Ali Raza',
    status: ClaimStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    answers: [
      const ClaimAnswer(question: 'What color is the item?', answer: 'Black'),
      const ClaimAnswer(
        question: 'Any distinctive marks or features?',
        answer: 'Clear case with a blue sticker on the back',
      ),
      const ClaimAnswer(
        question: 'When and where did you lose it?',
        answer: 'Yesterday around 3pm near the main gate',
      ),
    ],
  ),
  ClaimModel(
    id: 'c2dummy000000000000000002',
    itemId: '3',
    itemTitle: 'Blue Backpack',
    itemCategory: 'Bags & Wallets',
    claimantId: 'user2dummy',
    claimantName: 'Areesha Abbasi',
    status: ClaimStatus.approved,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    adminNote:
        'Ownership verified. Please collect your item from the admin office (Block A, Room 101) between 9am–5pm with your student ID.',
    answers: [
      const ClaimAnswer(question: 'What color is the item?', answer: 'Navy blue'),
      const ClaimAnswer(
        question: 'Any distinctive marks or features?',
        answer: 'Has a white keychain and a torn zipper on the side',
      ),
      const ClaimAnswer(
        question: 'What was inside the bag?',
        answer: 'Laptop, 3 notebooks, calculator, and water bottle',
      ),
    ],
  ),
  ClaimModel(
    id: 'c3dummy000000000000000003',
    itemId: '5',
    itemTitle: 'Prescription Glasses',
    itemCategory: 'Accessories',
    claimantId: 'user3dummy',
    claimantName: 'Sara Khan',
    status: ClaimStatus.rejected,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    adminNote:
        'Claim rejected. The description provided did not match the item details.',
    answers: [
      const ClaimAnswer(question: 'What color is the item?', answer: 'Brown frame'),
      const ClaimAnswer(
        question: 'Any distinctive marks or features?',
        answer: 'No case, just glasses',
      ),
    ],
  ),
];

// ── Dummy BLE Tags ────────────────────────────────────────────
enum BleProximity { near, medium, far, outOfRange }

class BleTag {
  final String id;
  final String tagId;
  final String itemName;
  final String itemCategory;
  final bool isActive;
  final BleProximity proximity;
  final String lastSeen;
  final String lastLocation;
  final int signalStrength; // RSSI simulated -40 to -100

  const BleTag({
    required this.id,
    required this.tagId,
    required this.itemName,
    required this.itemCategory,
    required this.isActive,
    required this.proximity,
    required this.lastSeen,
    required this.lastLocation,
    required this.signalStrength,
  });
}

final List<BleTag> dummyBleTags = [
  const BleTag(
    id: 'b1',
    tagId: 'FND-A1B2C3',
    itemName: 'Black Backpack',
    itemCategory: 'Bags & Wallets',
    isActive: true,
    proximity: BleProximity.near,
    lastSeen: '2 minutes ago',
    lastLocation: 'IIU Library, Block B',
    signalStrength: -45,
  ),
  const BleTag(
    id: 'b2',
    tagId: 'FND-D4E5F6',
    itemName: 'Car Keys',
    itemCategory: 'Keys',
    isActive: true,
    proximity: BleProximity.medium,
    lastSeen: '15 minutes ago',
    lastLocation: 'IIU Parking Lot A',
    signalStrength: -68,
  ),
  const BleTag(
    id: 'b3',
    tagId: 'FND-G7H8I9',
    itemName: 'Laptop Bag',
    itemCategory: 'Bags & Wallets',
    isActive: false,
    proximity: BleProximity.outOfRange,
    lastSeen: '3 hours ago',
    lastLocation: 'IIU Cafeteria',
    signalStrength: -100,
  ),
];
