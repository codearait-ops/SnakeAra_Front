import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/settings/controllers/settings_controller.dart';

/// A modern floating island AppBar with genuine glassmorphism blur (BackdropFilter),
/// rounded corners, glowing border, and adaptive RTL/LTR navigation.
class FloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? accentColor;
  final double height;
  final double horizontalMargin;
  final double topMargin;
  final double bottomMargin;

  const FloatingAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.showBack = true,
    this.onBackPressed,
    this.backgroundColor,
    this.borderColor,
    this.accentColor,
    this.height = 54.0,
    this.horizontalMargin = 16.0,
    this.topMargin = 8.0,
    this.bottomMargin = 6.0,
  });

  /// Total height of the floating app bar including status bar and margins.
  static double preferredTotalHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 54.0 + 8.0 + 6.0;
  }

  @override
  Size get preferredSize => Size.fromHeight(height + topMargin + bottomMargin);

  bool _resolveIsRtl(BuildContext context) {
    if (Get.isRegistered<SettingsController>()) {
      final code = Get.find<SettingsController>().currentLanguage.value.toLowerCase();
      if (code == 'fa' || code == 'ar') return true;
      if (code == 'en') return false;
    }
    final locale = Get.locale ?? Localizations.maybeLocaleOf(context);
    if (locale != null) {
      final code = locale.languageCode.toLowerCase();
      if (code == 'fa' || code == 'ar') return true;
      if (code == 'en') return false;
    }
    return Directionality.maybeOf(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SettingsController>()) {
      return Obx(() {
        final lang = Get.find<SettingsController>().currentLanguage.value.toLowerCase();
        final isRtl = lang == 'fa' || lang == 'ar';
        return _buildBar(context, isRtl);
      });
    }
    return _buildBar(context, _resolveIsRtl(context));
  }

  Widget _buildBar(BuildContext context, bool isRtl) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final effectiveShowBack = showBack && canPop;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && effectiveShowBack) {
      leadingWidget = IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.white,
        ),
        tooltip: isRtl ? 'بازگشت' : MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      );
    }

    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      titleWidget = Text(
        titleText!,
        style: GoogleFonts.vazirmatn(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: isRtl ? 0 : 0.8,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          margin: EdgeInsets.fromLTRB(horizontalMargin, topMargin, horizontalMargin, bottomMargin),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              if (accentColor != null)
                BoxShadow(
                  color: accentColor!.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor ??
                        (accentColor != null
                            ? accentColor!.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.18)),
                    width: 1.0,
                  ),
                ),
                child: NavigationToolbar(
                  leading: leadingWidget,
                  middle: titleWidget,
                  trailing: actions != null && actions!.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        )
                      : null,
                  centerMiddle: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
