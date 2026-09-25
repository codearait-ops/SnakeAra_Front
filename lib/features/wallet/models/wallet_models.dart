import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Information about rewarded ad limits and cooldowns for direct coin claims.
class AdRewardInfoModel {
  final int rewardAmount; // e.g. 15
  final int maxDailyViews; // e.g. 4
  final int viewsToday; // int
  final bool canWatchNow; // bool
  final int secondsUntilNextView; // int

  AdRewardInfoModel({
    this.rewardAmount = 15,
    this.maxDailyViews = 4,
    this.viewsToday = 0,
    this.canWatchNow = true,
    this.secondsUntilNextView = 0,
  });

  factory AdRewardInfoModel.fromJson(Map<String, dynamic> json) {
    final rawReward = json['reward_amount'] ?? json['rewardAmount'] ?? 15;
    final rewardAmount = rawReward is num
        ? rawReward.toInt()
        : (int.tryParse(rawReward.toString()) ?? 15);

    final rawMax = json['max_daily_views'] ?? json['maxDailyViews'] ?? 4;
    final maxDailyViews = rawMax is num
        ? rawMax.toInt()
        : (int.tryParse(rawMax.toString()) ?? 4);

    final rawViews = json['views_today'] ?? json['viewsToday'] ?? 0;
    final viewsToday = rawViews is num
        ? rawViews.toInt()
        : (int.tryParse(rawViews.toString()) ?? 0);

    final canWatchNow = json['can_watch_now'] == true ||
        json['canWatchNow'] == true ||
        (json['can_watch_now'] == null && viewsToday < maxDailyViews && (json['seconds_until_next_view'] ?? 0) <= 0);

    final rawSeconds = json['seconds_until_next_view'] ??
        json['secondsUntilNextView'] ??
        0;
    final secondsUntilNextView = rawSeconds is num
        ? rawSeconds.toInt()
        : (int.tryParse(rawSeconds.toString()) ?? 0);

    return AdRewardInfoModel(
      rewardAmount: rewardAmount,
      maxDailyViews: maxDailyViews,
      viewsToday: viewsToday,
      canWatchNow: canWatchNow,
      secondsUntilNextView: secondsUntilNextView,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reward_amount': rewardAmount,
      'max_daily_views': maxDailyViews,
      'views_today': viewsToday,
      'can_watch_now': canWatchNow,
      'seconds_until_next_view': secondsUntilNextView,
    };
  }

  AdRewardInfoModel copyWith({
    int? rewardAmount,
    int? maxDailyViews,
    int? viewsToday,
    bool? canWatchNow,
    int? secondsUntilNextView,
  }) {
    return AdRewardInfoModel(
      rewardAmount: rewardAmount ?? this.rewardAmount,
      maxDailyViews: maxDailyViews ?? this.maxDailyViews,
      viewsToday: viewsToday ?? this.viewsToday,
      canWatchNow: canWatchNow ?? this.canWatchNow,
      secondsUntilNextView: secondsUntilNextView ?? this.secondsUntilNextView,
    );
  }
}

/// Comprehensive wallet data returned from GET /api/wallet
class WalletData {
  final int balance;
  final AdRewardInfoModel adReward;
  final List<CoinTransactionModel> recentTransactions;

  WalletData({
    required this.balance,
    required this.adReward,
    this.recentTransactions = const [],
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'] ?? json['coins'] ?? json['data']?['balance'] ?? 0;
    final balance = rawBalance is num
        ? rawBalance.toInt()
        : (int.tryParse(rawBalance.toString()) ?? 0);

    final adJson = json['ad_reward'] ??
        json['adReward'] ??
        json['ad_reward_info'] ??
        json['adRewardInfo'] ??
        json['ad'] ??
        json;

    final rawRecent = json['recent_transactions'] ??
        json['recentTransactions'] ??
        json['transactions'] ??
        json['data']?['recent_transactions'] ??
        json['data']?['transactions'];

    final List<CoinTransactionModel> recentTransactions = [];
    if (rawRecent is List) {
      for (final item in rawRecent) {
        if (item is Map) {
          recentTransactions.add(
            CoinTransactionModel.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return WalletData(
      balance: balance,
      adReward: adJson is Map<String, dynamic>
          ? AdRewardInfoModel.fromJson(adJson)
          : (adJson is Map ? AdRewardInfoModel.fromJson(Map<String, dynamic>.from(adJson)) : AdRewardInfoModel()),
      recentTransactions: recentTransactions,
    );
  }
}

/// Response model for POST /wallet/claim-welcome-bonus
class WelcomeBonusResponse {
  final int coinsAwarded;
  final int? balance;
  final String? message;
  final bool isSuccess;

  WelcomeBonusResponse({
    required this.coinsAwarded,
    this.balance,
    this.message,
    this.isSuccess = true,
  });

  factory WelcomeBonusResponse.fromJson(Map<String, dynamic> json) {
    final rawCoins = json['coins_awarded'] ??
        json['coinsAwarded'] ??
        json['coins'] ??
        json['reward'] ??
        json['amount'] ??
        json['data']?['coins_awarded'] ??
        json['data']?['amount'];
    int coinsAwarded = 0;
    if (rawCoins is num) {
      coinsAwarded = rawCoins.toInt();
    } else if (rawCoins is Map) {
      final t = rawCoins['total'] ?? rawCoins['amount'] ?? rawCoins['coins'];
      if (t is num) {
        coinsAwarded = t.toInt();
      } else if (t != null) {
        coinsAwarded = int.tryParse(t.toString()) ?? 0;
      }
    } else if (rawCoins != null) {
      coinsAwarded = int.tryParse(rawCoins.toString()) ?? 0;
    }

    final rawBalance = json['balance'] ?? json['data']?['balance'];
    final balance = rawBalance is num
        ? rawBalance.toInt()
        : (rawBalance != null ? int.tryParse(rawBalance.toString()) : null);

    return WelcomeBonusResponse(
      coinsAwarded: coinsAwarded,
      balance: balance,
      message: json['message']?.toString(),
      isSuccess: json['success'] != false && (coinsAwarded > 0 || balance != null),
    );
  }
}

/// Models for Coin Wallet transactions and store items.
class CoinTransactionModel {
  final int id;
  final int amount; // positive for earn, negative for spend
  final String type; // 'welcome_bonus', 'daily_mission', 'league_entry', 'skin_purchase', 'league_reward'
  final String title;
  final String? description;
  final DateTime createdAt;

  CoinTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  /// Localized category / reason label based on transaction type
  String get typeLabel {
    final t = type.toLowerCase();
    if (t.contains('welcome')) return 'tx_type_welcome_bonus'.tr;
    if (t.contains('mission')) return 'tx_type_daily_mission'.tr;
    if (t.contains('ad')) return 'tx_type_ad_reward'.tr;
    if (t.contains('league') && (t.contains('entry') || !isCredit)) {
      return 'tx_type_league_entry'.tr;
    }
    if (t.contains('league') || t.contains('prize')) {
      return 'tx_type_league_reward'.tr;
    }
    if (t.contains('skin') || t.contains('shop') || t.contains('purchase')) {
      return 'tx_type_skin_purchase'.tr;
    }
    if (t.contains('streak') || t.contains('daily')) {
      return 'tx_type_daily_streak'.tr;
    }
    if (t.contains('game') || t.contains('win') || t.contains('level')) {
      return 'tx_type_game_reward'.tr;
    }
    if (t.contains('referral') || t.contains('invite')) {
      return 'tx_type_referral'.tr;
    }
    return isCredit ? 'tx_type_earn'.tr : 'tx_type_spend'.tr;
  }

  /// User-facing display title: if title is generic, falls back to localized typeLabel
  String get displayTitle {
    if (title.isNotEmpty &&
        title != 'coin_transaction_fallback'.tr &&
        title != 'Coin Transaction' &&
        title != 'تراکنش سکه') {
      return title;
    }
    return typeLabel;
  }

  /// Context-specific icon for this transaction reason
  IconData get typeIcon {
    final t = type.toLowerCase();
    if (t.contains('welcome')) return Icons.card_giftcard_rounded;
    if (t.contains('mission')) return Icons.task_alt_rounded;
    if (t.contains('ad')) return Icons.play_circle_outline_rounded;
    if (t.contains('league') && (t.contains('entry') || !isCredit)) {
      return Icons.emoji_events_outlined;
    }
    if (t.contains('league') || t.contains('prize')) {
      return Icons.emoji_events_rounded;
    }
    if (t.contains('skin') || t.contains('shop') || t.contains('purchase')) {
      return Icons.shopping_bag_outlined;
    }
    if (t.contains('streak') || t.contains('daily')) {
      return Icons.calendar_today_rounded;
    }
    if (t.contains('game') || t.contains('win') || t.contains('level')) {
      return Icons.sports_esports_rounded;
    }
    return isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : (int.tryParse(rawId?.toString() ?? '1') ?? 1);

    final rawAmount = json['amount'] ?? 0;
    final amount = rawAmount is num
        ? rawAmount.toInt()
        : (int.tryParse(rawAmount.toString()) ?? 0);

    final type = json['type']?.toString() ??
        json['category']?.toString() ??
        json['source']?.toString() ??
        json['action']?.toString() ??
        'general';

    final rawDesc = json['description'] ??
        json['reason'] ??
        json['desc'] ??
        json['details'] ??
        json['memo'] ??
        json['comment'];
    final description = rawDesc?.toString();

    final rawTitle = json['title'] ?? json['name'] ?? json['label'];
    final title = rawTitle?.toString() ??
        description ??
        'coin_transaction_fallback'.tr;

    return CoinTransactionModel(
      id: id,
      amount: amount,
      type: type,
      title: title,
      description: description,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Item available in the Skin / Cosmetics Shop
class ShopItemModel {
  final String id;
  final String nameFa;
  final String nameEn;
  final String descriptionFa;
  final String descriptionEn;
  final String category; // 'snake_skin', 'board_theme', 'avatar_frame'
  final int priceCoins;
  final String? previewAsset;
  final bool isOwned;
  final bool isEquipped;

  ShopItemModel({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.descriptionFa,
    required this.descriptionEn,
    required this.category,
    required this.priceCoins,
    this.previewAsset,
    this.isOwned = false,
    this.isEquipped = false,
  });

  String localizedName(String langCode) => langCode == 'fa' ? nameFa : nameEn;
  String localizedDesc(String langCode) => langCode == 'fa' ? descriptionFa : descriptionEn;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price_coins'] ?? json['price'] ?? 0;
    final price = rawPrice is num
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawId = json['item_id'] ?? json['id'] ?? '';

    return ShopItemModel(
      id: rawId.toString(),
      nameFa: json['name_fa']?.toString() ?? json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      descriptionFa: json['description_fa']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      category: json['category']?.toString() ?? 'snake_skin',
      priceCoins: price,
      previewAsset: json['preview_asset']?.toString() ?? json['asset']?.toString(),
      isOwned: json['is_owned'] == true || json['owned'] == true,
      isEquipped: json['is_equipped'] == true || json['equipped'] == true,
    );
  }

  ShopItemModel copyWith({
    String? id,
    String? nameFa,
    String? nameEn,
    String? descriptionFa,
    String? descriptionEn,
    String? category,
    int? priceCoins,
    String? previewAsset,
    bool? isOwned,
    bool? isEquipped,
  }) {
    return ShopItemModel(
      id: id ?? this.id,
      nameFa: nameFa ?? this.nameFa,
      nameEn: nameEn ?? this.nameEn,
      descriptionFa: descriptionFa ?? this.descriptionFa,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      category: category ?? this.category,
      priceCoins: priceCoins ?? this.priceCoins,
      previewAsset: previewAsset ?? this.previewAsset,
      isOwned: isOwned ?? this.isOwned,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }
}

/// Response containing catalog items and user coin balance from GET /shop/catalog
class ShopCatalogResponse {
  final List<ShopItemModel> items;
  final int? userBalance;

  ShopCatalogResponse({
    required this.items,
    this.userBalance,
  });

  factory ShopCatalogResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] ?? json['catalog'] ?? json['data'];
    final list = rawList is List ? rawList : <dynamic>[];
    final items = list
        .map((e) => ShopItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();

    final dataObj = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final rawBalance = json['user_balance'] ??
        json['balance'] ??
        json['coins'] ??
        dataObj?['user_balance'] ??
        dataObj?['balance'] ??
        dataObj?['coins'];

    final userBalance = rawBalance is num
        ? rawBalance.toInt()
        : int.tryParse(rawBalance?.toString() ?? '');

    return ShopCatalogResponse(
      items: items,
      userBalance: userBalance,
    );
  }
}

/// Response returned from POST /shop/purchase
class ShopPurchaseResponse {
  final bool success;
  final int? newBalance;
  final String? message;
  final dynamic itemId;

  ShopPurchaseResponse({
    required this.success,
    this.newBalance,
    this.message,
    this.itemId,
  });

  factory ShopPurchaseResponse.fromJson(Map<String, dynamic> json) {
    final dataObj = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawBalance = dataObj['user_balance'] ??
        dataObj['new_balance'] ??
        dataObj['balance'] ??
        dataObj['coins'] ??
        json['user_balance'] ??
        json['new_balance'] ??
        json['balance'] ??
        json['coins'];

    final newBalance = rawBalance is num
        ? rawBalance.toInt()
        : int.tryParse(rawBalance?.toString() ?? '');

    final rawItemId = dataObj['item_id'] ?? dataObj['id'] ?? json['item_id'] ?? json['id'];

    return ShopPurchaseResponse(
      success: json['success'] == true ||
          json['status'] == 'success' ||
          dataObj['success'] == true ||
          dataObj['status'] == 'success',
      newBalance: newBalance,
      message: json['message']?.toString() ?? dataObj['message']?.toString(),
      itemId: rawItemId,
    );
  }
}
