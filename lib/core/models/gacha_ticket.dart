class GachaTicket {
  final String userId;
  final int ticketCount;
  final int totalPulls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GachaTicket({
    required this.userId,
    this.ticketCount = 0,
    this.totalPulls = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory GachaTicket.fromJson(Map<String, dynamic> json) {
    return GachaTicket(
      userId: json['userId'] as String? ?? '',
      ticketCount: json['ticketCount'] as int? ?? 0,
      totalPulls: json['totalPulls'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ticketCount': ticketCount,
      'totalPulls': totalPulls,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class TicketExchangeOption {
  final String id;
  final String name;
  final int requiredTickets;
  final String rewardType;
  final String? specificMonsterId;
  final int guaranteeRate;
  final String? description;

  const TicketExchangeOption({
    required this.id,
    required this.name,
    required this.requiredTickets,
    required this.rewardType,
    this.specificMonsterId,
    this.guaranteeRate = 97,
    this.description,
  });

  factory TicketExchangeOption.fromJson(Map<String, dynamic> json) {
    return TicketExchangeOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      requiredTickets: json['requiredTickets'] as int? ?? 0,
      rewardType: json['rewardType'] as String? ?? '',
      specificMonsterId: json['specificMonsterId'] as String?,
      guaranteeRate: json['guaranteeRate'] as int? ?? 97,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredTickets': requiredTickets,
      'rewardType': rewardType,
      'specificMonsterId': specificMonsterId,
      'guaranteeRate': guaranteeRate,
      'description': description,
    };
  }
}