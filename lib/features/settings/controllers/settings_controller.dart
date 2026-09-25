import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../game/controllers/game_controller.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';

/// GetX controller managing user preferences, audio toggles, language, and settings UI state.
class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final SoundService soundService = Get.find<SoundService>();

  final RxBool soundEffectsEnabled = true.obs;
  final RxBool bgMusicEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;
  final RxBool showJoystickEnabled = true.obs;
  final RxString controlType = 'swipe'.obs; // 'swipe' or 'buttons'
  final RxString selectedSkinId = 'neon_green'.obs;
  final RxString selectedBoardSkinId = 'default'.obs;
  final RxString currentLanguage = 'en'.obs; // 'en' or 'fa'

  Locale get currentLocale =>
      Locale(currentLanguage.value, currentLanguage.value == 'fa' ? 'IR' : 'US');

  @override
  void onInit() {
    super.onInit();
    soundEffectsEnabled.value = _storage.prefs.getBool('sfx_enabled') ?? true;
    bgMusicEnabled.value = _storage.prefs.getBool('bg_music_enabled') ?? true;
    vibrationEnabled.value = _storage.prefs.getBool('vibration_enabled') ?? true;
    showJoystickEnabled.value = _storage.getShowJoystick();
    controlType.value = _storage.prefs.getString('control_type') ?? 'swipe';
    selectedSkinId.value = _storage.getSelectedSkinId();
    selectedBoardSkinId.value = _storage.getSelectedBoardSkinId();
    currentLanguage.value = _storage.getLanguageCode();
  }

  void changeLanguage(String code) {
    if (currentLanguage.value == code) return;
    currentLanguage.value = code;
    _storage.saveLanguageCode(code);
    final newLocale = Locale(code, code == 'fa' ? 'IR' : 'US');
    Get.updateLocale(newLocale);
    if (soundEffectsEnabled.value) soundService.playButtonTap();
  }

  void toggleSoundEffects(bool value) {
    soundEffectsEnabled.value = value;
    _storage.prefs.setBool('sfx_enabled', value);
    if (value) soundService.playButtonTap();
  }

  void toggleBgMusic(bool value) {
    bgMusicEnabled.value = value;
    _storage.prefs.setBool('bg_music_enabled', value);
    if (!value) {
      soundService.stopBgMusic();
    }
  }

  /// Cycles through audio states:
  /// 1. Both ON (Music ON, SFX ON)
  /// 2. Music OFF, SFX ON
  /// 3. Both OFF (All Muted)
  /// and loops back to 1.
  void cycleAudioMode({VoidCallback? onMusicEnabled}) {
    if (bgMusicEnabled.value && soundEffectsEnabled.value) {
      // 1st press: Disable background music, keep sound effects
      toggleBgMusic(false);
      if (soundEffectsEnabled.value) soundService.playButtonTap();
    } else if (!bgMusicEnabled.value && soundEffectsEnabled.value) {
      // 2nd press: Disable sound effects as well (mute all)
      toggleSoundEffects(false);
    } else {
      // 3rd press: Enable both music and sound effects
      bgMusicEnabled.value = true;
      _storage.prefs.setBool('bg_music_enabled', true);
      soundEffectsEnabled.value = true;
      _storage.prefs.setBool('sfx_enabled', true);
      soundService.playButtonTap();
      if (onMusicEnabled != null) {
        onMusicEnabled();
      } else {
        soundService.playBgMusic();
      }
    }
  }

  void toggleVibration(bool value) {
    vibrationEnabled.value = value;
    _storage.prefs.setBool('vibration_enabled', value);
    if (soundEffectsEnabled.value) soundService.playButtonTap();
  }

  void toggleShowJoystick(bool value) {
    showJoystickEnabled.value = value;
    _storage.saveShowJoystick(value);
    soundService.playButtonTap();
  }

  void setControlType(String type) {
    controlType.value = type;
    _storage.prefs.setString('control_type', type);
    if (soundEffectsEnabled.value) soundService.playButtonTap();
  }

  void selectSkin(String skinId) {
    selectedSkinId.value = skinId;
    _storage.saveSelectedSkinId(skinId);
    if (Get.isRegistered<GameController>()) {
      Get.find<GameController>().snakeGame.refreshSkin();
    }
    soundService.playButtonTap();
  }

  void selectBoardSkin(String boardSkinId) {
    selectedBoardSkinId.value = boardSkinId;
    _storage.saveSelectedBoardSkinId(boardSkinId);
    if (Get.isRegistered<GameController>()) {
      Get.find<GameController>().snakeGame.refreshBoardSkin();
    }
    soundService.playButtonTap();
  }
}
