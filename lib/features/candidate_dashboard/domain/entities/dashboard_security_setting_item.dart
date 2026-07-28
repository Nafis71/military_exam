enum DashboardSecuritySettingType {
  vpn,
  airplane,
  wifi,
  camera,
}

class DashboardSecuritySettingItem {
  const DashboardSecuritySettingItem({
    required this.type,
    required this.isEnabled,
    this.isBusy = false,
    this.hasError = false,
    this.isToggleDisabled = false,
    this.disabledHint,
  });

  final DashboardSecuritySettingType type;
  final bool isEnabled;
  final bool isBusy;
  final bool hasError;
  final bool isToggleDisabled;
  final String? disabledHint;

  DashboardSecuritySettingItem copyWith({
    bool? isEnabled,
    bool? isBusy,
    bool? hasError,
    bool? isToggleDisabled,
    String? disabledHint,
  }) {
    return DashboardSecuritySettingItem(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      isToggleDisabled: isToggleDisabled ?? this.isToggleDisabled,
      disabledHint: disabledHint ?? this.disabledHint,
    );
  }
}
