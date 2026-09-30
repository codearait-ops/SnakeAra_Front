import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/sound_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Modal bottom sheet for submitting user feedback, bug reports, and suggestions.
class FeedbackBottomSheet extends StatefulWidget {
  const FeedbackBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FeedbackBottomSheet(),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  String _selectedType = 'suggestion';
  bool _isLoading = false;
  bool _isTypeDropdownOpen = false;
  String? _errorMessage;

  Map<String, dynamic> get _selectedTypeData => _types.firstWhere(
    (t) => t['id'] == _selectedType,
    orElse: () => _types.first,
  );

  final List<Map<String, dynamic>> _types = const [
    {
      'id': 'suggestion',
      'labelKey': 'feedback_type_suggestion',
      'icon': Icons.lightbulb_outline_rounded,
    },
    {
      'id': 'bug',
      'labelKey': 'feedback_type_bug',
      'icon': Icons.bug_report_outlined,
    },
    {
      'id': 'criticism',
      'labelKey': 'feedback_type_criticism',
      'icon': Icons.rate_review_outlined,
    },
    {
      'id': 'other',
      'labelKey': 'feedback_type_other',
      'icon': Icons.chat_outlined,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final message = _messageController.text.trim();
    if (message.length < 5) {
      setState(() {
        _errorMessage = 'err_feedback_empty'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = Get.find<ApiService>();
      String? token;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isLoggedIn.value) {
          token = auth.currentUser.value?.token;
        }
      }

      final platformInfo = Platform.operatingSystem;

      final res = await api.submitFeedback(
        message: message,
        type: _selectedType,
        contact: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        token: token,
        appVersion: '1.0.0',
        deviceInfo: platformInfo,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        if (Get.isRegistered<SoundService>()) {
          Get.find<SoundService>().playButtonClick();
        }
        Navigator.of(context).pop();
        Get.snackbar(
          'feedback_title'.tr,
          res.message ?? 'feedback_success'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF161B22).withValues(alpha: 0.95),
          colorText: kPrimaryColor,
          icon: const Icon(Icons.check_circle_rounded, color: kPrimaryColor),
          borderColor: kPrimaryColor.withValues(alpha: 0.5),
          borderWidth: 1,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      } else {
        setState(() {
          _errorMessage = res.errorMessage ?? 'err_feedback_failed'.tr;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'err_feedback_failed'.tr;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isRtl =
        Directionality.of(context) == TextDirection.rtl ||
        Get.locale?.languageCode == 'fa';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: kPrimaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close Button Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: kPrimaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'feedback_title'.tr,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'feedback_subtitle'.tr,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Category Selector (Floating Dropdown)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    canvasColor: const Color(0xFF161B22),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(16),
                      elevation: 12,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return _types.map<Widget>((type) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  type['icon'] as IconData,
                                  size: 18,
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (type['labelKey'] as String).tr,
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                      items: _types.map((type) {
                        final isSelected = type['id'] == _selectedType;
                        return DropdownMenuItem<String>(
                          value: type['id'] as String,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kPrimaryColor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 18,
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.white60,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (type['labelKey'] as String).tr,
                                    style: GoogleFonts.vazirmatn(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: kPrimaryColor,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                          if (Get.isRegistered<SoundService>()) {
                            Get.find<SoundService>().playButtonClick();
                          }
                        }
                      },
                    ), // DropdownButton
                  ), // DropdownButtonHideUnderline
                ), // Theme
              ), // Container

              const SizedBox(height: 16),

              // Message Input Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : const Color(0xFF21262D),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 1000,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'feedback_message_hint'.tr,
                    hintStyle: GoogleFonts.vazirmatn(
                      color: Colors.white30,
                      fontSize: 12.5,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    counterStyle: GoogleFonts.vazirmatn(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Contact Info (Optional)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: TextField(
                  controller: _contactController,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    hintText: 'feedback_contact_hint'.tr,
                    hintStyle: GoogleFonts.vazirmatn(
                      color: Colors.white30,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.vazirmatn(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: kPrimaryColor.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: kPrimaryColor.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'feedback_send_btn'.tr,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: 0,
                            child: const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
