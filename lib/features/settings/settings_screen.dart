// Settings screen for the Forge application.
//
// The Settings tab: grouped glass sections for appearance (theme mode,
// accent, AMOLED and dynamic colors), training defaults, units, session
// behavior, haptics, reminders and data management. Every control persists
// through the [SettingsController]; data actions run through the
// [SettingsDataManager] wired to the export/import/backup engines.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dialogs/forge_dialogs.dart';
import '../../core/design/forge_design.dart';
import '../../core/overlays/forge_overlays.dart';
import '../../core/services/data_bundle.dart';
import '../../core/services/error_handling/forge_failures.dart';
import '../../models/settings_model.dart';
import '../../services/providers.dart';
import 'data/settings_controller.dart';
import 'data/settings_data_manager.dart';
import 'domain/settings_catalog.dart';
import 'providers/settings_providers.dart';
import 'widgets/accent_picker.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_segment_tile.dart';
import 'widgets/settings_slider_tile.dart';
import 'widgets/settings_switch_tile.dart';
import 'widgets/settings_value_tile.dart';

/// Settings tab — preferences for the whole app.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Duration _step = Duration(milliseconds: 40);

  SettingsController get _controller => ref.read(settingsControllerProvider);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.giant,
          ),
          children: [
            _animated(
              index: 0,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tune Forge to your training.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _animated(index: 1, child: _appearanceSection(settings)),
            _animated(index: 2, child: _trainingSection(settings)),
            _animated(index: 3, child: _unitsSection(settings)),
            _animated(index: 4, child: _sessionSection(settings)),
            _animated(index: 5, child: _remindersSection(settings)),
            _animated(index: 6, child: _dataSection()),
            _animated(
              index: 7,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Center(
                  child: Text(
                    'Forge v${ForgeAppInfo.version}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animated({required int index, required Widget child}) {
    return GlassAnimated(
      entrance: GlassEntrance.slide,
      delay: _step * index,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sections.
  // ---------------------------------------------------------------------

  Widget _appearanceSection(SettingsModel settings) {
    final themeMode = SettingsThemeMode.fromKey(settings.themeMode);
    return SettingsSection(
      icon: Icons.palette_rounded,
      title: 'Appearance',
      subtitle: 'Theme, accent and background',
      children: [
        SettingsSegmentTile(
          title: 'Theme',
          subtitle: 'Follow your device or pick a look',
          options: [for (final mode in SettingsThemeMode.values) mode.label],
          selectedIndex: themeMode.index,
          onChanged: (index) =>
              _controller.setThemeMode(SettingsThemeMode.values[index]),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Accent color',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).forgeColors.onSurfaceMuted,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        AccentPicker(
          selectedKey: settings.accentColor,
          onChanged: _controller.setAccent,
        ),
        SizedBox(height: AppSpacing.lg),
        SettingsSwitchTile(
          title: 'AMOLED dark',
          subtitle: 'True-black background in dark mode',
          value: settings.amoledMode,
          onChanged: _controller.setAmoled,
        ),
        SettingsSwitchTile(
          title: 'Dynamic colors',
          subtitle: 'Derive the palette from the accent seed',
          value: settings.dynamicColors,
          onChanged: _controller.setDynamicColors,
        ),
      ],
    );
  }

  Widget _trainingSection(SettingsModel settings) {
    final restTimer = SettingsRestTimerOption.nearest(settings.restTimer);
    return SettingsSection(
      icon: Icons.fitness_center_rounded,
      title: 'Training defaults',
      subtitle: 'Rest timer and warm-up presets',
      children: [
        SettingsSegmentTile(
          title: 'Rest timer',
          subtitle: 'Default time between sets',
          options: [
            for (final option in SettingsRestTimerOption.values) option.label,
          ],
          selectedIndex: restTimer.index,
          onChanged: (index) => _controller
              .setRestTimer(SettingsRestTimerOption.values[index].seconds),
        ),
        SettingsSegmentTile(
          title: 'Warm-up sets',
          subtitle: 'Suggested warm-up count per exercise',
          options: [
            for (final option in kSettingsWarmUpSetOptions) option.label,
          ],
          selectedIndex:
              _indexOf(kSettingsWarmUpSetOptions, settings.warmUpSets.toDouble()),
          onChanged: (index) => _controller
              .setWarmUpSets(kSettingsWarmUpSetOptions[index].value.toInt()),
        ),
        SettingsSliderTile(
          title: 'Warm-up weight',
          subtitle: 'Percentage of the working weight',
          valueLabel: '${settings.warmUpWeightPercent}%',
          value: settings.warmUpWeightPercent.toDouble(),
          min: 30,
          max: 70,
          divisions: 4,
          onChanged: (value) => _controller.setWarmUpWeightPercent(value.round()),
        ),
        SettingsValueTile<double>(
          title: 'Weight increment',
          subtitle: 'Default plate step',
          icon: Icons.add_rounded,
          value: settings.weightIncrement,
          valueLabel:
              '${formatSettingNumber(settings.weightIncrement)} ${settings.weightUnit}',
          options: _numericOptions(kSettingsWeightIncrementOptions),
          onChanged: _controller.setWeightIncrement,
        ),
        SettingsValueTile<double>(
          title: 'Plate weight',
          subtitle: 'Standard plate for the calculator',
          icon: Icons.circle_rounded,
          value: settings.plateWeight,
          valueLabel: '${formatSettingNumber(settings.plateWeight)} kg',
          options: _numericOptions(kSettingsPlateWeightOptions),
          onChanged: _controller.setPlateWeight,
        ),
        SettingsValueTile<double>(
          title: 'Barbell weight',
          subtitle: 'Standard bar for the calculator',
          icon: Icons.remove_rounded,
          value: settings.barWeight,
          valueLabel: '${formatSettingNumber(settings.barWeight)} kg',
          options: _numericOptions(kSettingsBarWeightOptions),
          onChanged: _controller.setBarWeight,
        ),
      ],
    );
  }

  Widget _unitsSection(SettingsModel settings) {
    final unitSystem = SettingsUnitSystem.fromKey(settings.unitSystem);
    return SettingsSection(
      icon: Icons.straighten_rounded,
      title: 'Units',
      subtitle: 'Measurements across the app',
      children: [
        SettingsSegmentTile(
          title: 'Unit system',
          subtitle: 'Metric or imperial',
          options: [for (final system in SettingsUnitSystem.values) system.label],
          selectedIndex: unitSystem.index,
          onChanged: (index) =>
              _controller.setUnitSystem(SettingsUnitSystem.values[index]),
        ),
        SettingsValueTile<String>(
          title: 'Water unit',
          subtitle: 'For hydration tracking',
          icon: Icons.water_drop_rounded,
          value: settings.waterUnit,
          valueLabel:
              settings.waterUnit == 'oz' ? 'Fluid ounces' : 'Liters',
          options: const [
            GlassDropdownOption<String>(
              label: 'Liters',
              value: 'l',
              icon: Icons.water_drop_outlined,
            ),
            GlassDropdownOption<String>(
              label: 'Fluid ounces',
              value: 'oz',
              icon: Icons.local_drink_outlined,
            ),
          ],
          onChanged: _controller.setWaterUnit,
        ),
      ],
    );
  }

  Widget _sessionSection(SettingsModel settings) {
    return SettingsSection(
      icon: Icons.timer_rounded,
      title: 'Workout session',
      subtitle: 'Rest timer and feedback',
      children: [
        SettingsSwitchTile(
          title: 'Auto-start rest timer',
          subtitle: 'Start the countdown after logging a set',
          value: settings.autoStartRestTimer,
          onChanged: _controller.setAutoStartRestTimer,
        ),
        SettingsSwitchTile(
          title: 'Countdown sound',
          subtitle: 'Play a beep when the rest timer ends',
          value: settings.countdownSound,
          onChanged: _controller.setCountdownSound,
        ),
        SettingsSwitchTile(
          title: 'Haptic feedback',
          subtitle: 'Subtle vibration on taps and completions',
          value: settings.hapticsEnabled,
          onChanged: _controller.setHaptics,
        ),
      ],
    );
  }

  Widget _remindersSection(SettingsModel settings) {
    return SettingsSection(
      icon: Icons.notifications_active_rounded,
      title: 'Reminders',
      subtitle: 'Scheduled locally on your device',
      children: [
        for (final reminder in kSettingsReminderTypes)
          SettingsSwitchTile(
            title: reminder.label,
            subtitle: reminder.subtitle,
            value: _reminderValue(settings, reminder.key),
            onChanged: (enabled) =>
                _controller.setReminderEnabled(reminder.key, enabled),
          ),
      ],
    );
  }

  Widget _dataSection() {
    final colors = Theme.of(context).forgeColors;
    return SettingsSection(
      icon: Icons.storage_rounded,
      title: 'Data',
      subtitle: 'Export, backup and import',
      children: [
        _dataTile(
          icon: Icons.file_upload_rounded,
          title: 'Export data',
          subtitle: 'Save everything to a JSON file',
          onTap: _exportData,
        ),
        _dataTile(
          icon: Icons.backup_rounded,
          title: 'Backup now',
          subtitle: 'Create a compressed backup',
          onTap: _createBackup,
        ),
        _dataTile(
          icon: Icons.settings_backup_restore_rounded,
          title: 'Restore backup',
          subtitle: 'Recover from a previous backup',
          onTap: _restoreBackup,
        ),
        _dataTile(
          icon: Icons.download_rounded,
          title: 'Import data',
          subtitle: 'Merge an export or backup file',
          onTap: _importData,
        ),
        GlassListTile(
          title: 'Reset settings',
          subtitle: 'Restore every preference to its default',
          leading: Icon(
            Icons.restart_alt_rounded,
            size: AppIconSize.small,
            color: colors.danger,
          ),
          onTap: _resetAll,
          semanticLabel: 'Reset settings',
        ),
      ],
    );
  }

  Widget _dataTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).forgeColors;
    return GlassListTile(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, size: AppIconSize.small, color: colors.primary),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------
  // Helpers.
  // ---------------------------------------------------------------------

  int _indexOf(List<SettingsNumericOption> options, double value) {
    final index = options.indexWhere((option) => option.value == value);
    return index < 0 ? 0 : index;
  }

  List<GlassDropdownOption<double>> _numericOptions(
    List<SettingsNumericOption> options,
  ) {
    return [
      for (final option in options)
        GlassDropdownOption<double>(
          label: option.label,
          value: option.value,
        ),
    ];
  }

  bool _reminderValue(SettingsModel settings, String key) {
    switch (key) {
      case 'workout':
        return settings.workoutRemindersEnabled;
      case 'rest':
        return settings.restRemindersEnabled;
      case 'daily':
        return settings.dailyReminderEnabled;
      case 'weekly':
        return settings.weeklySummaryEnabled;
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Data actions.
  // ---------------------------------------------------------------------

  SettingsDataManager get _dataManager =>
      ref.read(settingsDataManagerProvider);

  Future<void> _exportData() async {
    final result = await _dataManager.exportData();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    final summary = result.valueOrNull!;
    context.showSuccess(
      summary.copiedToClipboard
          ? 'Data exported and copied to clipboard.'
          : 'Data exported to ${summary.relativePath}.',
    );
  }

  Future<void> _createBackup() async {
    final result = await _dataManager.createBackup();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    context.showSuccess('Backup saved: ${_fileName(result.valueOrNull!.file)}.');
  }

  Future<void> _restoreBackup() async {
    final result = await _dataManager.listBackups();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    final candidates = result.valueOrNull ?? const <File>[];
    if (candidates.isEmpty) {
      _showForgeInfo('No backups yet', 'Create one under Data first.');
      return;
    }
    final selected = await _pickFile(
      title: 'Restore backup',
      icon: Icons.backup_rounded,
      files: candidates,
    );
    if (selected == null || !mounted) return;
    await _confirmAndRestore(selected);
  }

  Future<void> _importData() async {
    final result = await _dataManager.listImportCandidates();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    final candidates = result.valueOrNull ?? const <File>[];
    if (candidates.isEmpty) {
      _showForgeInfo(
        'No import files',
        'Export or back up from another device first, then place the '
        'file in the Forge documents folder.',
      );
      return;
    }
    final selected = await _pickFile(
      title: 'Import data',
      icon: Icons.download_rounded,
      files: candidates,
    );
    if (selected == null || !mounted) return;

    final validation = await _dataManager.validateFile(selected);
    if (!mounted) return;
    if (validation.isFailure) {
      context.showError(_failureMessage(validation.failureOrNull));
      return;
    }
    await _confirmAndImport(selected);
  }

  Future<File?> _pickFile({
    required String title,
    required IconData icon,
    required List<File> files,
  }) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    return GlassBottomSheet.show<File>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final file in files)
            GlassListTile(
              leading: Icon(
                icon,
                size: AppIconSize.small,
                color: colors.primary,
              ),
              title: _fileName(file),
              subtitle: _fileDate(file),
              onTap: () => Navigator.of(context).pop(file),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRestore(File file) async {
    final confirmed = await showForgeConfirmDialog(
      context,
      title: 'Restore backup?',
      message: 'This replaces the current data with the selected backup. '
          'Consider exporting first.',
      confirmLabel: 'Restore',
    );
    if (confirmed != true || !mounted) return;
    context.showLoading('Restoring…');
    final result = await _dataManager.restore(file);
    if (!mounted) return;
    context.dismissAllOverlays();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    _showForgeInfo(
      'Backup restored',
      'Forge data has been recovered. Your changes are live.',
    );
  }

  Future<void> _confirmAndImport(File file) async {
    final confirmed = await showForgeConfirmDialog(
      context,
      title: 'Import data?',
      message: 'The selected file will be merged into the current data. '
          'Conflicts are resolved by the newer file.',
      confirmLabel: 'Import',
    );
    if (confirmed != true || !mounted) return;
    context.showLoading('Importing…');
    final result = await _dataManager.importFile(file);
    if (!mounted) return;
    context.dismissAllOverlays();
    if (!mounted) return;
    if (result.isFailure) {
      context.showError(_failureMessage(result.failureOrNull));
      return;
    }
    _showForgeInfo(
      'Import complete',
      'Data from the file has been merged into Forge.',
    );
  }

  Future<void> _resetAll() async {
    final confirmed = await showForgeConfirmDialog(
      context,
      title: 'Reset settings?',
      message: 'Every preference returns to its default value. '
          'Training data is untouched.',
      confirmLabel: 'Reset',
    );
    if (confirmed != true || !mounted) return;
    await _controller.resetAll();
    if (!mounted) return;
    context.showSuccess('Settings reset to defaults.');
  }

  String _failureMessage(ForgeFailure? failure) =>
      failure?.message ?? 'Something went wrong.';

  String _fileName(File file) {
    final name = file.uri.pathSegments.isEmpty
        ? file.path
        : file.uri.pathSegments.last;
    return name;
  }

  String _fileDate(File file) {
    final modified = file.statSync().modified;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${modified.year}-${two(modified.month)}-${two(modified.day)} '
        '${two(modified.hour)}:${two(modified.minute)}';
  }

  void _showForgeInfo(String title, String message) {
    showForgeInfoDialog(context, title: title, message: message);
  }
}
