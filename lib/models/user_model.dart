// ============================================================
// lib/models/models.dart
// ============================================================
// Single file — all models export ചെയ്യാം or split ചെയ്യാം
// ============================================================

// ────────────────────────────────────────────────────────────
// USER MODEL
// ────────────────────────────────────────────────────────────

class UserModel {
  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? state;
  final String? district;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double walletBalance;
  final double totalEarned;
  final double totalRedeemed;
  final String? qrCode;
  final String status;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.state,
    this.district,
    this.city,
    this.latitude,
    this.longitude,
    required this.walletBalance,
    required this.totalEarned,
    required this.totalRedeemed,
    this.qrCode,
    required this.status,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      state: json['state'],
      district: json['district'],
      city: json['city'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      walletBalance: double.tryParse(json['wallet_balance'].toString()) ?? 0.0,
      totalEarned: double.tryParse(json['total_earned'].toString()) ?? 0.0,
      totalRedeemed: double.tryParse(json['total_redeemed'].toString()) ?? 0.0,
      qrCode: json['qr_code'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'state': state,
    'district': district,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'wallet_balance': walletBalance,
    'total_earned': totalEarned,
    'total_redeemed': totalRedeemed,
    'qr_code': qrCode,
    'status': status,
  };
}

// ────────────────────────────────────────────────────────────
// PARTNER STORE MODEL
// ────────────────────────────────────────────────────────────

class PartnerStoreModel {
  final int id;
  final String storeName;
  final String ownerName;
  final String phone;
  final String? email;
  final int categoryId;
  final String? address;
  final String state;
  final String district;
  final String city;
  final String? shopImage;
  final String status;
  final String subscriptionStatus;
  final double walletBalance;
  final DateTime? createdAt;

  PartnerStoreModel({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.phone,
    this.email,
    required this.categoryId,
    this.address,
    required this.state,
    required this.district,
    required this.city,
    this.shopImage,
    required this.status,
    required this.subscriptionStatus,
    required this.walletBalance,
    this.createdAt,
  });

  factory PartnerStoreModel.fromJson(Map<String, dynamic> json) {
    return PartnerStoreModel(
      id: json['id'],
      storeName: json['store_name'],
      ownerName: json['owner_name'],
      phone: json['phone'],
      email: json['email'],
      categoryId: json['category_id'],
      address: json['address'],
      state: json['state'],
      district: json['district'],
      city: json['city'],
      shopImage: json['shop_image'],
      status: json['status'] ?? 'pending',
      subscriptionStatus: json['subscription_status'] ?? 'inactive',
      walletBalance: double.tryParse(json['wallet_balance'].toString()) ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

// ────────────────────────────────────────────────────────────
// OFFER MODEL
// ────────────────────────────────────────────────────────────

class OfferModel {
  final int id;
  final int storeId;
  final String title;
  final String? description;
  final String? banner;
  final String offerType; // "normal" | "popup"
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime? createdAt;

  OfferModel({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    this.banner,
    required this.offerType,
    this.expiryDate,
    required this.isActive,
    this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      storeId: json['store_id'],
      title: json['title'],
      description: json['description'],
      banner: json['banner'],
      offerType: json['offer_type'] ?? 'normal',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

// ────────────────────────────────────────────────────────────
// TRANSACTION MODEL
// ────────────────────────────────────────────────────────────

class TransactionModel {
  final int id;
  final int userId;
  final int? storeId; // null for redemption transactions
  final double? purchaseAmount;
  final double? rewardPoints;
  final double? rewardPercentage;
  final String transactionType; // "earned" | "redeemed"
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.storeId,
    this.purchaseAmount,
    this.rewardPoints,
    this.rewardPercentage,
    required this.transactionType,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      storeId: json['store_id'],
      purchaseAmount: json['purchase_amount'] != null
          ? double.tryParse(json['purchase_amount'].toString())
          : null,
      rewardPoints: json['reward_points'] != null
          ? double.tryParse(json['reward_points'].toString())
          : null,
      rewardPercentage: json['reward_percentage'] != null
          ? double.tryParse(json['reward_percentage'].toString())
          : null,
      transactionType: json['transaction_type'] ?? 'earned',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  // Helper — UI-ൽ display ചെയ്യാൻ
  bool get isEarned => transactionType == 'earned';
  bool get isRedeemed => transactionType == 'redeemed';
}

// ────────────────────────────────────────────────────────────
// HOME RESPONSE MODEL
// (GET /api/user/home response wrapper)
// ────────────────────────────────────────────────────────────

class HomeResponseModel {
  final UserModel user;
  final List<PartnerStoreModel> nearbyStores;
  final List<OfferModel> offers;

  HomeResponseModel({
    required this.user,
    required this.nearbyStores,
    required this.offers,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) {
    return HomeResponseModel(
      user: UserModel.fromJson(json['user']),
      nearbyStores: (json['nearby_stores'] as List)
          .map((s) => PartnerStoreModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      offers: (json['offers'] as List)
          .map((o) => OfferModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
