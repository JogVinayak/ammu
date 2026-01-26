import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';

enum SoundType {
  builtin,
  custom,
}

class SoundOption {
  final String id;
  final String name;
  final String? assetPath; // For built-in sounds
  final String? filePath; // For custom sounds from device
  final SoundType type;
  final String icon;

  const SoundOption({
    required this.id,
    required this.name,
    this.assetPath,
    this.filePath,
    required this.type,
    this.icon = '🔔',
  });

  /// Get the path to play (either asset or file)
  String? get playablePath => type == SoundType.builtin ? assetPath : filePath;

  /// Check if this is the default sound
  bool get isDefault => id == 'bell';

  /// Check if this is a custom sound
  bool get isCustom => type == SoundType.custom;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'filePath': filePath,
      'type': type.name,
      'icon': icon,
    };
  }

  factory SoundOption.fromJson(Map<String, dynamic> json) {
    return SoundOption(
      id: json['id'] as String,
      name: json['name'] as String,
      assetPath: json['assetPath'] as String?,
      filePath: json['filePath'] as String?,
      type: SoundType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SoundType.builtin,
      ),
      icon: json['icon'] as String? ?? '🔔',
    );
  }

  @override
  String toString() {
    return 'SoundOption(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Built-in sound options
  static List<SoundOption> get builtInSounds => [
        const SoundOption(
          id: 'bell',
          name: AppStrings.bellDefault,
          assetPath: AppAssets.bellSound,
          type: SoundType.builtin,
          icon: '🛕',
        ),
        const SoundOption(
          id: 'water_drop',
          name: AppStrings.waterDrop,
          assetPath: AppAssets.waterDropSound,
          type: SoundType.builtin,
          icon: '💧',
        ),
        const SoundOption(
          id: 'chime',
          name: AppStrings.gentleChime,
          assetPath: AppAssets.chimeSound,
          type: SoundType.builtin,
          icon: '🎵',
        ),
        const SoundOption(
          id: 'ocean',
          name: AppStrings.oceanWave,
          assetPath: AppAssets.oceanSound,
          type: SoundType.builtin,
          icon: '🌊',
        ),
        const SoundOption(
          id: 'ding',
          name: AppStrings.softDing,
          assetPath: AppAssets.dingSound,
          type: SoundType.builtin,
          icon: '🔔',
        ),
        const SoundOption(
          id: 'bubbles',
          name: AppStrings.bubbles,
          assetPath: AppAssets.bubblesSound,
          type: SoundType.builtin,
          icon: '🫧',
        ),
      ];

  /// Get a sound by ID
  static SoundOption? getById(String id) {
    try {
      return builtInSounds.firstWhere((sound) => sound.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get default sound
  static SoundOption get defaultSound => builtInSounds.first;

  /// Create a custom sound option
  static SoundOption createCustom({
    required String filePath,
    required String name,
  }) {
    return SoundOption(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      filePath: filePath,
      type: SoundType.custom,
      icon: '🎧',
    );
  }
}
