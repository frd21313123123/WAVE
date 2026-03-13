import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/wave_avatar.dart';
import 'app_settings.dart';
import 'avatar_upload.dart';
import 'settings_controller.dart';
import 'settings_scope.dart';
import 'widgets/settings_feedback_banner.dart';
import 'widgets/settings_section_card.dart';

typedef AvatarPickerCallback = Future<AvatarUploadData?> Function();
typedef SettingsActionCallback = Future<void> Function();

Future<T?> showWaveSettingsSheet<T>(
  BuildContext context, {
  required SettingsController controller,
  AvatarPickerCallback? onPickAvatar,
  SettingsActionCallback? onLogoutRequested,
  SettingsActionCallback? onRunMicrophoneTest,
  SettingsActionCallback? onPreviewCallTone,
  SettingsActionCallback? onCheckForUpdates,
  String? appVersionText,
  String? updateStatusText,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SettingsScope(
        controller: controller,
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: WaveSettingsSheet(
                controller: controller,
                onPickAvatar: onPickAvatar,
                onLogoutRequested: onLogoutRequested,
                onRunMicrophoneTest: onRunMicrophoneTest,
                onPreviewCallTone: onPreviewCallTone,
                onCheckForUpdates: onCheckForUpdates,
                appVersionText: appVersionText,
                updateStatusText: updateStatusText,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class WaveSettingsSheet extends StatefulWidget {
  const WaveSettingsSheet({
    super.key,
    required this.controller,
    this.onPickAvatar,
    this.onLogoutRequested,
    this.onRunMicrophoneTest,
    this.onPreviewCallTone,
    this.onCheckForUpdates,
    this.appVersionText,
    this.updateStatusText,
  });

  final SettingsController controller;
  final AvatarPickerCallback? onPickAvatar;
  final SettingsActionCallback? onLogoutRequested;
  final SettingsActionCallback? onRunMicrophoneTest;
  final SettingsActionCallback? onPreviewCallTone;
  final SettingsActionCallback? onCheckForUpdates;
  final String? appVersionText;
  final String? updateStatusText;

  @override
  State<WaveSettingsSheet> createState() => _WaveSettingsSheetState();
}

class _WaveSettingsSheetState extends State<WaveSettingsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _vigenereKeyController;
  late final TextEditingController _twoFactorEnableController;
  late final TextEditingController _twoFactorDisableController;
  late final FocusNode _displayNameFocusNode;
  late final FocusNode _vigenereKeyFocusNode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _settingsTabs.length, vsync: this);
    _displayNameController = TextEditingController();
    _vigenereKeyController = TextEditingController();
    _twoFactorEnableController = TextEditingController();
    _twoFactorDisableController = TextEditingController();
    _displayNameFocusNode = FocusNode();
    _vigenereKeyFocusNode = FocusNode();
    widget.controller.addListener(_handleControllerChanged);
    _syncTextFields(force: true);
    widget.controller.bootstrap();
  }

  @override
  void didUpdateWidget(covariant WaveSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _syncTextFields(force: true);
    widget.controller.bootstrap();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _tabController.dispose();
    _displayNameController.dispose();
    _vigenereKeyController.dispose();
    _twoFactorEnableController.dispose();
    _twoFactorDisableController.dispose();
    _displayNameFocusNode.dispose();
    _vigenereKeyFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncTextFields();
    setState(() {});
  }

  void _syncTextFields({bool force = false}) {
    final user = widget.controller.currentUser;
    final displayName = user?.displayName ?? '';
    final key = widget.controller.settings.vigenereKey;

    if (force ||
        (!_displayNameFocusNode.hasFocus &&
            _displayNameController.text != displayName)) {
      _displayNameController.value = TextEditingValue(
        text: displayName,
        selection: TextSelection.collapsed(offset: displayName.length),
      );
    }

    if (force ||
        (!_vigenereKeyFocusNode.hasFocus &&
            _vigenereKeyController.text != key)) {
      _vigenereKeyController.value = TextEditingValue(
        text: key,
        selection: TextSelection.collapsed(offset: key.length),
      );
    }
  }

  Future<void> _handleAvatarUpload() async {
    final picker = widget.onPickAvatar;
    if (picker == null) {
      return;
    }
    try {
      final result = await picker();
      if (result == null) {
        return;
      }
      await widget.controller.uploadAvatarBytes(
        result.bytes,
        mimeType: result.mimeType,
      );
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _handleLogout() async {
    final action = widget.onLogoutRequested;
    if (action == null) {
      return;
    }
    try {
      await action();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _handleMicrophoneTest() async {
    final action = widget.onRunMicrophoneTest;
    if (action == null) {
      return;
    }
    try {
      await action();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _handlePreviewCallTone() async {
    final action = widget.onPreviewCallTone;
    if (action == null) {
      return;
    }
    try {
      await action();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _handleCheckForUpdates() async {
    final action = widget.onCheckForUpdates;
    if (action == null) {
      return;
    }
    try {
      await action();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This removes the profile, conversations, and server-side account '
            'data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await widget.controller.deleteAccount();
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final user = controller.currentUser;
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height * 0.92;

        return SizedBox(
          height: math.max(540, resolvedHeight),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user == null
                                ? 'Reusable mobile settings controls.'
                                : 'Manage profile, theme, encryption, call '
                                    'preferences, 2FA, and account actions.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isBusy)
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (controller.isTaskActive(SettingsAsyncTask.bootstrap))
                const LinearProgressIndicator(minHeight: 2),
              Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tabAlignment: TabAlignment.start,
                  tabs: _settingsTabs
                      .map(
                        (tab) => Tab(
                          icon: Icon(tab.icon),
                          text: tab.label,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppearanceTab(context),
                    _buildThemeTab(context),
                    _buildEncryptionTab(context),
                    _buildSoundsTab(context),
                    _buildSecurityTab(context),
                    _buildAccountTab(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceTab(BuildContext context) {
    final controller = widget.controller;
    final user = controller.currentUser;
    final feedback = controller.feedbackFor(SettingsFeedbackArea.appearance);
    final isBusy = controller.isAreaBusy(SettingsFeedbackArea.appearance);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (feedback != null) ...[
          SettingsFeedbackBanner(
            message: feedback.message,
            isError: feedback.isError,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSectionCard(
          title: 'Profile identity',
          subtitle: 'Avatar and public name sync with the same account record '
              'used by the web client.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user == null)
                const _SignedOutHint(
                  message: 'Sign in to upload an avatar and change the '
                      'display name.',
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarPreview(user: user, radius: 34),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayNameOrUsername,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy || widget.onPickAvatar == null
                          ? null
                          : _handleAvatarUpload,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Upload avatar'),
                    ),
                    if (widget.onPickAvatar == null)
                      Text(
                        'Attach a picker callback to enable avatar uploads.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          title: 'Display name',
          subtitle: 'Uses PUT /api/auth/profile and updates the account seen '
              'in both mobile and web clients.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _displayNameController,
                focusNode: _displayNameFocusNode,
                enabled: user != null && !isBusy,
                maxLength: 32,
                onChanged: (_) =>
                    controller.clearFeedback(SettingsFeedbackArea.appearance),
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Enter a public profile name',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: user == null || isBusy
                      ? null
                      : () => controller.updateDisplayName(
                            _displayNameController.text,
                          ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save display name'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTab(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        SettingsSectionCard(
          title: 'Theme mode',
          subtitle: 'Matches the web client light and dark modes.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ChoiceChip(
                label: const Text('Light'),
                avatar: const Icon(Icons.light_mode_outlined, size: 18),
                selected: settings.themeMode == WaveThemeMode.light,
                onSelected: (_) => controller.setThemeMode(WaveThemeMode.light),
              ),
              ChoiceChip(
                label: const Text('Dark'),
                avatar: const Icon(Icons.dark_mode_outlined, size: 18),
                selected: settings.themeMode == WaveThemeMode.dark,
                onSelected: (_) => controller.setThemeMode(WaveThemeMode.dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          title: 'Fullscreen mode',
          subtitle:
              'Persists the preferred display mode for parent app wiring.',
          child: SwitchListTile.adaptive(
            value: settings.fullscreen,
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer fullscreen mode'),
            subtitle: const Text('Turn this off for a windowed presentation.'),
            onChanged: controller.setFullscreen,
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionTab(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;
    final feedback = controller.feedbackFor(SettingsFeedbackArea.encryption);
    final metrics = controller.encryptionMetrics;
    const previewSource = 'Hello, Wave / Привет, Wave';
    final previewCipher = controller.encryptMessage(previewSource);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (feedback != null) ...[
          SettingsFeedbackBanner(
            message: feedback.message,
            isError: feedback.isError,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSectionCard(
          title: 'Vigenere encryption',
          subtitle: 'Local outgoing text encryption compatible with the web '
              'client message format.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                value: settings.vigenereEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('Encrypt outgoing text messages'),
                subtitle: const Text(
                  'When enabled, outgoing text payloads include '
                  'encryption.type = "vigenere".',
                ),
                onChanged: controller.setVigenereEnabled,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _vigenereKeyController,
                focusNode: _vigenereKeyFocusNode,
                obscureText: !controller.encryptionKeyVisible,
                onChanged: controller.setVigenereKey,
                decoration: InputDecoration(
                  labelText: 'Encryption key',
                  helperText: 'Empty keys automatically fall back to WAVE.',
                  suffixIcon: IconButton(
                    onPressed: controller.toggleEncryptionKeyVisibility,
                    icon: Icon(
                      controller.encryptionKeyVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(label: 'Strength', value: metrics.label),
                  _MetricChip(
                    label: 'Entropy',
                    value: '${metrics.entropyBits} bits',
                  ),
                  _MetricChip(
                    label: 'Estimate',
                    value: metrics.estimatedCrackTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      previewSource,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      previewCipher,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.saveEncryptionPreferences,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Save encryption settings'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundsTab(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;
    final feedback = controller.feedbackFor(SettingsFeedbackArea.sounds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (feedback != null) ...[
          SettingsFeedbackBanner(
            message: feedback.message,
            isError: feedback.isError,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSectionCard(
          title: 'Call audio preferences',
          subtitle: 'Local sliders and toggles aligned with the web settings '
              'for microphone, speaker, and call feedback.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VolumeSliderRow(
                label: 'Microphone level',
                value: settings.microphoneVolume.toDouble(),
                icon: Icons.mic_none_outlined,
                onChanged: controller.setMicrophoneVolume,
              ),
              const SizedBox(height: 14),
              _VolumeSliderRow(
                label: 'Speaker level',
                value: settings.speakerVolume.toDouble(),
                icon: Icons.volume_up_outlined,
                onChanged: controller.setSpeakerVolume,
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: settings.callSoundsEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('Play call sounds'),
                subtitle: const Text(
                  'Covers incoming call, ended, and rejected call cues.',
                ),
                onChanged: controller.setCallSoundsEnabled,
              ),
              SwitchListTile.adaptive(
                value: settings.notificationsEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('System notifications'),
                subtitle: const Text(
                  'Local preference for push and foreground alerts.',
                ),
                onChanged: controller.setNotificationsEnabled,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onRunMicrophoneTest == null
                        ? null
                        : _handleMicrophoneTest,
                    icon: const Icon(Icons.graphic_eq_outlined),
                    label: const Text('Run mic test'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onPreviewCallTone == null
                        ? null
                        : _handlePreviewCallTone,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Preview call tone'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.saveSoundPreferences,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save sound settings'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTab(BuildContext context) {
    final controller = widget.controller;
    final user = controller.currentUser;
    final feedback = controller.feedbackFor(SettingsFeedbackArea.security);
    final isBusy = controller.isAreaBusy(SettingsFeedbackArea.security);
    final setup = controller.twoFactorSetup;
    final enabled = user?.twoFactorEnabled == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (feedback != null) ...[
          SettingsFeedbackBanner(
            message: feedback.message,
            isError: feedback.isError,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSectionCard(
          title: 'Two-factor authentication',
          subtitle: 'Uses the existing server endpoints for status, setup, '
              'enable, and disable flows.',
          trailing: _StatusBadge(
            label: enabled ? 'Enabled' : 'Disabled',
            color: enabled ? Colors.green : Colors.orange,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user == null)
                const _SignedOutHint(
                  message: 'Sign in to configure Google Authenticator based '
                      '2FA.',
                )
              else ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: isBusy ? null : controller.beginTwoFactorSetup,
                      icon: const Icon(Icons.qr_code_2_outlined),
                      label: Text(
                        enabled ? 'Rotate setup secret' : 'Begin 2FA setup',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => controller.refreshTwoFactorStatus(),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Refresh status'),
                    ),
                  ],
                ),
                if (setup?.isReady == true) ...[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wideLayout = constraints.maxWidth >= 560;
                      final preview = Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          setup!.qrImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(Icons.qr_code_2_outlined, size: 42),
                            );
                          },
                        ),
                      );
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authenticator secret',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            setup.secret,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _twoFactorEnableController,
                            enabled: !isBusy,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: '6-digit code',
                              hintText: 'Enter the current authenticator code',
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => controller.enableTwoFactor(
                                      _twoFactorEnableController.text,
                                    ),
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Enable 2FA'),
                          ),
                        ],
                      );
                      if (!wideLayout) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            preview,
                            const SizedBox(height: 16),
                            details,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          preview,
                          const SizedBox(width: 18),
                          Expanded(child: details),
                        ],
                      );
                    },
                  ),
                ],
                if (enabled) ...[
                  const SizedBox(height: 18),
                  TextField(
                    controller: _twoFactorDisableController,
                    enabled: !isBusy,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Disable code',
                      hintText: 'Enter your current 2FA code',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => controller.disableTwoFactor(
                              _twoFactorDisableController.text,
                            ),
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('Disable 2FA'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    final controller = widget.controller;
    final user = controller.currentUser;
    final feedback = controller.feedbackFor(SettingsFeedbackArea.account);
    final isBusy = controller.isAreaBusy(SettingsFeedbackArea.account);
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (feedback != null) ...[
          SettingsFeedbackBanner(
            message: feedback.message,
            isError: feedback.isError,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSectionCard(
          title: 'Обновления приложения',
          subtitle: 'Проверяет последний GitHub Release для этого устройства.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.appVersionText != null)
                Text(
                  'Установлена версия: ${widget.appVersionText}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (widget.updateStatusText != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.updateStatusText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: widget.onCheckForUpdates == null
                    ? null
                    : _handleCheckForUpdates,
                icon: const Icon(Icons.system_update_alt_rounded),
                label: const Text('Проверить наличие обновлений'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          title: 'Account controls',
          subtitle: 'Session exit and destructive account actions.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text(
                  user.displayNameOrUsername,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.email} · @${user.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
              ] else
                const _SignedOutHint(
                  message: 'Remote account actions become available after sign '
                      'in.',
                ),
              if (widget.onLogoutRequested != null)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : _handleLogout,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Log out'),
                ),
              if (widget.onLogoutRequested != null) const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: user == null || isBusy ? null : _handleDeleteAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _VolumeSliderRow extends StatelessWidget {
  const _VolumeSliderRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final double value;
  final IconData icon;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text('${value.round()}%'),
          ],
        ),
        Slider(
          value: value.clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '${value.round()}%',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SignedOutHint extends StatelessWidget {
  const _SignedOutHint({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.user,
    required this.radius,
  });

  final PublicUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return WaveAvatar(
      label: user.displayNameOrUsername,
      imageUrl: user.avatarUrl,
      radius: radius,
    );
  }
}

class _SettingsTabSpec {
  const _SettingsTabSpec({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

const List<_SettingsTabSpec> _settingsTabs = [
  _SettingsTabSpec(label: 'Appearance', icon: Icons.person_outline),
  _SettingsTabSpec(label: 'Display', icon: Icons.palette_outlined),
  _SettingsTabSpec(label: 'Encryption', icon: Icons.key_outlined),
  _SettingsTabSpec(label: 'Sounds', icon: Icons.graphic_eq_outlined),
  _SettingsTabSpec(label: 'Security', icon: Icons.shield_outlined),
  _SettingsTabSpec(label: 'Account', icon: Icons.manage_accounts_outlined),
];
