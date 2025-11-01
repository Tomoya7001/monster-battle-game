class AppUser {
  final String id;
  final String displayName;
  final String? photoUrl;
  final int stone;      // 石
  final int coin;       // コイン
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  AppUser({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.stone = 1000,     // 初回ボーナス
    this.coin = 10000,     // 初回ボーナス
    required this.createdAt,
    required this.lastLoginAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'stone': stone,
    'coin': coin,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
  };
  
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    photoUrl: json['photoUrl'] as String?,
    stone: json['stone'] as int? ?? 0,
    coin: json['coin'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
  );
  
  AppUser copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
    int? stone,
    int? coin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      stone: stone ?? this.stone,
      coin: coin ?? this.coin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}