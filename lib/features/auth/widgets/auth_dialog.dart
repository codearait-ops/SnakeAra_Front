import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../controllers/auth_controller.dart';

/// Modal dialog for User Login, Registration, and Preset Avatar selection.
class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isForgotPasswordMode = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _isForgotPasswordMode) {
        setState(() {
          _isForgotPasswordMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kPrimaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Tab Bar
              Container(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF161B22),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: kPrimaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isForgotPasswordMode
                                  ? 'forgot_password_title'.tr
                                  : 'online_league_account'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_isForgotPasswordMode)
                      TabBar(
                        controller: _tabController,
                        indicatorColor: kPrimaryColor,
                        labelColor: kPrimaryColor,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: [
                          Tab(text: 'register_avatar_tab'.tr),
                          Tab(text: 'login_tab'.tr),
                        ],
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ),

              // Form content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(() {
                  if (_isForgotPasswordMode) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'forgot_password_desc'.tr,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email field for password recovery
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'email_label'.tr,
                            labelStyle: GoogleFonts.vazirmatn(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF161B22),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: kPrimaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Send Reset Link Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: auth.isLoading.value
                                ? null
                                : () async {
                                    final email = _emailController.text.trim();
                                    debugPrint('[AUTH DIALOG -> SUBMIT FORGOT PASSWORD] Email: "$email"');
                                    if (email.isEmpty || !email.contains('@')) {
                                      debugPrint('[AUTH DIALOG -> INVALID EMAIL FORMAT]');
                                      Get.snackbar(
                                        'input_error'.tr,
                                        'email_required_error'.tr,
                                      );
                                      return;
                                    }

                                    final success =
                                        await auth.forgotPassword(email: email);
                                    if (success) {
                                      setState(() {
                                        _isForgotPasswordMode = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: auth.isLoading.value
                                ? const AppLoadingWidget.small(
                                    size: 20,
                                    color: Colors.black,
                                  )
                                : Text(
                                    'send_reset_link'.tr,
                                    style: GoogleFonts.vazirmatn(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Back to login button
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isForgotPasswordMode = false;
                              });
                            },
                            child: Text(
                              'back_to_login'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Username field
                      TextField(
                        controller: _usernameController,
                        style: GoogleFonts.vazirmatn(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'username_nickname'.tr,
                          labelStyle: GoogleFonts.vazirmatn(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.vazirmatn(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'password_label'.tr,
                          labelStyle: GoogleFonts.vazirmatn(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF161B22),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Optional Email Field (In Register Tab) or Forgot Password Button (In Login Tab)
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          if (_tabController.index == 0) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style:
                                      GoogleFonts.vazirmatn(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'email_label'.tr,
                                    labelStyle: GoogleFonts.vazirmatn(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: kPrimaryColor,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF161B22),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: kPrimaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isForgotPasswordMode = true;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'forgot_password'.tr,
                                    style: GoogleFonts.vazirmatn(
                                      color: kPrimaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading.value
                              ? null
                              : () async {
                                  final username = _usernameController.text
                                      .trim();
                                  final password = _passwordController.text
                                      .trim();

                                  if (username.isEmpty || password.isEmpty) {
                                    Get.snackbar(
                                      'input_error'.tr,
                                      'please_fill_fields'.tr,
                                    );
                                    return;
                                  }

                                  bool success;
                                  if (_tabController.index == 0) {
                                    final email = _emailController.text.trim();
                                    success = await auth.register(
                                      username: username,
                                      password: password,
                                      avatarId: 'avatar_1',
                                      email: email.isNotEmpty ? email : null,
                                    );
                                  } else {
                                    success = await auth.login(
                                      username: username,
                                      password: password,
                                    );
                                  }

                                  if (success) {
                                    Get.back();
                                    Get.offAllNamed('/menu');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading.value
                              ? const AppLoadingWidget.small(
                                  size: 20,
                                  color: Colors.black,
                                )
                              : Text(
                                  _tabController.index == 0
                                      ? 'join_league'.tr
                                      : 'log_in_btn'.tr,
                                  style: GoogleFonts.vazirmatn(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
