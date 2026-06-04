// ============================================================
// lib/models/user_model.dart
// ============================================================

// ────────────────────────────────────────────────────────────
// USER MODEL
// ────────────────────────────────────────────────────────────

import 'package:club_india_user/services/api_service.dart';

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

  // 🔥 Bank details
  final String? bankHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;

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
    this.bankHolderName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
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
      bankHolderName: json['bank_holder_name'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      upiId: json['upi_id'],
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
    'bank_holder_name': bankHolderName,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc_code': ifscCode,
    'upi_id': upiId,
  };

  // ── Helpers ───────────────────────────────────────────────
  bool get isActive => status == 'active';
  bool get hasBankDetails => accountNumber != null && accountNumber!.isNotEmpty;
  bool get hasUpi => upiId != null && upiId!.isNotEmpty;
  String get displayName => name ?? phone;
  String get displayBalance => '₹${walletBalance.toStringAsFixed(2)}';
}

// ────────────────────────────────────────────────────────────
// LOCATION MODEL
// ────────────────────────────────────────────────────────────

class LocationModel {
  final int? id;
  final double? latitude;
  final double? longitude;

  LocationModel({this.id, this.latitude, this.longitude});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;
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
  final LocationModel? location;
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
    this.location,
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
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  bool get isApproved => status == 'approved';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get hasLocation => location?.hasCoordinates ?? false;
  String get fullAddress => [
    address,
    city,
    district,
    state,
  ].where((e) => e != null && e.isNotEmpty).join(', ');
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

  // ── Helpers ───────────────────────────────────────────────
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isPopup => offerType == 'popup';
  bool get isNormal => offerType == 'normal';
}

// ────────────────────────────────────────────────────────────
// TRANSACTION MODEL
// ────────────────────────────────────────────────────────────

class TransactionModel {
  final int id;
  final int userId;
  final int? storeId;
  final double? purchaseAmount;
  final double? rewardPoints;
  final double? rewardPercentage;

  // 🔥 FIX: Backend may use 'earned' | 'redeemed' | 'withdrawn'
  final String transactionType;

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

  // ── Helpers ───────────────────────────────────────────────
  bool get isEarned => transactionType == 'earned';
  bool get isRedeemed => transactionType == 'redeemed';
  bool get isWithdrawn => transactionType == 'withdrawn';
  bool get isDebit => isRedeemed || isWithdrawn;

  String get displayPoints =>
      rewardPoints != null ? '${rewardPoints!.toStringAsFixed(0)} pts' : '—';
  String get displayPurchase =>
      purchaseAmount != null ? '₹${purchaseAmount!.toStringAsFixed(2)}' : '—';
  String get displayRupeeValue => rewardPoints != null
      ? '₹${(rewardPoints! * 0.10).toStringAsFixed(2)}'
      : '—';
}

// ────────────────────────────────────────────────────────────
// SPECIAL AD MODEL  (Home Page Banner)
// ────────────────────────────────────────────────────────────

class SpecialAdModel {
  final bool active;
  final String? image;
  final String? title;
  final String? description;
  final String? actionUrl;

  SpecialAdModel({
    required this.active,
    this.image,
    this.title,
    this.description,
    this.actionUrl,
  });

  factory SpecialAdModel.fromJson(Map<String, dynamic> json) {
    return SpecialAdModel(
      active: json['active'] ?? false,
      image: json['image'],
      title: json['title'],
      description: json['description'],
      actionUrl: json['action_url'],
    );
  }

  /// Show only when active AND image exists
  bool get shouldShow => active && image != null && image!.isNotEmpty;
}

// ────────────────────────────────────────────────────────────
// POPUP AD MODEL
// ────────────────────────────────────────────────────────────

class PopupAdModel {
  final bool active;
  final String? image;
  final String? actionUrl;

  PopupAdModel({required this.active, this.image, this.actionUrl});

  factory PopupAdModel.fromJson(Map<String, dynamic> json) {
    return PopupAdModel(
      active: json['active'] ?? false,
      image: json['image'],
      actionUrl: json['action_url'],
    );
  }

  bool get shouldShow => active && image != null && image!.isNotEmpty;
}

// ────────────────────────────────────────────────────────────
// HOME RESPONSE MODEL
// ────────────────────────────────────────────────────────────

class HomeResponseModel {
  final UserModel user;
  final List<PartnerStoreModel> nearbyStores;
  final List<OfferModel> offers;
  final SpecialAdModel? specialAd;
  final PopupAdModel? popupAd;

  HomeResponseModel({
    required this.user,
    required this.nearbyStores,
    required this.offers,
    this.specialAd,
    this.popupAd,
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

      specialAd: json['special_ad'] is Map<String, dynamic>
          ? SpecialAdModel.fromJson(json['special_ad'] as Map<String, dynamic>)
          : null,

      // 🔥 Backend popups array support
      popupAd: json['popups'] is List && (json['popups'] as List).isNotEmpty
          ? PopupAdModel(
              active:
                  json['popups'][0]['is_active'] == true ||
                  json['popups'][0]['is_active'] == 1,
              image:
                  '${UserApiService.imageBaseUrl}/uploads/${json['popups'][0]['banner']}',
              actionUrl: json['popups'][0]['action_url'],
            )
          : null,
    );
  }
}
