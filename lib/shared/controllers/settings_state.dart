part of 'settings_controller.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool? biometricsIsEnabled,
    @Default(false) bool? darkModeIsEnabled,
    File? userProfilePicture,
  }) = _SettingsState;
}
