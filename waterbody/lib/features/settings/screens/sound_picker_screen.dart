import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/sound_option.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/permission_service.dart';
import '../widgets/sound_tile.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  late SoundOption _selectedSound;
  String? _playingSoundId;
  SoundOption? _customSound;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    _selectedSound = provider.selectedSound;
    _customSound = provider.customSound;
  }

  @override
  void dispose() {
    // Stop any playing sound
    context.read<SettingsProvider>().stopSoundPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(AppStrings.chooseSound),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Built-in sounds section
                Text(
                  AppStrings.builtInSounds,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...SoundOption.builtInSounds.map((sound) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SoundTile(
                        sound: sound,
                        isSelected: _selectedSound.id == sound.id,
                        isPlaying: _playingSoundId == sound.id,
                        onTap: () => _selectSound(sound),
                        onPlayPause: () => _togglePlay(sound),
                      ),
                    )),
                const SizedBox(height: 24),
                // Custom sound section
                Text(
                  AppStrings.customSound,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Show custom sound if exists
                if (_customSound != null) ...[
                  SoundTile(
                    sound: _customSound!,
                    isSelected: _selectedSound.id == _customSound!.id,
                    isPlaying: _playingSoundId == _customSound!.id,
                    onTap: () => _selectSound(_customSound!),
                    onPlayPause: () => _togglePlay(_customSound!),
                  ),
                  const SizedBox(height: 8),
                ],
                CustomSoundPickerTile(
                  onTap: _pickCustomSound,
                ),
                const SizedBox(height: 24),
                // Currently selected indicator
                _buildCurrentSelection(),
              ],
            ),
          ),
          // Save button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.waterLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            _selectedSound.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.currentlySelected,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _selectedSound.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSelection,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(AppStrings.save),
          ),
        ),
      ),
    );
  }

  void _selectSound(SoundOption sound) {
    setState(() {
      _selectedSound = sound;
    });
  }

  Future<void> _togglePlay(SoundOption sound) async {
    final provider = context.read<SettingsProvider>();

    if (_playingSoundId == sound.id) {
      // Stop playing
      await provider.stopSoundPreview();
      setState(() => _playingSoundId = null);
    } else {
      // Stop any currently playing sound
      await provider.stopSoundPreview();
      // Play new sound
      await provider.previewSound(sound);
      setState(() => _playingSoundId = sound.id);

      // Auto stop after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _playingSoundId == sound.id) {
          provider.stopSoundPreview();
          setState(() => _playingSoundId = null);
        }
      });
    }
  }

  Future<void> _pickCustomSound() async {
    // Check storage permission
    final permissionService = PermissionService();
    final hasPermission = await permissionService.hasStoragePermission();

    if (!hasPermission) {
      final granted = await permissionService.requestStoragePermission();
      if (!granted && mounted) {
        permissionService.showPermissionDeniedDialog(
          context,
          title: AppStrings.permissionRequired,
          message: AppStrings.storagePermission,
        );
        return;
      }
    }

    // Pick sound file
    final provider = context.read<SettingsProvider>();
    final sound = await provider.pickCustomSound();

    if (sound != null && mounted) {
      setState(() {
        _customSound = sound;
        _selectedSound = sound;
      });
    }
  }

  Future<void> _saveSelection() async {
    final provider = context.read<SettingsProvider>();
    await provider.stopSoundPreview();
    await provider.setSound(_selectedSound);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.soundChanged),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
