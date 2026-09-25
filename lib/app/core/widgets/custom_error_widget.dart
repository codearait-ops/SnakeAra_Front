import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service/Widget to capture Flutter build errors and display a modern, dark-mode,
/// responsive error fallback instead of the default red screen of death (RedScreen).
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({
    super.key,
    required this.errorDetails,
  });

  /// Configures Flutter's global ErrorWidget builder.
  static void initialize() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(errorDetails: details);
    };
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 20,
            vertical: 16,
          ),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'A temporary UI glitch occurred. Tap below to reload this section.'.tr,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.forceAppUpdate();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Retry'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
