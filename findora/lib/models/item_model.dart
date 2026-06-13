enum ItemStatus { lost, found }

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final ItemStatus status;
  final String location;
  final String postedBy;
  final String? postedById;
  final String timeAgo;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? color;
  final String date;
  final bool isResolved;
  final double? distanceKm;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.postedBy,
    this.postedById,
    required this.timeAgo,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.color,
    required this.date,
    this.isResolved = false,
    this.distanceKm,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      status: json['status'] == 'found' ? ItemStatus.found : ItemStatus.lost,
      location: json['location']?.toString() ?? '',
      postedBy: json['postedBy']?.toString() ?? 'Findora User',
      postedById: json['postedById']?.toString(),
      timeAgo: json['timeAgo']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      color: json['color']?.toString(),
      date: json['date']?.toString() ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  ItemModel copyWith({bool? isResolved}) {
    return ItemModel(
      id: id,
      title: title,
      description: description,
      category: category,
      status: status,
      location: location,
      postedBy: postedBy,
      postedById: postedById,
      timeAgo: timeAgo,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      color: color,
      date: date,
      isResolved: isResolved ?? this.isResolved,
      distanceKm: distanceKm,
    );
  }
}

// ── Dummy Data ──────────────────────────────────────────────
final List<ItemModel> dummyItems = [
  ItemModel(
    id: '1',
    title: 'Black iPhone 14 Pro',
    description:
        'Lost my black iPhone 14 Pro near the main gate. Has a clear case with a blue sticker on the back. Last seen around 3pm.',
    category: 'Electronics',
    status: ItemStatus.lost,
    location: 'IIU Main Gate, Islamabad',
    postedBy: 'Hajira G.',
    timeAgo: '2 hours ago',
    date: '2025-09-28',
    latitude: 33.7215,
    longitude: 73.0433,
    color: 'Black',
  ),
  ItemModel(
    id: '2',
    title: 'Student ID Card',
    description:
        'Found a student ID card near the library. Name on card: Ahmed Raza. Please contact admin to claim.',
    category: 'Documents',
    status: ItemStatus.found,
    location: 'IIU Library, Islamabad',
    postedBy: 'Areesha A.',
    timeAgo: '5 hours ago',
    date: '2025-09-28',
    latitude: 33.7220,
    longitude: 73.0440,
    color: 'White',
  ),
  ItemModel(
    id: '3',
    title: 'Blue Backpack',
    description:
        'Lost a navy blue backpack with laptop and books inside. Lost somewhere between cafeteria and Block C.',
    category: 'Bags & Wallets',
    status: ItemStatus.lost,
    location: 'IIU Cafeteria, Islamabad',
    postedBy: 'Sara K.',
    timeAgo: '1 day ago',
    date: '2025-09-27',
    latitude: 33.7210,
    longitude: 73.0428,
    color: 'Blue',
  ),
  ItemModel(
    id: '4',
    title: 'Car Keys - Honda',
    description:
        'Found a set of Honda car keys with a red keychain in the parking area near Block A.',
    category: 'Keys',
    status: ItemStatus.found,
    location: 'IIU Parking, Block A',
    postedBy: 'Omar F.',
    timeAgo: '3 hours ago',
    date: '2025-09-28',
    latitude: 33.7225,
    longitude: 73.0445,
    color: 'Silver',
  ),
  ItemModel(
    id: '5',
    title: 'Prescription Glasses',
    description:
        'Lost my reading glasses, black frame, inside a brown leather case. Lost in the exam hall.',
    category: 'Accessories',
    status: ItemStatus.lost,
    location: 'IIU Exam Hall, Islamabad',
    postedBy: 'Fatima N.',
    timeAgo: '6 hours ago',
    date: '2025-09-28',
    latitude: 33.7218,
    longitude: 73.0438,
    color: 'Black',
  ),
  ItemModel(
    id: '6',
    title: 'Calculus Textbook',
    description:
        'Found a Calculus textbook (Thomas, 14th edition) in the Math department corridor. Name written inside: Bilal.',
    category: 'Books',
    status: ItemStatus.found,
    location: 'Math Department, IIU',
    postedBy: 'Admin',
    timeAgo: '2 days ago',
    date: '2025-09-26',
    latitude: 33.7212,
    longitude: 73.0430,
    color: 'Yellow',
  ),
  ItemModel(
    id: '7',
    title: 'Brown Leather Wallet',
    description:
        'Lost my brown leather wallet containing cash and important cards near the sports complex.',
    category: 'Bags & Wallets',
    status: ItemStatus.lost,
    location: 'IIU Sports Complex',
    postedBy: 'Usman T.',
    timeAgo: '4 hours ago',
    date: '2025-09-28',
    latitude: 33.7208,
    longitude: 73.0425,
    color: 'Brown',
  ),
  ItemModel(
    id: '8',
    title: 'White Airpods Pro',
    description:
        'Found white Airpods Pro with charging case in the prayer area. In good condition.',
    category: 'Electronics',
    status: ItemStatus.found,
    location: 'IIU Prayer Area',
    postedBy: 'Zainab M.',
    timeAgo: '1 hour ago',
    date: '2025-09-28',
    latitude: 33.7222,
    longitude: 73.0442,
    color: 'White',
  ),
];
