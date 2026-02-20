class LockedApp {
  final String packageName;
  final String appName;
  final String? iconPath;
  /// Base64-encoded app icon (from InstalledApp), used for display.
  final String? iconBase64;
  final LockType lockType;
  final String? password;
  final String? pin;
  final String? pattern;
  bool isLocked;
  final bool isHidden;
  final bool isBlocked;
  final DateTime? lockScheduleStart;
  final DateTime? lockScheduleEnd;

  LockedApp({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.iconBase64,
    required this.lockType,
    this.password,
    this.pin,
    this.pattern,
    this.isLocked = true,
    this.isHidden = false,
    this.isBlocked = false,
    this.lockScheduleStart,
    this.lockScheduleEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'iconBase64': iconBase64,
      'lockType': lockType.toString().split('.').last,
      'password': password,
      'pin': pin,
      'pattern': pattern,
      'isLocked': isLocked,
      'isHidden': isHidden,
      'isBlocked': isBlocked,
      'lockScheduleStart': lockScheduleStart?.toIso8601String(),
      'lockScheduleEnd': lockScheduleEnd?.toIso8601String(),
    };
  }

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: json['packageName'],
      appName: json['appName'],
      iconPath: json['iconPath'],
      iconBase64: json['iconBase64'],
      lockType: LockType.values.firstWhere(
        (e) => e.toString().split('.').last == json['lockType'],
        orElse: () => LockType.password,
      ),
      password: json['password'],
      pin: json['pin'],
      pattern: json['pattern'],
      isLocked: json['isLocked'] ?? true,
      isHidden: json['isHidden'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      lockScheduleStart: json['lockScheduleStart'] != null
          ? DateTime.parse(json['lockScheduleStart'])
          : null,
      lockScheduleEnd: json['lockScheduleEnd'] != null
          ? DateTime.parse(json['lockScheduleEnd'])
          : null,
    );
  }
}

enum LockType {
  password,
  pin,
  pattern,
  biometric,
}
