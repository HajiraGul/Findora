enum ClaimStatus { pending, approved, rejected }

class ClaimModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemCategory;
  final ClaimStatus status;
  final String submittedAt;
  final String? adminNote;
  final List<ClaimAnswer> answers;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemCategory,
    required this.status,
    required this.submittedAt,
    this.adminNote,
    required this.answers,
  });
}

class ClaimAnswer {
  final String question;
  final String answer;

  const ClaimAnswer({required this.question, required this.answer});
}

// ── Dummy Claims ─────────────────────────────────────────────
final List<ClaimModel> dummyClaims = [
  ClaimModel(
    id: 'c1',
    itemId: '1',
    itemTitle: 'Black iPhone 14 Pro',
    itemCategory: 'Electronics',
    status: ClaimStatus.pending,
    submittedAt: '2 hours ago',
    answers: [
      ClaimAnswer(question: 'What color is the item?', answer: 'Black'),
      ClaimAnswer(
        question: 'Any distinctive marks or features?',
        answer: 'Clear case with a blue sticker on the back',
      ),
      ClaimAnswer(
        question: 'When and where did you lose it?',
        answer: 'Yesterday around 3pm near the main gate',
      ),
    ],
  ),
  ClaimModel(
    id: 'c2',
    itemId: '3',
    itemTitle: 'Blue Backpack',
    itemCategory: 'Bags & Wallets',
    status: ClaimStatus.approved,
    submittedAt: '1 day ago',
    adminNote:
        'Ownership verified. Please collect your item from the admin office (Block A, Room 101) between 9am–5pm with your student ID.',
    answers: [
      ClaimAnswer(question: 'What color is the item?', answer: 'Navy blue'),
      ClaimAnswer(
        question: 'Any distinctive marks or features?',
        answer: 'Has a white keychain and a torn zipper on the side',
      ),
      ClaimAnswer(
        question: 'What was inside the bag?',
        answer: 'Laptop, 3 notebooks, calculator, and water bottle',
      ),
    ],
  ),
  ClaimModel(
    id: 'c3',
    itemId: '5',
    itemTitle: 'Prescription Glasses',
    itemCategory: 'Accessories',
    status: ClaimStatus.rejected,
    submittedAt: '3 days ago',
    adminNote:
        'Claim rejected. The description provided did not match the item details. You may submit a new claim with more accurate information.',
    answers: [
      ClaimAnswer(question: 'What color is the item?', answer: 'Brown frame'),
      ClaimAnswer(
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
  BleTag(
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
  BleTag(
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
  BleTag(
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
