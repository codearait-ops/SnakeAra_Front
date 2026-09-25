import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../cosmetics/models/cosmetics_models.dart';

/// Interactive grid allowing users to choose from dynamic / cached cosmetic avatars.
class AvatarSelectorWidget extends StatelessWidget {
  final String selectedAvatarId;
  final ValueChanged<String> onSelectAvatar;

  const AvatarSelectorWidget({
    super.key,
    required this.selectedAvatarId,
    required this.onSelectAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final cosmetics = Get.isRegistered<CosmeticsController>()
        ? Get.find<CosmeticsController>()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_avatar'.tr,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        if (cosmetics != null)
          Obx(() {
            final avatarsList = cosmetics.allAvatars.isNotEmpty
                ? cosmetics.allAvatars.where((a) => a.hasAccess).toList()
                : <CosmeticAvatar>[];

            if (avatarsList.isEmpty) {
              return _buildFallbackGrid();
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: avatarsList.length,
              itemBuilder: (context, index) {
                final avatar = avatarsList[index];
                final isSelected = avatar.id.toString() == selectedAvatarId ||
                    avatar.itemId?.toString() == selectedAvatarId;

                return GestureDetector(
                  onTap: () => onSelectAvatar(avatar.id.toString()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          avatar.primaryColor.withValues(alpha: isSelected ? 0.35 : 0.1),
                          avatar.secondaryColor.withValues(alpha: isSelected ? 0.2 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? avatar.primaryColor
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: avatar.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatar.primaryColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: avatar.primaryColor.withValues(
                                alpha: isSelected ? 0.8 : 0.25,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: avatar.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatar.imageUrl,
                                    fit: BoxFit.cover,
                                    width: 44,
                                    height: 44,
                                    placeholder: (_, __) => Container(
                                      color: avatar.primaryColor.withValues(alpha: 0.3),
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      color: avatar.primaryColor,
                                      size: 24,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: avatar.primaryColor,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          avatar.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          })
        else
          _buildFallbackGrid(),
      ],
    );
  }

  Widget _buildFallbackGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: kPresetAvatars.length,
      itemBuilder: (context, index) {
        final avatar = kPresetAvatars[index];
        final isSelected = avatar.id == selectedAvatarId;

        return GestureDetector(
          onTap: () => onSelectAvatar(avatar.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  avatar.primaryColor.withValues(alpha: isSelected ? 0.35 : 0.1),
                  avatar.secondaryColor.withValues(alpha: isSelected ? 0.2 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? avatar.primaryColor
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  avatar.icon,
                  color: avatar.primaryColor,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  avatar.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
