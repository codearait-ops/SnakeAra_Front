import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// A unified, highly-polished cyberpunk/arcade loading widget for SnakeAra.
/// Provides consistent loading indicators across screens, cards, modals, and buttons.
class AppLoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final double? strokeWidth;
  final String? message;
  final TextStyle? messageStyle;
  final bool isCard;
  final EdgeInsetsGeometry? cardPadding;
  final bool fullScreen;

  const AppLoadingWidget({
    super.key,
    this.size = 36.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth,
    this.message,
    this.messageStyle,
    this.isCard = false,
    this.cardPadding,
    this.fullScreen = false,
  });

  /// Small variant ideal for inside buttons and compact inline headers.
  const AppLoadingWidget.small({
    super.key,
    this.size = 18.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
  })  : message = null,
        messageStyle = null,
        isCard = false,
        cardPadding = null,
        fullScreen = false;

  /// Card variant wrapped in a glassmorphic container with glowing borders.
  const AppLoadingWidget.card({
    super.key,
    this.size = 36.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth,
    this.message,
    this.messageStyle,
    this.cardPadding,
  })  : isCard = true,
        fullScreen = false;

  /// Fullscreen / Centered page view variant with optional backdrop and message.
  const AppLoadingWidget.fullScreen({
    super.key,
    this.size = 42.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth,
    this.message,
    this.messageStyle,
  })  : isCard = false,
        cardPadding = null,
        fullScreen = true;

  /// Gold/Amber variant specifically designed for League, Hall of Fame, and Shop.
  const AppLoadingWidget.gold({
    super.key,
    this.size = 36.0,
    this.message,
    this.messageStyle,
    this.isCard = false,
    this.fullScreen = false,
    this.strokeWidth,
  })  : color = kGoldColor,
        secondaryColor = const Color(0x33FFD700),
        cardPadding = null;

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? kPrimaryColor;
    final effectiveSecondaryColor = widget.secondaryColor ??
        effectiveColor.withValues(alpha: 0.15);
    final effectiveStroke = widget.strokeWidth ??
        (widget.size * 0.08).clamp(2.0, 3.5);

    Widget spinner = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(
                  alpha: 0.2 + (_pulseAnimation.value * 0.25),
                ),
                blurRadius: widget.size * (0.3 + _pulseAnimation.value * 0.2),
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track Ring
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: effectiveStroke,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveSecondaryColor),
            ),
          ),
          // Active Spinning Arc
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: effectiveStroke,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
        ],
      ),
    );

    Widget content = spinner;

    if (widget.message != null && widget.message!.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          spinner,
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: 0.75 + (_pulseAnimation.value * 0.25),
                child: child,
              );
            },
            child: Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: widget.messageStyle ??
                  GoogleFonts.vazirmatn(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
        ],
      );
    }

    if (widget.isCard) {
      content = Container(
        padding: widget.cardPadding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: content,
      );
    }

    if (widget.fullScreen) {
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
