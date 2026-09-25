import 'package:flutter/material.dart';
import '../../../app/core/constants/app_constants.dart';

/// Helper to parse color from hex string, integer, or Color object
Color parseHexColor(dynamic hex, {Color fallback = const Color(0xFF00E676)}) {
  if (hex == null) return fallback;
  if (hex is Color) return hex;
  if (hex is int) return Color(hex);
  final str = hex.toString().trim().replaceAll('#', '').replaceAll('0x', '');
  if (str.length == 6) {
    final val = int.tryParse('FF$str', radix: 16);
    if (val != null) return Color(val);
  } else if (str.length == 8) {
    final val = int.tryParse(str, radix: 16);
    if (val != null) return Color(val);
  }
  return fallback;
}

/// Model representing a Board / Game Background Theme
class CosmeticTheme {
  final dynamic id; // int or String (e.g. 1 or 'space')
  final dynamic itemId; // Optional, present in /shop, absent in /home/dashboard
  final String? itemType; // 'theme' or 'board_theme'
  final String themeKey; // e.g. 'space', 'forest', 'sea', 'ancient'
  final String nameFa;
  final String nameEn;
  final int price;
  final bool isFree;
  final bool isPurchased;
  final bool isOwned;
  final String status; // 'free' | 'locked' | 'owned'
  final String previewUrl;
  final Map<String, String> modes; // 8 mode background URLs
  final int sortOrder;
  final bool isActive;

  CosmeticTheme({
    required this.id,
    this.itemId,
    this.itemType = 'theme',
    required this.themeKey,
    required this.nameFa,
    required this.nameEn,
    this.price = 0,
    this.isFree = false,
    this.isPurchased = false,
    this.isOwned = false,
    this.status = 'locked',
    required this.previewUrl,
    required this.modes,
    this.sortOrder = 0,
    this.isActive = true,
  });

  /// Returns localized theme name
  String localizedName(String langCode) => langCode == 'fa' ? nameFa : nameEn;

  /// Effective ID used for purchase / identification
  dynamic get effectiveItemId => itemId ?? id ?? themeKey;

  /// Effective item type used for purchase
  String get effectiveItemType => itemType ?? 'theme';

  /// Whether the user owns or can equip this theme
  bool get hasAccess =>
      isOwned || isFree || isPurchased || status == 'owned' || status == 'free';

  /// Resolves the remote URL for a given game mode key
  String? getModeUrl(String modeKey) {
    final normalized = modeKey.toLowerCase();
    return modes[normalized] ?? modes['classic'] ?? previewUrl;
  }

  CosmeticTheme copyWith({
    dynamic id,
    dynamic itemId,
    String? itemType,
    String? themeKey,
    String? nameFa,
    String? nameEn,
    int? price,
    bool? isFree,
    bool? isPurchased,
    bool? isOwned,
    String? status,
    String? previewUrl,
    Map<String, String>? modes,
    int? sortOrder,
    bool? isActive,
  }) {
    return CosmeticTheme(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      themeKey: themeKey ?? this.themeKey,
      nameFa: nameFa ?? this.nameFa,
      nameEn: nameEn ?? this.nameEn,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      isPurchased: isPurchased ?? this.isPurchased,
      isOwned: isOwned ?? this.isOwned,
      status: status ?? this.status,
      previewUrl: previewUrl ?? this.previewUrl,
      modes: modes ?? this.modes,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Tolerant factory parsing from either /home/dashboard or /shop payload
  factory CosmeticTheme.fromJson(Map<String, dynamic> json) {
    final rawModes = json['modes'];
    final Map<String, String> modesMap = {};
    if (rawModes is Map) {
      rawModes.forEach((k, v) {
        if (k != null && v != null) {
          modesMap[k.toString().toLowerCase()] = v.toString();
        }
      });
    }

    final rawPrice = json['price'] ?? json['price_coins'] ?? 0;
    final price = rawPrice is num
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawSort = json['sort_order'] ?? json['sortOrder'] ?? 0;
    final sortOrder = rawSort is num
        ? rawSort.toInt()
        : (int.tryParse(rawSort.toString()) ?? 0);

    final isFree = json['is_free'] == true || json['free'] == true;
    final isPurchased =
        json['is_purchased'] == true || json['purchased'] == true;
    final isOwned =
        json['is_owned'] == true ||
        json['owned'] == true ||
        isFree ||
        isPurchased ||
        json['status'] == 'owned' ||
        json['status'] == 'free';

    final statusStr =
        json['status']?.toString().toLowerCase() ??
        (isOwned || isFree ? 'owned' : 'locked');

    final rawKey =
        json['theme_key'] ??
        json['themeKey'] ??
        json['key'] ??
        json['id']?.toString() ??
        'space';

    final rawNameFa = json['name_fa'] ?? json['nameFa'] ?? json['name'] ?? '';
    final rawNameEn =
        json['name_en'] ?? json['nameEn'] ?? json['name'] ?? rawNameFa;

    return CosmeticTheme(
      id: json['id'] ?? rawKey,
      itemId: json['item_id'] ?? json['itemId'],
      itemType:
          json['item_type']?.toString() ??
          json['itemType']?.toString() ??
          'theme',
      themeKey: rawKey.toString(),
      nameFa: rawNameFa.toString(),
      nameEn: rawNameEn.toString(),
      price: price,
      isFree: isFree,
      isPurchased: isPurchased,
      isOwned: isOwned,
      status: statusStr,
      previewUrl:
          json['preview_url']?.toString() ??
          json['previewUrl']?.toString() ??
          '',
      modes: modesMap,
      sortOrder: sortOrder,
      isActive: json['is_active'] != false && json['isActive'] != false,
    );
  }

  /// Factory specifically tailored for /home/dashboard `available_themes` entries
  factory CosmeticTheme.fromDashboardJson(Map<String, dynamic> json) {
    final parsed = CosmeticTheme.fromJson(json);
    return parsed.copyWith(isOwned: true, status: 'owned');
  }

  /// Factory specifically tailored for /shop `themes` entries
  factory CosmeticTheme.fromShopJson(Map<String, dynamic> json) {
    return CosmeticTheme.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'theme_key': themeKey,
      'name_fa': nameFa,
      'name_en': nameEn,
      'price': price,
      'is_free': isFree,
      'is_purchased': isPurchased,
      'is_owned': isOwned,
      'status': status,
      'preview_url': previewUrl,
      'modes': modes,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

/// Model representing a Player Cosmetic Avatar
class CosmeticAvatar {
  final dynamic id; // int or String (e.g. 1 or 'avatar_1')
  final dynamic itemId; // Optional, present in /shop, absent in /home/dashboard
  final String? itemType; // 'avatar'
  final String name;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final String imageUrl;
  final int price;
  final bool isFree;
  final bool isPurchased;
  final bool isOwned;
  final String status; // 'free' | 'locked' | 'owned'
  final int sortOrder;
  final bool isActive;

  CosmeticAvatar({
    required this.id,
    this.itemId,
    this.itemType = 'avatar',
    required this.name,
    this.title = '',
    this.primaryColor = kAvatarPrimaryColor,
    this.secondaryColor = kAvatarSecondaryColor,
    required this.imageUrl,
    this.price = 0,
    this.isFree = false,
    this.isPurchased = false,
    this.isOwned = false,
    this.status = 'locked',
    this.sortOrder = 0,
    this.isActive = true,
  });

  /// Effective ID used for purchase / identification
  dynamic get effectiveItemId => itemId ?? id;

  /// Effective item type used for purchase
  String get effectiveItemType => itemType ?? 'avatar';

  /// Whether the user owns or can equip this avatar
  bool get hasAccess =>
      isOwned || isFree || isPurchased || status == 'owned' || status == 'free';

  CosmeticAvatar copyWith({
    dynamic id,
    dynamic itemId,
    String? itemType,
    String? name,
    String? title,
    Color? primaryColor,
    Color? secondaryColor,
    String? imageUrl,
    int? price,
    bool? isFree,
    bool? isPurchased,
    bool? isOwned,
    String? status,
    int? sortOrder,
    bool? isActive,
  }) {
    return CosmeticAvatar(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      title: title ?? this.title,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      isPurchased: isPurchased ?? this.isPurchased,
      isOwned: isOwned ?? this.isOwned,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Tolerant factory parsing from either /home/dashboard or /shop payload
  factory CosmeticAvatar.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['price_coins'] ?? 0;
    final price = rawPrice is num
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawSort = json['sort_order'] ?? json['sortOrder'] ?? 0;
    final sortOrder = rawSort is num
        ? rawSort.toInt()
        : (int.tryParse(rawSort.toString()) ?? 0);

    final isFree = json['is_free'] == true || json['free'] == true;
    final isPurchased =
        json['is_purchased'] == true || json['purchased'] == true;
    final isOwned =
        json['is_owned'] == true ||
        json['owned'] == true ||
        isFree ||
        isPurchased ||
        json['status'] == 'owned' ||
        json['status'] == 'free';

    final statusStr =
        json['status']?.toString().toLowerCase() ??
        (isOwned || isFree ? 'owned' : 'locked');

    final rawId =
        json['id'] ?? json['avatar_id'] ?? json['avatarId'] ?? 'avatar_1';

    return CosmeticAvatar(
      id: rawId,
      itemId: json['item_id'] ?? json['itemId'],
      itemType:
          json['item_type']?.toString() ??
          json['itemType']?.toString() ??
          'avatar',
      name: json['name']?.toString() ?? 'Avatar',
      title: json['title']?.toString() ?? '',
      primaryColor: kAvatarPrimaryColor,
      secondaryColor: kAvatarSecondaryColor,
      imageUrl:
          json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['url']?.toString() ??
          '',
      price: price,
      isFree: isFree,
      isPurchased: isPurchased,
      isOwned: isOwned,
      status: statusStr,
      sortOrder: sortOrder,
      isActive: json['is_active'] != false && json['isActive'] != false,
    );
  }

  /// Factory specifically tailored for /home/dashboard `available_avatars` entries
  factory CosmeticAvatar.fromDashboardJson(Map<String, dynamic> json) {
    final parsed = CosmeticAvatar.fromJson(json);
    return parsed.copyWith(isOwned: true, status: 'owned');
  }

  /// Factory specifically tailored for /shop `avatars` entries
  factory CosmeticAvatar.fromShopJson(Map<String, dynamic> json) {
    return CosmeticAvatar.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'name': name,
      'title': title,
      'primary_color':
          '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'secondary_color':
          '#${secondaryColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'image_url': imageUrl,
      'price': price,
      'is_free': isFree,
      'is_purchased': isPurchased,
      'is_owned': isOwned,
      'status': status,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

/// Model representing a server-driven Snake Skin cosmetic.
/// Parsed from /shop `skins` array and /home/dashboard `available_skins` array.
class CosmeticSnakeSkin {
  final dynamic id; // int or String
  final dynamic itemId; // item_id field from server (e.g. 'neon_green')
  final String? itemType; // 'snake_skin'
  final String skinKey; // e.g. 'neon_green', 'rainbow'
  final String nameFa;
  final String nameEn;
  final int price;
  final bool isFree;
  final bool isPurchased;
  final bool isOwned;
  final String status; // 'free' | 'locked' | 'owned' | 'purchased'
  final Color headColor;
  final Color tailColor;
  final Color glowColor;
  final List<Color>? gradientColors; // null for solid skins
  final String previewUrl;
  final int sortOrder;
  final bool isActive;

  CosmeticSnakeSkin({
    required this.id,
    this.itemId,
    this.itemType = 'snake_skin',
    required this.skinKey,
    required this.nameFa,
    required this.nameEn,
    this.price = 0,
    this.isFree = false,
    this.isPurchased = false,
    this.isOwned = false,
    this.status = 'locked',
    required this.headColor,
    required this.tailColor,
    required this.glowColor,
    this.gradientColors,
    this.previewUrl = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  /// Primary color for UI previews (first gradient color or head color).
  Color get primaryColor => gradientColors?.first ?? headColor;

  /// Whether this skin uses a multi-color gradient.
  bool get isGradient => gradientColors != null && gradientColors!.isNotEmpty;

  /// Returns localized skin name based on language code.
  String localizedName(String langCode) => langCode == 'fa' ? nameFa : nameEn;

  /// Effective item ID for purchase / identification.
  dynamic get effectiveItemId => itemId ?? id ?? skinKey;

  /// Effective item type for purchase endpoint.
  String get effectiveItemType => itemType ?? 'snake_skin';

  /// Whether the user can equip this skin.
  bool get hasAccess =>
      isOwned || isFree || isPurchased || status == 'owned' || status == 'free';

  /// Calculate exact segment color at progress [t] (0.0 = head, 1.0 = tail).
  Color getColorAt(double t) {
    if (isGradient) {
      final list = gradientColors!;
      if (list.length == 1) return list.first;
      final scaledT = t * (list.length - 1);
      final index = scaledT.floor().clamp(0, list.length - 2);
      final remainder = scaledT - index;
      return Color.lerp(list[index], list[index + 1], remainder)!;
    }
    return Color.lerp(headColor, tailColor, t)!;
  }

  CosmeticSnakeSkin copyWith({
    dynamic id,
    dynamic itemId,
    String? itemType,
    String? skinKey,
    String? nameFa,
    String? nameEn,
    int? price,
    bool? isFree,
    bool? isPurchased,
    bool? isOwned,
    String? status,
    Color? headColor,
    Color? tailColor,
    Color? glowColor,
    List<Color>? gradientColors,
    String? previewUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return CosmeticSnakeSkin(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      skinKey: skinKey ?? this.skinKey,
      nameFa: nameFa ?? this.nameFa,
      nameEn: nameEn ?? this.nameEn,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      isPurchased: isPurchased ?? this.isPurchased,
      isOwned: isOwned ?? this.isOwned,
      status: status ?? this.status,
      headColor: headColor ?? this.headColor,
      tailColor: tailColor ?? this.tailColor,
      glowColor: glowColor ?? this.glowColor,
      gradientColors: gradientColors ?? this.gradientColors,
      previewUrl: previewUrl ?? this.previewUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Tolerant factory — parses both /shop and /home/dashboard payloads.
  factory CosmeticSnakeSkin.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['price_coins'] ?? 0;
    final price = rawPrice is num
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawSort = json['sort_order'] ?? json['sortOrder'] ?? 0;
    final sortOrder = rawSort is num
        ? rawSort.toInt()
        : (int.tryParse(rawSort.toString()) ?? 0);

    final isFree = json['is_free'] == true || json['free'] == true;
    final isPurchased =
        json['is_purchased'] == true || json['purchased'] == true;
    final isOwned =
        json['is_owned'] == true ||
        json['owned'] == true ||
        isFree ||
        isPurchased ||
        json['status'] == 'owned' ||
        json['status'] == 'free' ||
        json['status'] == 'purchased';

    final statusStr =
        json['status']?.toString().toLowerCase() ??
        (isOwned ? 'owned' : 'locked');

    final rawKey =
        json['skin_key'] ??
        json['skinKey'] ??
        json['key'] ??
        json['id']?.toString() ??
        'neon_green';

    // Parse gradient_colors array of hex strings
    List<Color>? gradientColors;
    final rawGradient = json['gradient_colors'];
    if (rawGradient is List && rawGradient.isNotEmpty) {
      gradientColors = rawGradient
          .where((e) => e != null)
          .map((e) => parseHexColor(e))
          .toList();
    }

    return CosmeticSnakeSkin(
      id: json['id'] ?? rawKey,
      itemId: json['item_id'] ?? json['itemId'],
      itemType:
          json['item_type']?.toString() ??
          json['itemType']?.toString() ??
          'snake_skin',
      skinKey: rawKey.toString(),
      nameFa:
          (json['name_fa'] ?? json['nameFa'] ?? json['name'] ?? '')
              .toString(),
      nameEn:
          (json['name_en'] ??
                  json['nameEn'] ??
                  json['name'] ??
                  json['name_fa'] ??
                  '')
              .toString(),
      price: price,
      isFree: isFree,
      isPurchased: isPurchased,
      isOwned: isOwned,
      status: statusStr,
      headColor: parseHexColor(
        json['head_color'] ?? json['headColor'],
        fallback: const Color(0xFF69F0AE),
      ),
      tailColor: parseHexColor(
        json['tail_color'] ?? json['tailColor'],
        fallback: const Color(0xFF004D40),
      ),
      glowColor: parseHexColor(
        json['glow_color'] ?? json['glowColor'],
        fallback: const Color(0xFF00E676),
      ),
      gradientColors: gradientColors,
      previewUrl:
          json['preview_url']?.toString() ??
          json['previewUrl']?.toString() ??
          '',
      sortOrder: sortOrder,
      isActive: json['is_active'] != false && json['isActive'] != false,
    );
  }

  /// Factory tailored for /home/dashboard `available_skins` entries.
  factory CosmeticSnakeSkin.fromDashboardJson(Map<String, dynamic> json) {
    final parsed = CosmeticSnakeSkin.fromJson(json);
    return parsed.copyWith(isOwned: true, status: 'owned');
  }

  /// Factory tailored for /shop `skins` entries.
  factory CosmeticSnakeSkin.fromShopJson(Map<String, dynamic> json) {
    return CosmeticSnakeSkin.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'skin_key': skinKey,
      'name_fa': nameFa,
      'name_en': nameEn,
      'price': price,
      'is_free': isFree,
      'is_purchased': isPurchased,
      'is_owned': isOwned,
      'status': status,
      'head_color': '#${headColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'tail_color': '#${tailColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'glow_color': '#${glowColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'gradient_colors': gradientColors
          ?.map((c) =>
              '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}')
          .toList(),
      'preview_url': previewUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

/// Catalog Response returned from GET /snake_ara/api/shop
class CosmeticsCatalogResponse {
  final List<CosmeticTheme> themes;
  final List<CosmeticAvatar> avatars;
  final List<CosmeticSnakeSkin> skins;
  final int? userBalance;

  CosmeticsCatalogResponse({
    required this.themes,
    required this.avatars,
    this.skins = const [],
    this.userBalance,
  });

  factory CosmeticsCatalogResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : json);

    final rawThemes = data['themes'] ?? json['themes'];
    final List<CosmeticTheme> themesList = [];
    if (rawThemes is List) {
      for (final item in rawThemes) {
        if (item is Map) {
          themesList.add(
            CosmeticTheme.fromShopJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final rawAvatars = data['avatars'] ?? json['avatars'];
    final List<CosmeticAvatar> avatarsList = [];
    if (rawAvatars is List) {
      for (final item in rawAvatars) {
        if (item is Map) {
          avatarsList.add(
            CosmeticAvatar.fromShopJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    // Parse skins array from /shop
    final rawSkins = data['skins'] ?? json['skins'];
    final List<CosmeticSnakeSkin> skinsList = [];
    if (rawSkins is List) {
      for (final item in rawSkins) {
        if (item is Map) {
          skinsList.add(
            CosmeticSnakeSkin.fromShopJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    // wallet balance can be nested under 'wallet' key (as in actual API response)
    final walletMap = json['wallet'];
    final rawBalance =
        (walletMap is Map ? walletMap['coin_balance'] ?? walletMap['balance'] : null) ??
        data['user_balance'] ??
        data['balance'] ??
        data['coins'] ??
        json['user_balance'] ??
        json['balance'] ??
        json['coins'];

    final userBalance = rawBalance is num
        ? rawBalance.toInt()
        : int.tryParse(rawBalance?.toString() ?? '');

    return CosmeticsCatalogResponse(
      themes: themesList,
      avatars: avatarsList,
      skins: skinsList,
      userBalance: userBalance,
    );
  }
}
